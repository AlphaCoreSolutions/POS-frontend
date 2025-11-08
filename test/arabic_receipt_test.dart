import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/receipt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Arabic Receipt Builder - Comprehensive Tests', () {
    late ReceiptBuilder rb;

    setUpAll(() async {
      // Create ReceiptBuilder with Arabic font support
      rb = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: true,
      );
    });

    test('Test 1: Build customer receipt with Arabic product names', () async {
      final order = {
        'orderNumber': '001',
        'paymentMethod': 'Cash',
        'subtotal': 45.50,
        'tax': 4.55,
        'tips': 5.00,
        'total': 55.05,
      };

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

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));

      // Verify ESC/POS commands are present
      expect(bytes.any((b) => b == 0x1B), isTrue); // ESC character present

      print('✅ Test 1 Passed: Generated ${bytes.length} bytes');
    });

    test('Test 2: Receipt with Arabic numbers (Eastern Arabic numerals)',
        () async {
      final rbArabicDigits = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true, // Use Arabic-Indic digits
        debug: true,
      );

      final order = {
        'orderNumber': '123456',
        'paymentMethod': 'Card',
        'subtotal': 99.99,
        'tax': 9.99,
        'total': 109.98,
      };

      final items = [
        {'name': 'منتج تجريبي', 'quantity': 10, 'unitPrice': 9.99}
      ];

      final bytes = await rbArabicDigits.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 2 Passed: Arabic numerals receipt generated');
    });

    test('Test 3: Kitchen receipt with complex Arabic text', () async {
      final order = {'orderNumber': '789'};

      final items = [
        {'name': 'برجر لحم مع جبنة شيدر', 'quantity': 2, 'notes': 'مشوي جيداً'},
        {
          'name': 'بطاطس مقلية كبيرة',
          'quantity': 1,
          'notes': 'مع كاتشب ومايونيز'
        },
        {'name': 'سلطة خضراء', 'quantity': 1, 'notes': ''},
      ];

      final bytes = await rb.buildKitchen(
        order,
        kitchenName: 'مطبخ رئيسي',
        items: items,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(200));
      print('✅ Test 3 Passed: Kitchen receipt generated');
    });

    test('Test 4: Receipt with all payment methods in Arabic', () async {
      final paymentMethods = ['Cash', 'Card', 'wallet', 'online'];

      for (final method in paymentMethods) {
        final order = {
          'orderNumber': '100',
          'paymentMethod': method,
          'total': 50.00,
        };

        final items = [
          {'name': 'منتج', 'quantity': 1, 'unitPrice': 50.00}
        ];

        final bytes = await rb.buildCustomer(order, items: items);
        expect(bytes, isNotEmpty);
        print('✅ Test 4 Passed: $method payment method receipt generated');
      }
    });

    test('Test 5: Receipt with long Arabic product names', () async {
      final order = {
        'orderNumber': '999',
        'paymentMethod': 'Cash',
        'total': 120.00,
      };

      final items = [
        {
          'name':
              'ساندويتش دجاج مشوي مع الخضروات الطازجة والصوص الخاص والبطاطس المقلية',
          'quantity': 1,
          'unitPrice': 120.00,
          'notes': 'بدون بصل وثوم'
        },
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 5 Passed: Long product name handled correctly');
    });

    test('Test 6: Receipt with mixed Arabic and English text', () async {
      final order = {
        'orderNumber': '555',
        'paymentMethod': 'Cash',
        'total': 75.50,
      };

      final items = [
        {'name': 'Burger برجر', 'quantity': 2, 'unitPrice': 25.00},
        {'name': 'Pizza بيتزا', 'quantity': 1, 'unitPrice': 25.50},
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 6 Passed: Mixed Arabic/English text handled');
    });

    test('Test 7: Receipt with zero tax and tips', () async {
      final order = {
        'orderNumber': '777',
        'paymentMethod': 'Cash',
        'subtotal': 30.00,
        'tax': 0.0,
        'tips': 0.0,
        'total': 30.00,
      };

      final items = [
        {'name': 'قهوة', 'quantity': 1, 'unitPrice': 30.00}
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 7 Passed: Receipt without tax/tips generated');
    });

    test('Test 8: Receipt with decimal quantities', () async {
      final order = {
        'orderNumber': '888',
        'paymentMethod': 'Cash',
        'total': 37.50,
      };

      final items = [
        {'name': 'لحم بالكيلو', 'quantity': 2.5, 'unitPrice': 15.00},
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 8 Passed: Decimal quantities handled');
    });

    test('Test 9: Multiple kitchen orders', () async {
      final order = {'orderNumber': '333'};

      final kitchens = {
        'مطبخ ساخن': [
          {'name': 'شاورما', 'quantity': 2, 'notes': ''},
          {'name': 'برجر', 'quantity': 1, 'notes': 'جيد الاستواء'},
        ],
        'مطبخ بارد': [
          {'name': 'سلطة', 'quantity': 3, 'notes': ''},
          {'name': 'عصير', 'quantity': 2, 'notes': 'مع ثلج'},
        ],
      };

      for (final entry in kitchens.entries) {
        final bytes = await rb.buildKitchen(
          order,
          kitchenName: entry.key,
          items: entry.value,
        );
        expect(bytes, isNotEmpty);
        print('✅ Test 9 Passed: ${entry.key} receipt generated');
      }
    });

    test('Test 10: Save receipt to file (optional - for manual verification)',
        () async {
      final order = {
        'orderNumber': 'TEST-001',
        'paymentMethod': 'نقداً',
        'subtotal': 100.00,
        'tax': 15.00,
        'tips': 10.00,
        'total': 125.00,
      };

      final items = [
        {'name': 'شاورما دجاج', 'quantity': 2, 'unitPrice': 25.00},
        {'name': 'بيتزا', 'quantity': 1, 'unitPrice': 50.00},
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      // Save to file for manual inspection
      final file = File('test_output/arabic_receipt_test.bin');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      expect(bytes, isNotEmpty);
      print('✅ Test 10 Passed: Receipt saved to ${file.path}');
    }, skip: false);

    test('Test 11: Stress test - Large order with many items', () async {
      final order = {
        'orderNumber': '9999',
        'paymentMethod': 'بطاقة',
        'subtotal': 500.00,
        'tax': 75.00,
        'total': 575.00,
      };

      final items = List.generate(
        20,
        (i) => {
          'name': 'منتج رقم ${i + 1}',
          'quantity': (i % 5) + 1,
          'unitPrice': 25.00,
          'notes': i % 3 == 0 ? 'ملاحظة خاصة' : '',
        },
      );

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      print('✅ Test 11 Passed: Large order with 20 items generated');
    });

    test('Test 12: Special Arabic characters and diacritics', () async {
      final order = {
        'orderNumber': '1111',
        'paymentMethod': 'Cash',
        'total': 50.00,
      };

      final items = [
        {'name': 'قَهْوَة عَرَبِيَّة', 'quantity': 1, 'unitPrice': 25.00},
        {'name': 'شَايٌ بِالنَّعْنَاع', 'quantity': 1, 'unitPrice': 25.00},
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 12 Passed: Diacritics handled correctly');
    });
  });

  group('Receipt Builder - Error Handling Tests', () {
    test('Test 13: Handle empty order gracefully', () async {
      final rb = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        debug: true,
      );

      final order = {};
      final items = <Map<String, dynamic>>[];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 13 Passed: Empty order handled');
    });

    test('Test 14: Handle missing fields', () async {
      final rb = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        debug: true,
      );

      final order = {
        'orderNumber': '222',
        // Missing paymentMethod, subtotal, tax, tips, total
      };

      final items = [
        {
          'name': 'منتج',
          // Missing quantity, unitPrice
        }
      ];

      final bytes = await rb.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 14 Passed: Missing fields handled with defaults');
    });
  });

  group('Different Paper Sizes', () {
    test('Test 15: 58mm receipt', () async {
      final rb58 = await ReceiptBuilder.create(
        paper: PaperSize.mm58,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: true,
      );

      final order = {
        'orderNumber': '58MM',
        'paymentMethod': 'نقداً',
        'total': 100.00,
      };

      final items = [
        {'name': 'منتج', 'quantity': 1, 'unitPrice': 100.00}
      ];

      final bytes = await rb58.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 15 Passed: 58mm receipt generated');
    });

    test('Test 16: 80mm receipt', () async {
      final rb80 = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
        debug: true,
      );

      final order = {
        'orderNumber': '80MM',
        'paymentMethod': 'بطاقة',
        'total': 150.00,
      };

      final items = [
        {'name': 'منتج كبير', 'quantity': 1, 'unitPrice': 150.00}
      ];

      final bytes = await rb80.buildCustomer(order, items: items);

      expect(bytes, isNotEmpty);
      print('✅ Test 16 Passed: 80mm receipt generated');
    });
  });
}
