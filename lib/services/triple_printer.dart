import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/receipt_builder.dart';

/// Roles are defined in bluetooth_printing_service.dart (reuse that enum)

/// NOTE:
/// - Accepts OrderDto OR Map<String, dynamic>
/// - productsById is optional; if provided, we internally route:
///     Falafel => categoryId == 7
///     Shawarma & Snacks => categoryId in {6, 8, 9}
/// - If productsById not provided, we try to call router.split(order)
///   (dynamic call to keep backward compatibility with your existing KitchenRouter).

class TriplePrinter {
  final BluetoothPrinterManager btManager;
  final dynamic
      router; // Keep dynamic to be compatible with your existing router
  final Map<int, dynamic>? productsById;
  final ProductResolver? resolve; // optional external resolver

  // Timing
  static const Duration _printerDelayShort = Duration(milliseconds: 500);
  static const Duration _printerDelayLong = Duration(milliseconds: 800);
  static const Duration _reconnectDelay = Duration(milliseconds: 1000);

  TriplePrinter({
    required this.btManager,
    required this.router,
    this.productsById,
    this.resolve,
  });

  Future<void> printAll(dynamic order, {String storeName = ''}) async {
    final printSessionId = DateTime.now().millisecondsSinceEpoch;
    developer.log(
      '🖨️ [PRINT-SESSION-$printSessionId] Starting print sequence',
      name: 'TriplePrinter',
    );

    try {
      // 1) Customer (80mm)
      final customerBuilder = await ReceiptBuilder.createCustomerBuilder(
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
      );

      final bytes = await customerBuilder.printCustomer(
        order,
        resolve: _buildResolver(),
        storeName: storeName,
      );

      final customerPrinted = await btManager.withPrinter(
        PrinterRole.customer,
        () async => btManager.writeBytes(Uint8List.fromList(bytes)),
      );

      if (!customerPrinted) {
        developer.log(
          '⚠️ [PRINT-SESSION-$printSessionId] Customer receipt FAILED',
          name: 'TriplePrinter',
          level: 900,
        );
      }
      await Future.delayed(_printerDelayShort);

      // 2) Kitchens (58mm)
      final buckets = _makeBuckets(order);
      await _printKitchenBucket(
        printSessionId,
        role: PrinterRole.falafel,
        kitchenName: 'مطبخ الفلافل',
        items: buckets['falafel'] ?? const [],
        order: order,
      );

      await Future.delayed(_printerDelayLong);

      await _printKitchenBucket(
        printSessionId,
        role: PrinterRole.shawarmaSnacks,
        kitchenName: 'مطبخ الشاورما والوجبات الخفيفة',
        items: buckets['shawarmaSnacks'] ?? const [],
        order: order,
      );

      // 3) Reconnect customer printer (ready for next order)
      final customerPrinter = btManager.getForRole(PrinterRole.customer);
      if (customerPrinter != null) {
        await Future.delayed(_reconnectDelay);
        await btManager.connect(customerPrinter.mac);
      }

      developer.log(
        '✅ [PRINT-SESSION-$printSessionId] Completed',
        name: 'TriplePrinter',
      );
    } catch (e, st) {
      developer.log(
        '❌ [PRINT-SESSION-$printSessionId] CRITICAL: $e',
        name: 'TriplePrinter',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      // best-effort: keep customer printer ready
      try {
        final customerPrinter = btManager.getForRole(PrinterRole.customer);
        if (customerPrinter != null) {
          await Future.delayed(_reconnectDelay);
          await btManager.connect(customerPrinter.mac);
        }
      } catch (_) {}
      rethrow;
    }
  }

  // ---------------- internal helpers ----------------

  Future<void> _printKitchenBucket(
    int sessionId, {
    required PrinterRole role,
    required String kitchenName,
    required List<dynamic> items,
    required dynamic order,
  }) async {
    if (items.isEmpty) {
      developer.log(
        '➖ [PRINT-SESSION-$sessionId] No items for $kitchenName',
        name: 'TriplePrinter',
      );
      return;
    }

    final builder = await ReceiptBuilder.createKitchenBuilder(
      arabicFontFamily: 'NotoNaskhArabic',
      arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
      useArabicIndicDigits: true,
    );

    final b = await builder.printKitchen(
      order,
      kitchenName: kitchenName,
      items: items,
      resolve: _buildResolver(),
    );

    final ok = await btManager.withPrinter(
      role,
      () async => btManager.writeBytes(Uint8List.fromList(b)),
    );

    if (!ok) {
      developer.log(
        '⚠️ [PRINT-SESSION-$sessionId] $kitchenName FAILED',
        name: 'TriplePrinter',
        level: 900,
      );
    } else {
      developer.log(
        '✅ [PRINT-SESSION-$sessionId] $kitchenName printed',
        name: 'TriplePrinter',
      );
    }
  }

  /// Build a resolver: prefer explicit resolve, then productsById, else null.
  ProductResolver? _buildResolver() {
    if (resolve != null) return resolve;
    if (productsById != null) {
      return (int id) => productsById![id];
    }
    return null;
  }

  /// Make kitchen buckets. If productsById is available, do it internally.
  /// Else, try to call router.split(order) dynamically.
  Map<String, List<dynamic>> _makeBuckets(dynamic order) {
    if (productsById != null) {
      // Internal split using category rules
      final items = _extractItems(order);
      final falafel = <dynamic>[];
      final shsn = <dynamic>[];
      for (final it in items) {
        final pid = _asInt(_pick(it, ['productId', 'ProductId']), 0);
        final p = productsById![pid];
        final catId = _categoryIdOf(p);
        if (catId == 7) {
          falafel.add(it);
        } else if (const {6, 8, 9}.contains(catId)) {
          shsn.add(it);
        }
      }
      return {'falafel': falafel, 'shawarmaSnacks': shsn};
    }

    // Try your existing KitchenRouter: split(order)
    try {
      final res = router.split(order);
      if (res is Map<String, List>) {
        // ensure correct shape
        return {
          'falafel': List<dynamic>.from(res['falafel'] ?? const []),
          'shawarmaSnacks':
              List<dynamic>.from(res['shawarmaSnacks'] ?? const []),
        };
      }
    } catch (_) {
      // ignore, fallback to no kitchen split
    }
    return {'falafel': const [], 'shawarmaSnacks': const []};
  }

  int _categoryIdOf(dynamic prod) {
    if (prod == null) return -1;
    try {
      final v = (prod as dynamic).categoryId;
      if (v is int) return v;
      if (v is num) return v.toInt();
    } catch (_) {}
    if (prod is Map) {
      final v = prod['categoryId'];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    try {
      final m = (prod as dynamic).toJson?.call();
      if (m is Map) {
        final v = m['categoryId'];
        if (v is int) return v;
        if (v is num) return v.toInt();
      }
    } catch (_) {}
    return -1;
  }

  // -------- minimal shared extractors (duplicated tiny bits) --------
  List<dynamic> _extractItems(dynamic order) {
    final l = (_pick(order, ['data.orderItems']) as List?) ??
        (_pick(order, ['orderItems']) as List?) ??
        (_pick(order, ['items']) as List?) ??
        <dynamic>[];
    return l;
  }

  dynamic _pick(dynamic obj, List<String> keys) {
    for (final k in keys) {
      final parts = k.split('.');
      dynamic cur = obj;
      bool ok = true;
      for (final p in parts) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          ok = false;
          break;
        }
      }
      if (ok) return cur;
    }
    return null;
  }

  int _asInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
  }
}
