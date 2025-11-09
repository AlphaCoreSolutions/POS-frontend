# Quick Start - Modern Receipt System

## 🚀 Quick Setup

### 1. Verify Configuration

Check `main_page.dart` line ~1375:

```dart
final storeName = 'مطعم فيجن'; // ← Change to your store name
```

Check kitchen routing line ~3005:

```dart
final router = KitchenRouter(
  falafelCategoryIds: {7},              // ← Your category IDs
  shawarmaSnacksCategoryIds: {6, 8, 9, 10}, // ← Your category IDs
);
```

### 2. Test Printing

1. Complete a test order in the POS
2. Click checkout
3. Verify receipts print:
   - Customer receipt (80mm)
   - Kitchen receipt(s) (58mm) - only if items present

### 3. Verify Output

**Customer Receipt Should Show:**
- ✅ Store name (centered)
- ✅ Order number (centered)
- ✅ Order date (centered)
- ✅ Items table (centered, 3 columns)
- ✅ Totals (right-aligned)
- ✅ Thank you (centered)
- ✅ Current date/time (centered)

**Kitchen Receipt Should Show:**
- ✅ Kitchen name (centered)
- ✅ Order number (centered)
- ✅ Order date (centered)
- ✅ Items table (centered, 2 columns)
- ✅ Current date/time (centered)

---

## 🔧 Common Adjustments

### Change Store Name

`main_page.dart` line ~1327:

```dart
final storeName = 'اسم مطعمك هنا'; // Your store name in Arabic
```

### Adjust Font Sizes

`receipt_builder.dart`:

- Line ~246: Store name font (default: 32)
- Line ~259: Order number font (default: 28)
- Line ~268: Order date font (default: 24)
- Line ~508: Table header font (default: 24)

### Adjust Column Widths

`receipt_builder.dart` line ~530 (Customer table):

```dart
final int rightColWidth = (usableWidth * 0.45).toInt();  // Item name
final int centerColWidth = (usableWidth * 0.20).toInt(); // Quantity
final int leftColWidth = (usableWidth * 0.35).toInt();   // Total
```

Line ~659 (Kitchen table):

```dart
final int rightColWidth = (usableWidth * 0.70).toInt();  // Item name
final int leftColWidth = (usableWidth * 0.30).toInt();   // Quantity
```

---

## 🐛 Troubleshooting

### Receipt Not Printing

1. Check printer connection in printer setup
2. Verify Bluetooth permissions
3. Check terminal output for error messages
4. Look for messages starting with `🖨️` in debug console

### Arabic Text Not Showing

1. Verify font file exists: `lib/assets/fonts/NotoNaskhArabic-Regular.ttf`
2. Check pubspec.yaml includes font
3. Restart app after adding font

### Wrong Items in Kitchen Receipt

1. Verify category IDs in `KitchenRouter` configuration
2. Check product category IDs in database
3. Add debug prints to see category routing

### Order Number Not Showing

1. Check API response includes `id`, `orderNumber`, or similar field
2. Verify `postOrderWithResponse()` is being used
3. Add debug print to see API response structure

---

## 📊 Debug Output

When printing, you'll see console output like:

```
🖨️ ============================================
🖨️ Starting Modern Print Function
🖨️ Order: 123 | Total: $28.75
🖨️ Store: مطعم فيجن
🖨️ ============================================
🖨️ Initializing Bluetooth printers...
🖨️ ✅ Bluetooth manager ready
🖨️ ✅ Kitchen router configured
🖨️ ✅ Triple printer initialized with modern design
🖨️ ============================================
🖨️ Starting print sequence...
🖨️ ============================================
🧾 Customer receipt: 4523 bytes in 145ms
🍳 Kitchen receipt: 2341 bytes in 87ms
🖨️ ============================================
🖨️ ✅ Print sequence completed successfully!
🖨️ ============================================
```

---

## 📞 Support

If you encounter issues:

1. Check `MODERN_RECEIPT_IMPLEMENTATION.md` for full documentation
2. Review error messages in debug console
3. Verify all configuration settings
4. Test with a simple order first

---

**Quick Tip**: Start with a single-item test order to verify basic functionality before testing complex orders.
