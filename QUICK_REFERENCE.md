# ⚡ Quick Reference: Arabic Receipt Printing

## 🚀 One-Command Print

```dart
// Copy-paste ready code!
final builder = await ReceiptBuilder.create(
  arabicFontFamily: 'NotoNaskhArabic',
  arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
  useArabicIndicDigits: true,
);

final bytes = await builder.buildCustomer({
  'orderNumber': '123',
  'paymentMethod': 'Cash',
  'total': 100.00,
}, items: [
  {'name': 'شاورما', 'quantity': 2, 'unitPrice': 25.00},
  {'name': 'عصير', 'quantity': 1, 'unitPrice': 50.00},
]);

await PrintBluetoothThermal.writeBytes(bytes);
```

## 📋 Order Structure

```dart
final order = {
  'orderNumber': '123',        // Required
  'paymentMethod': 'Cash',     // Auto-translates to Arabic
  'subtotal': 100.00,          // Optional (auto-calculated)
  'tax': 15.00,                // Optional
  'tips': 10.00,               // Optional
  'total': 125.00,             // Required
};
```

## 🛍️ Item Structure

```dart
final items = [
  {
    'name': 'شاورما دجاج',     // Product name (Arabic)
    'quantity': 2,              // Quantity (number or decimal)
    'unitPrice': 25.00,         // Price per unit
    'notes': 'بدون بصل',        // Optional notes
  },
];
```

## 💳 Payment Methods (Auto-Translated)

| English | Arabic |
|---------|--------|
| `Cash` | نقداً |
| `Card` | بطاقة |
| `wallet` | محفظة إلكترونية |
| `online` | دفع إلكتروني |

## 📏 Paper Sizes

```dart
// 58mm printer
PaperSize.mm58  // 384px width

// 80mm printer (default)
PaperSize.mm80  // 576px width
```

## 🔢 Number Formats

```dart
// Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
useArabicIndicDigits: true

// Western digits (0123456789)
useArabicIndicDigits: false
```

## 🍳 Kitchen Ticket

```dart
final bytes = await builder.buildKitchen(
  order,
  kitchenName: 'مطبخ رئيسي',
  items: kitchenItems,
);
```

## 🐛 Debug Mode

```dart
final builder = await ReceiptBuilder.create(
  // ... other params
  debug: true,  // Enable detailed logging
);
```

## ✅ Status Check

```dart
// Check printer connection
final connected = await PrintBluetoothThermal.connectionStatus;
if (connected != true) {
  print('Printer not connected');
}
```

## 🧪 Run Tests

```bash
flutter test test/arabic_receipt_test.dart
```

## 📚 Documentation Files

1. `ARABIC_PRINTING_SUMMARY.md` - Overview & quick start
2. `ARABIC_RECEIPT_GUIDE.md` - Complete guide
3. `VERIFICATION.md` - System verification
4. `lib/examples/arabic_receipt_example.dart` - Code examples

## 🔥 Most Common Use

```dart
// In your button onPressed or order completion:
try {
  final builder = await ReceiptBuilder.create(
    arabicFontFamily: 'NotoNaskhArabic',
    arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    useArabicIndicDigits: true,
  );
  
  final bytes = await builder.buildCustomer(orderData, items: itemsList);
  final ok = await PrintBluetoothThermal.writeBytes(bytes);
  
  if (ok) {
    showSnackBar('✅ تم طباعة الفاتورة');
  }
} catch (e) {
  showSnackBar('❌ فشل في الطباعة');
}
```

## 💡 Pro Tips

1. **Cache the builder**: Create once, reuse multiple times
2. **Enable debug**: Always use `debug: true` during development
3. **Check connection**: Verify printer status before printing
4. **Handle errors**: Wrap in try-catch for better UX
5. **Test thoroughly**: Run the test suite before deployment

## ⚠️ Common Mistakes

❌ **Don't do this:**
```dart
// Missing Arabic font configuration
final builder = await ReceiptBuilder.create();
```

✅ **Do this:**
```dart
// Always specify Arabic font
final builder = await ReceiptBuilder.create(
  arabicFontFamily: 'NotoNaskhArabic',
  arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
);
```

## 🎯 Result

```
         فاتورة
━━━━━━━━━━━━━━━━━━━━━━
رقم الطلب: ١٢٣
طريقة الدفع: نقداً
━━━━━━━━━━━━━━━━━━━━━━

٢ × شاورما .......... ٥٠.٠٠$
١ × عصير ............ ٥٠.٠٠$

━━━━━━━━━━━━━━━━━━━━━━
الإجمالي ........... ١٠٠.٠٠$
━━━━━━━━━━━━━━━━━━━━━━

      شكراً لكم
```

---

**Status: ✅ 100% Working**

Print away! 🖨️ طباعة سعيدة!
