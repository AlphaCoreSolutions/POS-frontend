import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/kitchen_router.dart';
import 'package:visionpos/services/receipt_builder.dart';

/// Unified printer for customer and kitchen receipts.
/// Uses the new simplified ReceiptBuilder API - no helpers needed!
///
/// Features:
/// - Automatic Arabic rendering (100% Android compatible)
/// - Per-printer ReceiptBuilder instances for reliability
/// - Auto-reconnect customer printer after kitchen printing
/// - Enhanced timing controls for multi-printer stability
/// - Comprehensive logging and error handling
///
/// Usage:
/// ```dart
/// final router = KitchenRouter(falafelCategoryIds: {1,2}, ...);
/// final printer = TriplePrinter(bt: btManager, router: router);
///
/// await printer.printAll(orderData);
/// ```
class TriplePrinter {
  final BluetoothPrinterManager bt;
  final KitchenRouter router;

  // Enhanced timing for multi-printer stability
  static const Duration _printerDelayShort = Duration(milliseconds: 500);
  static const Duration _printerDelayLong = Duration(milliseconds: 800);
  static const Duration _reconnectDelay = Duration(milliseconds: 1000);

  TriplePrinter({
    required this.bt,
    required this.router,
  });

  /// order must have:
  ///  - items: [{name, quantity, price, categoryId, notes?}, ...]
  ///  - subtotal, tax, tips, total, paymentMethod, orderNumber
  Future<void> printAll(Map<String, dynamic> order) async {
    final printSessionId = DateTime.now().millisecondsSinceEpoch;
    developer.log(
      '🖨️ [PRINT-SESSION-$printSessionId] Starting print sequence with per-printer builders',
      name: 'TriplePrinter',
    );

    try {
      // Validate order data
      _validateOrderData(order, printSessionId);

      // 1. Print Customer Receipt
      developer.log(
        '📄 [PRINT-SESSION-$printSessionId] Step 1: Building customer receipt',
        name: 'TriplePrinter',
      );

      // Create fresh builder for customer printer
      developer.log(
        '🏗️ [PRINT-SESSION-$printSessionId] Creating fresh ReceiptBuilder for customer printer',
        name: 'TriplePrinter',
      );
      final customerBuilder = await ReceiptBuilder.create(
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: false,
      );

      final Stopwatch customerBuildTimer = Stopwatch()..start();
      // Use new unified API - returns Android-compatible List<int>
      final customerBytes = await customerBuilder.printCustomer(order);
      customerBuildTimer.stop();

      developer.log(
        '📄 [PRINT-SESSION-$printSessionId] Customer receipt ready: ${customerBytes.length} bytes (Android-compatible) in ${customerBuildTimer.elapsedMilliseconds}ms',
        name: 'TriplePrinter',
      );

      final Stopwatch customerPrintTimer = Stopwatch()..start();
      final customerSuccess =
          await bt.withPrinter(PrinterRole.customer, () async {
        // Convert List<int> to Uint8List for writeBytes
        await bt.writeBytes(Uint8List.fromList(customerBytes));
      });
      customerPrintTimer.stop();

      if (!customerSuccess) {
        developer.log(
          '⚠️ [PRINT-SESSION-$printSessionId] Customer receipt FAILED to print',
          name: 'TriplePrinter',
          level: 900, // Warning level
        );
        debugPrint('⚠️ Customer receipt failed to print');
      } else {
        developer.log(
          '✅ [PRINT-SESSION-$printSessionId] Customer receipt printed successfully in ${customerPrintTimer.elapsedMilliseconds}ms',
          name: 'TriplePrinter',
        );
        debugPrint('✅ Customer receipt printed successfully');
      }
      await Future.delayed(_printerDelayShort);

      // 2. Print Kitchen Tickets
      developer.log(
        '🍴 [PRINT-SESSION-$printSessionId] Step 2: Processing kitchen tickets',
        name: 'TriplePrinter',
      );

      final buckets = router.split(order);
      developer.log(
        '🍴 [PRINT-SESSION-$printSessionId] Kitchen routing: Falafel=${buckets['falafel']!.length} items, Shawarma=${buckets['shawarmaSnacks']!.length} items',
        name: 'TriplePrinter',
      );

      // Falafel Kitchen
      final falafelItems = buckets['falafel']!;
      if (falafelItems.isNotEmpty) {
        developer.log(
          '🥙 [PRINT-SESSION-$printSessionId] Building Falafel kitchen ticket (${falafelItems.length} items)',
          name: 'TriplePrinter',
        );

        try {
          // Create fresh builder for Falafel printer
          developer.log(
            '🏗️ [PRINT-SESSION-$printSessionId] Creating fresh ReceiptBuilder for Falafel printer',
            name: 'TriplePrinter',
          );
          final falafelBuilder = await ReceiptBuilder.create(
            arabicFontFamily: 'NotoNaskhArabic',
            arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
            useArabicIndicDigits: true,
            debug: false,
          );

          final Stopwatch falafelBuildTimer = Stopwatch()..start();
          // Use new unified API - returns Android-compatible List<int>
          final bytes = await falafelBuilder.printKitchen(
            order,
            kitchenName: 'مطبخ الفلافل', // Arabic: Falafel Kitchen
            items: falafelItems,
          );
          falafelBuildTimer.stop();

          developer.log(
            '🥙 [PRINT-SESSION-$printSessionId] Falafel ticket ready: ${bytes.length} bytes (Android-compatible: List<int>) in ${falafelBuildTimer.elapsedMilliseconds}ms',
            name: 'TriplePrinter',
          );

          // Log Arabic content validation
          _logArabicContentValidation(
              'مطبخ الفلافل', falafelItems, printSessionId);

          final Stopwatch falafelPrintTimer = Stopwatch()..start();
          final success = await bt.withPrinter(PrinterRole.falafel, () async {
            // Convert List<int> to Uint8List for writeBytes
            await bt.writeBytes(Uint8List.fromList(bytes));
          });
          falafelPrintTimer.stop();

          if (!success) {
            developer.log(
              '⚠️ [PRINT-SESSION-$printSessionId] Falafel kitchen ticket FAILED to print',
              name: 'TriplePrinter',
              level: 900,
            );
            debugPrint('⚠️ Falafel kitchen ticket failed to print');
          } else {
            developer.log(
              '✅ [PRINT-SESSION-$printSessionId] Falafel ticket printed successfully in ${falafelPrintTimer.elapsedMilliseconds}ms',
              name: 'TriplePrinter',
            );
            debugPrint('✅ Falafel kitchen ticket printed');
          }
        } catch (e, stackTrace) {
          developer.log(
            '❌ [PRINT-SESSION-$printSessionId] ERROR building/printing Falafel ticket: $e',
            name: 'TriplePrinter',
            error: e,
            stackTrace: stackTrace,
            level: 1000, // Error level
          );
          debugPrint('❌ Falafel kitchen ticket error: $e');
          rethrow;
        }
        await Future.delayed(_printerDelayLong);
      } else {
        developer.log(
          '➖ [PRINT-SESSION-$printSessionId] No Falafel items, skipping',
          name: 'TriplePrinter',
        );
      }

      // Shawarma & Snacks Kitchen
      final shsnItems = buckets['shawarmaSnacks']!;
      if (shsnItems.isNotEmpty) {
        developer.log(
          '🌯 [PRINT-SESSION-$printSessionId] Building Shawarma kitchen ticket (${shsnItems.length} items)',
          name: 'TriplePrinter',
        );

        try {
          // Create fresh builder for Shawarma printer
          developer.log(
            '🏗️ [PRINT-SESSION-$printSessionId] Creating fresh ReceiptBuilder for Shawarma printer',
            name: 'TriplePrinter',
          );
          final shawarmaBuilder = await ReceiptBuilder.create(
            arabicFontFamily: 'NotoNaskhArabic',
            arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
            useArabicIndicDigits: true,
            debug: false,
          );

          final Stopwatch shawarmaBuildTimer = Stopwatch()..start();
          // Use new unified API - returns Android-compatible List<int>
          final bytes = await shawarmaBuilder.printKitchen(
            order,
            kitchenName:
                'مطبخ الشاورما والوجبات الخفيفة', // Arabic: Shawarma & Snacks Kitchen
            items: shsnItems,
          );
          shawarmaBuildTimer.stop();

          developer.log(
            '🌯 [PRINT-SESSION-$printSessionId] Shawarma ticket ready: ${bytes.length} bytes (Android-compatible: List<int>) in ${shawarmaBuildTimer.elapsedMilliseconds}ms',
            name: 'TriplePrinter',
          );

          // Log Arabic content validation
          _logArabicContentValidation(
              'مطبخ الشاورما والوجبات الخفيفة', shsnItems, printSessionId);

          final Stopwatch shawarmaPrintTimer = Stopwatch()..start();
          final success =
              await bt.withPrinter(PrinterRole.shawarmaSnacks, () async {
            // Convert List<int> to Uint8List for writeBytes
            await bt.writeBytes(Uint8List.fromList(bytes));
          });
          shawarmaPrintTimer.stop();

          if (!success) {
            developer.log(
              '⚠️ [PRINT-SESSION-$printSessionId] Shawarma kitchen ticket FAILED to print',
              name: 'TriplePrinter',
              level: 900,
            );
            debugPrint('⚠️ Shawarma kitchen ticket failed to print');
          } else {
            developer.log(
              '✅ [PRINT-SESSION-$printSessionId] Shawarma ticket printed successfully in ${shawarmaPrintTimer.elapsedMilliseconds}ms',
              name: 'TriplePrinter',
            );
            debugPrint('✅ Shawarma kitchen ticket printed');
          }
        } catch (e, stackTrace) {
          developer.log(
            '❌ [PRINT-SESSION-$printSessionId] ERROR building/printing Shawarma ticket: $e',
            name: 'TriplePrinter',
            error: e,
            stackTrace: stackTrace,
            level: 1000,
          );
          debugPrint('❌ Shawarma kitchen ticket error: $e');
          rethrow;
        }
        await Future.delayed(_printerDelayLong);
      } else {
        developer.log(
          '➖ [PRINT-SESSION-$printSessionId] No Shawarma items, skipping',
          name: 'TriplePrinter',
        );
      }

      // 3. Reconnect to Customer Printer (ready for next order)
      developer.log(
        '🔄 [PRINT-SESSION-$printSessionId] Step 3: Reconnecting customer printer',
        name: 'TriplePrinter',
      );

      final customerPrinter = bt.getForRole(PrinterRole.customer);
      if (customerPrinter != null) {
        await Future.delayed(
            _reconnectDelay); // Allow previous printer to fully disconnect

        final Stopwatch reconnectTimer = Stopwatch()..start();
        final reconnected = await bt.connect(customerPrinter.mac);
        reconnectTimer.stop();

        if (reconnected) {
          developer.log(
            '✅ [PRINT-SESSION-$printSessionId] Customer printer reconnected successfully in ${reconnectTimer.elapsedMilliseconds}ms (MAC: ${customerPrinter.mac})',
            name: 'TriplePrinter',
          );
          debugPrint('✅ Customer printer reconnected and ready');
        } else {
          developer.log(
            '⚠️ [PRINT-SESSION-$printSessionId] FAILED to reconnect customer printer (MAC: ${customerPrinter.mac})',
            name: 'TriplePrinter',
            level: 900,
          );
          debugPrint('⚠️ Failed to reconnect customer printer');
        }
      } else {
        developer.log(
          '⚠️ [PRINT-SESSION-$printSessionId] No customer printer assigned, cannot reconnect',
          name: 'TriplePrinter',
          level: 900,
        );
      }

      developer.log(
        '✅ [PRINT-SESSION-$printSessionId] Print sequence completed successfully',
        name: 'TriplePrinter',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ [PRINT-SESSION-$printSessionId] CRITICAL ERROR in printAll: $e',
        name: 'TriplePrinter',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      debugPrint('❌ Error in printAll: $e');
      debugPrint('Stack trace: $stackTrace');

      // Always try to reconnect customer printer even if there was an error
      try {
        final customerPrinter = bt.getForRole(PrinterRole.customer);
        if (customerPrinter != null) {
          developer.log(
            '🔄 [PRINT-SESSION-$printSessionId] Attempting emergency reconnection to customer printer',
            name: 'TriplePrinter',
          );
          await Future.delayed(_reconnectDelay);
          final reconnected = await bt.connect(customerPrinter.mac);
          if (reconnected) {
            developer.log(
              '✅ [PRINT-SESSION-$printSessionId] Emergency reconnection successful',
              name: 'TriplePrinter',
            );
          } else {
            developer.log(
              '⚠️ [PRINT-SESSION-$printSessionId] Emergency reconnection failed',
              name: 'TriplePrinter',
              level: 900,
            );
          }
        }
      } catch (reconnectError) {
        developer.log(
          '❌ [PRINT-SESSION-$printSessionId] Emergency reconnection threw error: $reconnectError',
          name: 'TriplePrinter',
          error: reconnectError,
          level: 1000,
        );
        debugPrint(
            '⚠️ Failed to reconnect customer printer after error: $reconnectError');
      }

      rethrow;
    }
  }

  /// Validate order data before printing
  void _validateOrderData(Map<String, dynamic> order, int sessionId) {
    developer.log(
      '🔍 [PRINT-SESSION-$sessionId] Validating order data',
      name: 'TriplePrinter',
    );

    final items = order['items'] as List?;
    if (items == null || items.isEmpty) {
      developer.log(
        '⚠️ [PRINT-SESSION-$sessionId] WARNING: Order has no items',
        name: 'TriplePrinter',
        level: 900,
      );
    } else {
      developer.log(
        '✓ [PRINT-SESSION-$sessionId] Order has ${items.length} items',
        name: 'TriplePrinter',
      );
    }

    final orderNumber = order['orderNumber'];
    if (orderNumber == null || orderNumber.toString().isEmpty) {
      developer.log(
        '⚠️ [PRINT-SESSION-$sessionId] WARNING: Order has no order number',
        name: 'TriplePrinter',
        level: 900,
      );
    } else {
      developer.log(
        '✓ [PRINT-SESSION-$sessionId] Order number: $orderNumber',
        name: 'TriplePrinter',
      );
    }
  }

  /// Log Arabic content validation for kitchen tickets
  void _logArabicContentValidation(
    String kitchenName,
    List<Map<String, dynamic>> items,
    int sessionId,
  ) {
    // Check if kitchen name contains Arabic
    final hasArabicName = _containsArabic(kitchenName);
    developer.log(
      '📝 [PRINT-SESSION-$sessionId] Kitchen name "$kitchenName" - Arabic: $hasArabicName',
      name: 'TriplePrinter.ArabicValidation',
    );

    // Check each item
    for (int i = 0; i < items.length; i++) {
      final itemName = items[i]['name']?.toString() ?? '';
      final hasArabic = _containsArabic(itemName);
      final notes = items[i]['notes']?.toString() ?? '';
      final hasArabicNotes = notes.isNotEmpty && _containsArabic(notes);

      developer.log(
        '📝 [PRINT-SESSION-$sessionId] Item ${i + 1}: "$itemName" - Arabic: $hasArabic, Notes: ${notes.isNotEmpty ? '"$notes"' : 'none'} - Arabic notes: $hasArabicNotes',
        name: 'TriplePrinter.ArabicValidation',
      );
    }
  }

  /// Check if text contains Arabic characters
  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
  }
}
