import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/receipt_builder.dart';

/// Example: How to print an Arabic receipt
/// This file demonstrates the complete workflow for printing Arabic receipts
/// with best practices for error handling, validation, and user feedback.
class ArabicReceiptExample {
  // Constants for configuration
  static const String _defaultFontFamily = 'NotoNaskhArabic';
  static const String _defaultFontPath =
      'lib/assets/fonts/NotoNaskhArabic-Regular.ttf';
  static const bool _defaultUseArabicDigits = true;
  static const bool _defaultDebugMode = false;

  // Singleton pattern for builder caching
  static ReceiptBuilder? _cachedBuilder;

  /// Get or create a receipt builder instance
  /// Caches the builder to avoid repeated initialization
  static Future<ReceiptBuilder> _getBuilder({
    PaperSize paper = PaperSize.mm80,
    bool useArabicIndicDigits = _defaultUseArabicDigits,
    bool debug = _defaultDebugMode,
  }) async {
    if (_cachedBuilder != null) {
      return _cachedBuilder!;
    }

    try {
      _cachedBuilder = await ReceiptBuilder.create(
        paper: paper,
        arabicFontFamily: _defaultFontFamily,
        arabicFontAssetPath: _defaultFontPath,
        useArabicIndicDigits: useArabicIndicDigits,
        debug: debug,
      );
      return _cachedBuilder!;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to create receipt builder',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );
      rethrow;
    }
  }

  /// Clear cached builder (useful when changing configuration)
  static void clearCache() {
    _cachedBuilder = null;
  }

  /// Validate order data before printing
  static bool _validateOrder(Map<String, dynamic> order) {
    if (order.isEmpty) {
      developer.log('Order is empty', name: 'ArabicReceiptExample');
      return false;
    }
    return true;
  }

  /// Validate items before printing
  static bool _validateItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      developer.log('Items list is empty', name: 'ArabicReceiptExample');
      return false;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (!item.containsKey('name') || item['name'].toString().isEmpty) {
        developer.log('Item at index $i has no name',
            name: 'ArabicReceiptExample');
        return false;
      }
    }
    return true;
  }

  /// Check printer connection status
  static Future<bool> _checkPrinterConnection() async {
    try {
      final bluetooth = BlueThermalPrinter.instance;
      final connected = await bluetooth.isConnected;
      return connected == true;
    } catch (e) {
      developer.log('Error checking printer connection',
          error: e, name: 'ArabicReceiptExample');
      return false;
    }
  }

  /// Print receipt with comprehensive error handling
  static Future<bool> _printWithErrorHandling(
    Uint8List bytes, {
    int retryCount = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    final bluetooth = BlueThermalPrinter.instance;

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        await bluetooth.writeBytes(bytes);
        developer.log('Receipt printed successfully on attempt ${attempt + 1}',
            name: 'ArabicReceiptExample');
        return true;
      } catch (e, stackTrace) {
        developer.log(
          'Print attempt ${attempt + 1} failed',
          error: e,
          stackTrace: stackTrace,
          name: 'ArabicReceiptExample',
        );

        if (attempt < retryCount) {
          developer.log('Print failed, retrying in ${retryDelay.inSeconds}s...',
              name: 'ArabicReceiptExample');
          await Future.delayed(retryDelay);
        }
      }
    }

    return false;
  }

  /// Show user feedback via SnackBar
  static void _showFeedback(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  /// Example 1: Print a customer receipt with best practices
  static Future<bool> printCustomerReceipt({
    BuildContext? context,
  }) async {
    try {
      developer.log('Starting customer receipt print',
          name: 'ArabicReceiptExample');

      // Validate connection
      if (!await _checkPrinterConnection()) {
        final message = 'الطابعة غير متصلة';
        developer.log(message, name: 'ArabicReceiptExample');
        if (context != null && context.mounted) {
          _showFeedback(context, message,
              backgroundColor: Colors.orange, icon: Icons.warning);
        }
        return false;
      }

      // Get builder
      final builder = await _getBuilder();

      // Prepare order data with validation
      final order = {
        'orderNumber': '001',
        'paymentMethod': 'Cash',
        'subtotal': 45.50,
        'tax': 4.55,
        'tips': 5.00,
        'total': 55.05,
      };

      if (!_validateOrder(order)) {
        return false;
      }

      // Prepare items with validation
      final items = [
        {
          'name': 'شاورما دجاج',
          'quantity': 2,
          'unitPrice': 15.00,
          'notes': 'بدون بصل'
        },
        {
          'name': 'بيتزا مارجريتا',
          'quantity': 1,
          'unitPrice': 25.00,
          'notes': 'صغيرة'
        },
        {'name': 'عصير برتقال', 'quantity': 3, 'unitPrice': 5.00, 'notes': ''},
      ];

      if (!_validateItems(items)) {
        return false;
      }

      // Generate receipt
      developer.log('Generating receipt bytes', name: 'ArabicReceiptExample');
      final bytes = await builder.buildCustomer(order, items: items);

      // Print with retry logic
      final success = await _printWithErrorHandling(bytes);

      // User feedback
      if (context != null && context.mounted) {
        if (success) {
          _showFeedback(
            context,
            '✅ تم إرسال الفاتورة للطابعة',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
            duration: const Duration(seconds: 2),
          );
        } else {
          _showFeedback(
            context,
            '❌ فشل في الطباعة',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
        }
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        'Error printing customer receipt',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );

      if (context != null && context.mounted) {
        _showFeedback(
          context,
          'خطأ في الطباعة: ${e.toString()}',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }

      return false;
    }
  }

  /// Example 2: Print a kitchen ticket with best practices
  static Future<bool> printKitchenTicket({
    BuildContext? context,
    required String kitchenName,
    List<Map<String, dynamic>>? customItems,
  }) async {
    try {
      developer.log('Starting kitchen ticket print',
          name: 'ArabicReceiptExample');

      // Validate connection
      if (!await _checkPrinterConnection()) {
        final message = 'الطابعة غير متصلة';
        if (context != null && context.mounted) {
          _showFeedback(context, message,
              backgroundColor: Colors.orange, icon: Icons.warning);
        }
        return false;
      }

      // Get builder
      final builder = await _getBuilder();

      // Order data
      final order = {
        'orderNumber': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Kitchen items with default or custom data
      final items = customItems ??
          [
            {'name': 'برجر لحم مع جبنة', 'quantity': 2, 'notes': 'مشوي جيداً'},
            {'name': 'بطاطس مقلية كبيرة', 'quantity': 1, 'notes': 'مع كاتشب'},
          ];

      if (!_validateItems(items)) {
        return false;
      }

      // Generate kitchen ticket
      developer.log('Generating kitchen ticket', name: 'ArabicReceiptExample');
      final bytes = await builder.buildKitchen(
        order,
        kitchenName: kitchenName,
        items: items,
      );

      // Print with retry
      final success = await _printWithErrorHandling(bytes);

      // User feedback
      if (context != null && context.mounted) {
        if (success) {
          _showFeedback(
            context,
            '✅ تم إرسال طلب المطبخ',
            backgroundColor: Colors.green,
            icon: Icons.restaurant,
            duration: const Duration(seconds: 2),
          );
        } else {
          _showFeedback(
            context,
            '❌ فشل في إرسال طلب المطبخ',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
        }
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        'Error printing kitchen ticket',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );

      if (context != null && context.mounted) {
        _showFeedback(
          context,
          'خطأ في الطباعة: ${e.toString()}',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }

      return false;
    }
  }

  /// Example 3: Print receipt with Western numerals
  static Future<bool> printWithWesternNumerals({
    BuildContext? context,
  }) async {
    try {
      // Clear cache to force new builder with different settings
      clearCache();

      final builder = await _getBuilder(
        useArabicIndicDigits: false, // Use Western numerals
        debug: true,
      );

      final order = {
        'orderNumber': '999',
        'paymentMethod': 'Card',
        'total': 100.00,
      };

      final items = [
        {'name': 'قهوة عربية', 'quantity': 2, 'unitPrice': 50.00}
      ];

      if (!_validateOrder(order) || !_validateItems(items)) {
        return false;
      }

      final bytes = await builder.buildCustomer(order, items: items);
      final success = await _printWithErrorHandling(bytes);

      if (context != null && context.mounted) {
        _showFeedback(
          context,
          success ? '✅ تمت الطباعة' : '❌ فشلت الطباعة',
          backgroundColor: success ? Colors.green : Colors.red,
        );
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        'Error in printWithWesternNumerals',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );
      return false;
    }
  }

  /// Example 4: Print on 58mm paper with validation
  static Future<bool> printOn58mmPaper({
    BuildContext? context,
  }) async {
    try {
      clearCache(); // Clear cache for different paper size

      final builder = await _getBuilder(
        paper: PaperSize.mm58,
        debug: true,
      );

      final order = {
        'orderNumber': DateTime.now().millisecondsSinceEpoch.toString(),
        'paymentMethod': 'Cash',
        'total': 25.00,
      };

      final items = [
        {'name': 'شاي', 'quantity': 1, 'unitPrice': 25.00}
      ];

      if (!_validateOrder(order) || !_validateItems(items)) {
        return false;
      }

      final bytes = await builder.buildCustomer(order, items: items);
      final success = await _printWithErrorHandling(bytes);

      if (context != null && context.mounted) {
        _showFeedback(
          context,
          success ? '✅ تمت الطباعة (58mm)' : '❌ فشلت الطباعة',
          backgroundColor: success ? Colors.green : Colors.red,
        );
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        'Error in printOn58mmPaper',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );
      return false;
    }
  }

  /// Example 5: Production-ready receipt printing with comprehensive error handling
  static Future<bool> printReceiptProductionReady({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> items,
    PaperSize paperSize = PaperSize.mm80,
    bool useArabicDigits = true,
    bool showLoadingIndicator = true,
  }) async {
    try {
      // Validate inputs
      if (!_validateOrder(order)) {
        _showFeedback(
          context,
          'بيانات الطلب غير صالحة',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
        );
        return false;
      }

      if (!_validateItems(items)) {
        _showFeedback(
          context,
          'قائمة المنتجات غير صالحة',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
        );
        return false;
      }

      // Check connection
      if (!await _checkPrinterConnection()) {
        _showFeedback(
          context,
          'الطابعة غير متصلة، الرجاء الاتصال أولاً',
          backgroundColor: Colors.orange,
          icon: Icons.bluetooth_disabled,
        );
        return false;
      }

      // Show loading
      if (showLoadingIndicator && context.mounted) {
        _showFeedback(
          context,
          'جاري طباعة الفاتورة...',
          duration: const Duration(milliseconds: 800),
          icon: Icons.print,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Get or create builder
      clearCache(); // Ensure fresh builder with current settings
      final builder = await _getBuilder(
        paper: paperSize,
        useArabicIndicDigits: useArabicDigits,
        debug: true,
      );

      // Generate receipt with timing
      final stopwatch = Stopwatch()..start();
      developer.log('Generating receipt', name: 'ArabicReceiptExample');

      final bytes = await builder.buildCustomer(order, items: items);

      stopwatch.stop();
      developer.log(
        'Receipt generated in ${stopwatch.elapsedMilliseconds}ms (${bytes.length} bytes)',
        name: 'ArabicReceiptExample',
      );

      // Print with retry
      final success = await _printWithErrorHandling(
        bytes,
        retryCount: 2,
        retryDelay: const Duration(seconds: 1),
      );

      // Show result with appropriate feedback
      if (context.mounted) {
        if (success) {
          _showFeedback(
            context,
            '✅ تم إرسال الفاتورة للطابعة بنجاح',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
            duration: const Duration(seconds: 2),
          );
        } else {
          _showFeedback(
            context,
            '❌ فشل في الطباعة بعد عدة محاولات',
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
            duration: const Duration(seconds: 4),
          );
        }
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        'Critical error in printReceiptProductionReady',
        error: e,
        stackTrace: stackTrace,
        name: 'ArabicReceiptExample',
      );

      if (context.mounted) {
        _showFeedback(
          context,
          'خطأ حرج في الطباعة: ${e.toString()}',
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 5),
        );
      }

      return false;
    }
  }

  /// Example 6: Test all payment methods with proper delay
  static Future<void> testAllPaymentMethods({
    BuildContext? context,
    Duration delayBetweenPrints = const Duration(seconds: 3),
  }) async {
    final paymentMethods = {
      'Cash': 'نقداً',
      'Card': 'بطاقة',
      'wallet': 'محفظة إلكترونية',
      'online': 'دفع إلكتروني',
    };

    int successCount = 0;
    int failCount = 0;

    for (final entry in paymentMethods.entries) {
      developer.log(
        'Testing payment method: ${entry.key} (${entry.value})',
        name: 'ArabicReceiptExample',
      );

      try {
        final builder = await _getBuilder();

        final order = {
          'orderNumber': DateTime.now().millisecondsSinceEpoch.toString(),
          'paymentMethod': entry.key,
          'total': 50.00,
        };

        final items = [
          {'name': 'منتج تجريبي', 'quantity': 1, 'unitPrice': 50.00}
        ];

        final bytes = await builder.buildCustomer(order, items: items);
        final success = await _printWithErrorHandling(bytes, retryCount: 1);

        if (success) {
          successCount++;
          developer.log(
            '✅ Success with ${entry.key}',
            name: 'ArabicReceiptExample',
          );
        } else {
          failCount++;
          developer.log(
            '❌ Failed with ${entry.key}',
            name: 'ArabicReceiptExample',
          );
        }

        // Wait between prints to avoid printer buffer overflow
        if (paymentMethods.entries.last != entry) {
          await Future.delayed(delayBetweenPrints);
        }
      } catch (e) {
        failCount++;
        developer.log(
          'Error testing ${entry.key}: $e',
          name: 'ArabicReceiptExample',
        );
      }
    }

    // Summary
    final summary = 'نجح: $successCount، فشل: $failCount';
    developer.log(summary, name: 'ArabicReceiptExample');

    if (context != null && context.mounted) {
      _showFeedback(
        context,
        'اكتمل الاختبار: $summary',
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        icon: failCount == 0 ? Icons.check_circle : Icons.warning,
      );
    }
  }

  /// Utility: Get printer information for debugging
  static Future<Map<String, dynamic>> getPrinterInfo() async {
    try {
      final bluetooth = BlueThermalPrinter.instance;
      final connected = await bluetooth.isConnected;
      // Add more printer info methods as available from the plugin
      return {
        'connected': connected,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('Error getting printer info',
          error: e, name: 'ArabicReceiptExample');
      return {'error': e.toString()};
    }
  }
}

/// ===========================================================================
/// USAGE EXAMPLES
/// ===========================================================================
///
/// Example 1: Simple receipt printing with context
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     await ArabicReceiptExample.printCustomerReceipt(context: context);
///   },
///   child: const Text('طباعة فاتورة'),
/// )
/// ```
///
/// Example 2: Kitchen ticket with custom data
/// ```dart
/// await ArabicReceiptExample.printKitchenTicket(
///   context: context,
///   kitchenName: 'مطبخ ساخن',
///   customItems: [
///     {'name': 'برجر', 'quantity': 2, 'notes': 'جيد الاستواء'},
///   ],
/// );
/// ```
///
/// Example 3: Production-ready printing (recommended)
/// ```dart
/// final order = {
///   'orderNumber': orderNumber,
///   'paymentMethod': paymentMethod,
///   'subtotal': subtotal,
///   'tax': tax,
///   'total': total,
/// };
///
/// final items = selectedItems.map((item) => {
///   'name': item.name,
///   'quantity': item.quantity,
///   'unitPrice': item.price,
///   'notes': item.notes ?? '',
/// }).toList();
///
/// final success = await ArabicReceiptExample.printReceiptProductionReady(
///   context: context,
///   order: order,
///   items: items,
///   paperSize: PaperSize.mm80,
///   useArabicDigits: true,
/// );
///
/// if (success) {
///   // Handle success (e.g., clear cart, save order)
/// }
/// ```
///
/// Example 4: Check printer status before printing
/// ```dart
/// final printerInfo = await ArabicReceiptExample.getPrinterInfo();
/// if (printerInfo['connected'] == true) {
///   // Proceed with printing
/// } else {
///   // Show connection dialog
/// }
/// ```
///
/// Example 5: Clear cache when changing settings
/// ```dart
/// // When user changes paper size or digit format
/// ArabicReceiptExample.clearCache();
/// ```
