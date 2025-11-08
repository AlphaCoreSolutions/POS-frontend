import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/receipt_builder.dart';

/// Example: How to print an Arabic receipt
/// This file demonstrates the complete workflow for printing Arabic receipts
class ArabicReceiptExample {
  /// Example 1: Print a customer receipt with Arabic text
  static Future<void> printCustomerReceipt() async {
    try {
      // Step 1: Create the ReceiptBuilder with Arabic font support
      final builder = await ReceiptBuilder.create(
        paper: PaperSize.mm80, // or PaperSize.mm58
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true, // Use Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩)
        debug: true, // Enable debug logging
      );

      // Step 2: Prepare order data
      final order = {
        'orderNumber': '001',
        'paymentMethod': 'Cash', // Will be translated to 'نقداً'
        'subtotal': 45.50,
        'tax': 4.55,
        'tips': 5.00,
        'total': 55.05,
      };

      // Step 3: Prepare items with Arabic names
      final items = [
        {
          'name': 'شاورما دجاج', // Chicken shawarma
          'quantity': 2,
          'unitPrice': 15.00,
          'notes': 'بدون بصل' // Without onions
        },
        {
          'name': 'بيتزا مارجريتا', // Margherita pizza
          'quantity': 1,
          'unitPrice': 25.00,
          'notes': 'صغيرة' // Small
        },
        {
          'name': 'عصير برتقال', // Orange juice
          'quantity': 3,
          'unitPrice': 5.00,
          'notes': ''
        },
      ];

      // Step 4: Generate receipt bytes
      final bytes = await builder.buildCustomer(order, items: items);

      // Step 5: Send to printer
      final ok = await PrintBluetoothThermal.writeBytes(bytes);

      if (ok == true) {
        print('✅ Receipt printed successfully');
        print('✅ تم طباعة الفاتورة بنجاح');
      } else {
        print('❌ Failed to print receipt');
        print('❌ فشل في طباعة الفاتورة');
      }
    } catch (e) {
      print('Error printing receipt: $e');
    }
  }

  /// Example 2: Print a kitchen ticket
  static Future<void> printKitchenTicket() async {
    try {
      // Create builder
      final builder = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: true,
      );

      // Order data
      final order = {'orderNumber': '123'};

      // Kitchen items
      final items = [
        {
          'name': 'برجر لحم مع جبنة', // Beef burger with cheese
          'quantity': 2,
          'notes': 'مشوي جيداً' // Well done
        },
        {
          'name': 'بطاطس مقلية كبيرة', // Large fries
          'quantity': 1,
          'notes': 'مع كاتشب' // With ketchup
        },
      ];

      // Generate kitchen ticket
      final bytes = await builder.buildKitchen(
        order,
        kitchenName: 'مطبخ رئيسي', // Main kitchen
        items: items,
      );

      // Send to kitchen printer
      final ok = await PrintBluetoothThermal.writeBytes(bytes);

      if (ok == true) {
        print('✅ Kitchen ticket printed');
      } else {
        print('❌ Failed to print kitchen ticket');
      }
    } catch (e) {
      print('Error printing kitchen ticket: $e');
    }
  }

  /// Example 3: Print receipt with Western numerals (not Arabic-Indic)
  static Future<void> printWithWesternNumerals() async {
    final builder = await ReceiptBuilder.create(
      paper: PaperSize.mm80,
      arabicFontFamily: 'NotoNaskhArabic',
      arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
      useArabicIndicDigits: false, // Use Western numerals (0123456789)
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

    final bytes = await builder.buildCustomer(order, items: items);
    await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Example 4: Print on 58mm paper
  static Future<void> printOn58mmPaper() async {
    final builder = await ReceiptBuilder.create(
      paper: PaperSize.mm58, // 58mm paper
      arabicFontFamily: 'NotoNaskhArabic',
      arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
      useArabicIndicDigits: true,
      debug: true,
    );

    final order = {
      'orderNumber': '58',
      'paymentMethod': 'Cash',
      'total': 25.00,
    };

    final items = [
      {'name': 'شاي', 'quantity': 1, 'unitPrice': 25.00}
    ];

    final bytes = await builder.buildCustomer(order, items: items);
    await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Example 5: Complete workflow with error handling
  static Future<void> printReceiptWithErrorHandling(
    BuildContext context,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      // Check Bluetooth connection
      final connected = await PrintBluetoothThermal.connectionStatus;
      if (connected != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الطابعة غير متصلة، الرجاء الاتصال أولاً'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري طباعة الفاتورة...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create builder
      final builder = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: true,
      );

      // Generate receipt
      final bytes = await builder.buildCustomer(order, items: items);

      // Print
      final ok = await PrintBluetoothThermal.writeBytes(bytes);

      // Show result
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الفاتورة للطابعة'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل في الطباعة'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Print error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Example 6: Print with all payment methods
  static Future<void> demonstratePaymentMethods() async {
    final builder = await ReceiptBuilder.create(
      paper: PaperSize.mm80,
      arabicFontFamily: 'NotoNaskhArabic',
      arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
      useArabicIndicDigits: true,
      debug: true,
    );

    final paymentMethods = {
      'Cash': 'نقداً',
      'Card': 'بطاقة',
      'wallet': 'محفظة إلكترونية',
      'online': 'دفع إلكتروني',
    };

    for (final entry in paymentMethods.entries) {
      print(
          'Printing receipt with payment method: ${entry.key} (${entry.value})');

      final order = {
        'orderNumber': '100',
        'paymentMethod': entry.key,
        'total': 50.00,
      };

      final items = [
        {'name': 'منتج تجريبي', 'quantity': 1, 'unitPrice': 50.00}
      ];

      final bytes = await builder.buildCustomer(order, items: items);
      await PrintBluetoothThermal.writeBytes(bytes);

      // Wait between prints
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

/// Usage in your Flutter app:
///
/// ```dart
/// // In a button onPressed:
/// ElevatedButton(
///   onPressed: () async {
///     await ArabicReceiptExample.printCustomerReceipt();
///   },
///   child: Text('طباعة فاتورة'),
/// ),
/// ```
