# Kitchen Arabic Printing - Logging & Debugging Guide

## Overview
This guide explains the comprehensive logging system implemented for kitchen ticket printing in Arabic. The logging helps identify issues at every step of the printing process.

## How to View Logs

### 1. Flutter DevTools Console
Run your app with:
```bash
flutter run
```
Then open DevTools and view the logs in real-time.

### 2. Android Logcat (for Android devices)
```bash
flutter logs
```
Or:
```bash
adb logcat | grep "TriplePrinter\|ReceiptBuilder"
```

### 3. VS Code Debug Console
When running in debug mode, logs will appear in the Debug Console.

## Log Levels

The system uses different log levels to categorize messages:

- **🔍 INFO (default)**: Normal operation messages
- **⚠️ WARNING (900)**: Potential issues that don't stop execution
- **❌ ERROR (1000)**: Critical errors that stop execution

## Print Session Tracking

Each print job gets a unique session ID based on timestamp. All logs for that session are tagged with:
```
[PRINT-SESSION-1234567890]
```

This makes it easy to track a single order through the entire printing process.

## Log Output Examples

### ✅ Successful Print Session

```
🖨️ [PRINT-SESSION-1704812345000] Starting print sequence
🔍 [PRINT-SESSION-1704812345000] Validating order data
✓ [PRINT-SESSION-1704812345000] Order has 5 items
✓ [PRINT-SESSION-1704812345000] Order number: 0001

📄 [PRINT-SESSION-1704812345000] Step 1: Building customer receipt
📄 [PRINT-SESSION-1704812345000] Customer receipt built: 2456 bytes in 145ms
✅ [PRINT-SESSION-1704812345000] Customer receipt printed successfully in 890ms

🍴 [PRINT-SESSION-1704812345000] Step 2: Processing kitchen tickets
🍴 [PRINT-SESSION-1704812345000] Kitchen routing: Falafel=2 items, Shawarma=3 items

🥙 [PRINT-SESSION-1704812345000] Building Falafel kitchen ticket (2 items)
📝 [PRINT-SESSION-1704812345000] Kitchen name "مطبخ الفلافل" - Arabic: true
📝 [PRINT-SESSION-1704812345000] Item 1: "فلافل" - Arabic: true, Notes: none - Arabic notes: false
📝 [PRINT-SESSION-1704812345000] Item 2: "حمص" - Arabic: true, Notes: "بدون طحينة" - Arabic notes: true
🥙 [PRINT-SESSION-1704812345000] Falafel ticket built: 1234 bytes in 98ms
✅ [PRINT-SESSION-1704812345000] Falafel ticket printed successfully in 720ms

🌯 [PRINT-SESSION-1704812345000] Building Shawarma kitchen ticket (3 items)
📝 [PRINT-SESSION-1704812345000] Kitchen name "مطبخ الشاورما والوجبات الخفيفة" - Arabic: true
📝 [PRINT-SESSION-1704812345000] Item 1: "شاورما دجاج" - Arabic: true, Notes: none - Arabic notes: false
🌯 [PRINT-SESSION-1704812345000] Shawarma ticket built: 1567 bytes in 112ms
✅ [PRINT-SESSION-1704812345000] Shawarma ticket printed successfully in 780ms

🔄 [PRINT-SESSION-1704812345000] Step 3: Reconnecting customer printer
✅ [PRINT-SESSION-1704812345000] Customer printer reconnected successfully in 234ms (MAC: 00:11:22:33:44:55)
✅ [PRINT-SESSION-1704812345000] Print sequence completed successfully
```

### ⚠️ Warning Example (No Kitchen Items)

```
🖨️ [PRINT-SESSION-1704812456000] Starting print sequence
🔍 [PRINT-SESSION-1704812456000] Validating order data
✓ [PRINT-SESSION-1704812456000] Order has 3 items
✓ [PRINT-SESSION-1704812456000] Order number: 0002

📄 [PRINT-SESSION-1704812456000] Step 1: Building customer receipt
✅ [PRINT-SESSION-1704812456000] Customer receipt printed successfully in 850ms

🍴 [PRINT-SESSION-1704812456000] Step 2: Processing kitchen tickets
🍴 [PRINT-SESSION-1704812456000] Kitchen routing: Falafel=0 items, Shawarma=0 items
➖ [PRINT-SESSION-1704812456000] No Falafel items, skipping
➖ [PRINT-SESSION-1704812456000] No Shawarma items, skipping

🔄 [PRINT-SESSION-1704812456000] Step 3: Reconnecting customer printer
✅ [PRINT-SESSION-1704812456000] Customer printer reconnected successfully in 221ms
✅ [PRINT-SESSION-1704812456000] Print sequence completed successfully
```

### ❌ Error Example (Printer Connection Failed)

```
🖨️ [PRINT-SESSION-1704812567000] Starting print sequence
🔍 [PRINT-SESSION-1704812567000] Validating order data
✓ [PRINT-SESSION-1704812567000] Order has 4 items

📄 [PRINT-SESSION-1704812567000] Step 1: Building customer receipt
📄 [PRINT-SESSION-1704812567000] Customer receipt built: 2345 bytes in 142ms
⚠️ [PRINT-SESSION-1704812567000] Customer receipt FAILED to print

🍴 [PRINT-SESSION-1704812567000] Step 2: Processing kitchen tickets
🥙 [PRINT-SESSION-1704812567000] Building Falafel kitchen ticket (2 items)
🥙 [PRINT-SESSION-1704812567000] Falafel ticket built: 1123 bytes in 95ms
⚠️ [PRINT-SESSION-1704812567000] Falafel kitchen ticket FAILED to print

🔄 [PRINT-SESSION-1704812567000] Step 3: Reconnecting customer printer
⚠️ [PRINT-SESSION-1704812567000] FAILED to reconnect customer printer (MAC: 00:11:22:33:44:55)
✅ [PRINT-SESSION-1704812567000] Print sequence completed successfully
```

### ❌ Critical Error Example (Arabic Font Not Loaded)

```
🖨️ [PRINT-SESSION-1704812678000] Starting print sequence
📄 [PRINT-SESSION-1704812678000] Step 1: Building customer receipt
✅ [PRINT-SESSION-1704812678000] Customer receipt printed successfully

🍴 [PRINT-SESSION-1704812678000] Step 2: Processing kitchen tickets
🥙 [PRINT-SESSION-1704812678000] Building Falafel kitchen ticket (2 items)
buildKitchen() → rendering kitchen name: "مطبخ الفلافل"
_arabicTextLineAsRaster() → text: "مطبخ الفلافل" (len=12, fontSize=28, align=center)
_arabicTextLineAsRaster() ⚠ arabicFontFamily == null (Arabic may break)
_arabicTextLineAsRaster() ✗ CRITICAL: No Arabic font configured!
❌ [PRINT-SESSION-1704812678000] ERROR building/printing Falafel ticket: StateError: Arabic font family not configured
❌ [PRINT-SESSION-1704812678000] CRITICAL ERROR in printAll: StateError: Arabic font family not configured

🔄 [PRINT-SESSION-1704812678000] Attempting emergency reconnection to customer printer
✅ [PRINT-SESSION-1704812678000] Emergency reconnection successful
```

## Detailed Logging Breakdown

### 1. Triple Printer Logs (`TriplePrinter`)

#### Session Start
```
🖨️ [PRINT-SESSION-xxx] Starting print sequence
```

#### Order Validation
```
🔍 [PRINT-SESSION-xxx] Validating order data
✓ [PRINT-SESSION-xxx] Order has X items
✓ [PRINT-SESSION-xxx] Order number: XXXX
⚠️ [PRINT-SESSION-xxx] WARNING: Order has no items
⚠️ [PRINT-SESSION-xxx] WARNING: Order has no order number
```

#### Customer Receipt
```
📄 [PRINT-SESSION-xxx] Step 1: Building customer receipt
📄 [PRINT-SESSION-xxx] Customer receipt built: X bytes in Xms
✅ [PRINT-SESSION-xxx] Customer receipt printed successfully in Xms
⚠️ [PRINT-SESSION-xxx] Customer receipt FAILED to print
```

#### Kitchen Routing
```
🍴 [PRINT-SESSION-xxx] Step 2: Processing kitchen tickets
🍴 [PRINT-SESSION-xxx] Kitchen routing: Falafel=X items, Shawarma=X items
```

#### Falafel Kitchen
```
🥙 [PRINT-SESSION-xxx] Building Falafel kitchen ticket (X items)
📝 [PRINT-SESSION-xxx] Kitchen name "مطبخ الفلافل" - Arabic: true
📝 [PRINT-SESSION-xxx] Item 1: "فلافل" - Arabic: true, Notes: "x" - Arabic notes: true
🥙 [PRINT-SESSION-xxx] Falafel ticket built: X bytes in Xms
✅ [PRINT-SESSION-xxx] Falafel ticket printed successfully in Xms
⚠️ [PRINT-SESSION-xxx] Falafel kitchen ticket FAILED to print
❌ [PRINT-SESSION-xxx] ERROR building/printing Falafel ticket: [error]
➖ [PRINT-SESSION-xxx] No Falafel items, skipping
```

#### Shawarma Kitchen
```
🌯 [PRINT-SESSION-xxx] Building Shawarma kitchen ticket (X items)
📝 [PRINT-SESSION-xxx] Kitchen name "مطبخ الشاورما والوجبات الخفيفة" - Arabic: true
📝 [PRINT-SESSION-xxx] Item 1: "شاورما" - Arabic: true, Notes: none - Arabic notes: false
🌯 [PRINT-SESSION-xxx] Shawarma ticket built: X bytes in Xms
✅ [PRINT-SESSION-xxx] Shawarma ticket printed successfully in Xms
⚠️ [PRINT-SESSION-xxx] Shawarma kitchen ticket FAILED to print
❌ [PRINT-SESSION-xxx] ERROR building/printing Shawarma ticket: [error]
➖ [PRINT-SESSION-xxx] No Shawarma items, skipping
```

#### Reconnection
```
🔄 [PRINT-SESSION-xxx] Step 3: Reconnecting customer printer
✅ [PRINT-SESSION-xxx] Customer printer reconnected successfully in Xms (MAC: xx:xx:xx:xx:xx:xx)
⚠️ [PRINT-SESSION-xxx] FAILED to reconnect customer printer (MAC: xx:xx:xx:xx:xx:xx)
⚠️ [PRINT-SESSION-xxx] No customer printer assigned, cannot reconnect
```

#### Error Recovery
```
❌ [PRINT-SESSION-xxx] CRITICAL ERROR in printAll: [error]
🔄 [PRINT-SESSION-xxx] Attempting emergency reconnection to customer printer
✅ [PRINT-SESSION-xxx] Emergency reconnection successful
⚠️ [PRINT-SESSION-xxx] Emergency reconnection failed
❌ [PRINT-SESSION-xxx] Emergency reconnection threw error: [error]
```

### 2. Receipt Builder Logs (`ReceiptBuilder`)

#### Kitchen Ticket Building
```
buildKitchen() → start; kitchen="مطبخ الفلافل", items=2
buildKitchen() → rendering kitchen name: "مطبخ الفلافل"
buildKitchen() ✓ kitchen name rendered: X bytes
buildKitchen() → rendering item 1/2: "فلافل" (qty: 2)
buildKitchen() ✓ item rendered: X bytes
buildKitchen() → rendering notes: "بدون بصل"
buildKitchen() ✓ notes rendered: X bytes
buildKitchen() ✗ FAILED to render notes "...": [error]
buildKitchen() ⚠ Continuing without notes...
buildKitchen() → rendering order number: "0001"
buildKitchen() ✓ order number rendered: X bytes
buildKitchen() → rendering timestamp: "2025-01-09 14:30:15"
buildKitchen() ✓ timestamp rendered: X bytes
buildKitchen() ✓ X bytes in Xms
buildKitchen() ✗✗✗ CRITICAL ERROR: [error]
```

#### Arabic Raster Rendering
```
_arabicTextLineAsRaster() → text: "مطبخ الفلافل" (len=12, fontSize=28, align=center)
_arabicTextLineAsRaster() → Arabic detected: true, font: NotoNaskhArabic
_arabicTextLineAsRaster() → building paragraph...
_arabicTextLineAsRaster() ✓ paragraph built (height: 45.5px)
_arabicTextLineAsRaster() → rendering to 576x58px canvas
_arabicTextLineAsRaster() → converting to image...
_arabicTextLineAsRaster() ✓ rasterized to PNG (X bytes)
_arabicTextLineAsRaster() → decoding PNG...
_arabicTextLineAsRaster() ✓ PNG decoded (576x58)
_arabicTextLineAsRaster() → converting to ESC/POS raster...
_arabicTextLineAsRaster() ✓ converted to ESC/POS (X bytes)
```

#### Errors in Raster Rendering
```
_arabicTextLineAsRaster() ⚠ arabicFontFamily == null (Arabic may break)
_arabicTextLineAsRaster() ✗ CRITICAL: No Arabic font configured!
_arabicTextLineAsRaster() ✗ FAILED to build/layout paragraph: [error]
_arabicTextLineAsRaster() ✗ toByteData returned null
_arabicTextLineAsRaster() ✗ FAILED to rasterize: [error]
_arabicTextLineAsRaster() ✗ PNG decode returned null
_arabicTextLineAsRaster() ✗ FAILED to convert to ESC/POS raster: [error]
```

## Common Issues and Their Log Signatures

### Issue 1: Arabic Font Not Loaded
**Log Signature:**
```
_arabicTextLineAsRaster() ⚠ arabicFontFamily == null (Arabic may break)
_arabicTextLineAsRaster() ✗ CRITICAL: No Arabic font configured!
```
**Solution:** Ensure `ReceiptBuilder.create()` is called with proper font configuration:
```dart
arabicFontFamily: 'NotoNaskhArabic',
arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
```

### Issue 2: Printer Not Connected
**Log Signature:**
```
⚠️ [PRINT-SESSION-xxx] Customer receipt FAILED to print
⚠️ [PRINT-SESSION-xxx] Falafel kitchen ticket FAILED to print
```
**Solution:** Check Bluetooth connection status and ensure printer is paired and within range.

### Issue 3: No Items for Kitchen
**Log Signature:**
```
➖ [PRINT-SESSION-xxx] No Falafel items, skipping
➖ [PRINT-SESSION-xxx] No Shawarma items, skipping
```
**Solution:** This is normal if the order doesn't contain items for that kitchen.

### Issue 4: Arabic Text Not Rendering
**Log Signature:**
```
📝 [PRINT-SESSION-xxx] Item 1: "???" - Arabic: false
_arabicTextLineAsRaster() → Arabic detected: false
```
**Solution:** Check that item names are actually in Arabic in the database.

### Issue 5: Reconnection Failed
**Log Signature:**
```
⚠️ [PRINT-SESSION-xxx] FAILED to reconnect customer printer (MAC: xx:xx:xx:xx:xx:xx)
```
**Solution:** Check printer is still powered on and in range. May need to manually reconnect.

## Performance Monitoring

The logs include timing information to help identify performance bottlenecks:

- **Building time**: How long to generate the receipt bytes
- **Printing time**: How long to transmit to printer
- **Reconnection time**: How long to reconnect printer

Example:
```
📄 Customer receipt built: 2456 bytes in 145ms  ← Building took 145ms
✅ Customer receipt printed successfully in 890ms  ← Printing took 890ms
✅ Customer printer reconnected successfully in 234ms  ← Reconnection took 234ms
```

## Filtering Logs

### View Only Print Sessions
```bash
flutter logs | grep "PRINT-SESSION"
```

### View Only Errors
```bash
flutter logs | grep "❌\|✗"
```

### View Only Warnings
```bash
flutter logs | grep "⚠️"
```

### View Specific Kitchen
```bash
flutter logs | grep "Falafel"
# or
flutter logs | grep "Shawarma"
```

### View Arabic Validation
```bash
flutter logs | grep "ArabicValidation"
```

## Enabling Debug Mode

To get even more detailed logs from `ReceiptBuilder`, enable debug mode:

```dart
final builder = await ReceiptBuilder.create(
  paper: PaperSize.mm80,
  arabicFontFamily: 'NotoNaskhArabic',
  arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
  useArabicIndicDigits: true,
  debug: true,  // ← Enable detailed logging
);
```

## Production vs Development

### Development
- Keep `debug: true` in ReceiptBuilder
- Monitor logs actively during testing
- Use log filtering to focus on specific issues

### Production
- Set `debug: false` in ReceiptBuilder to reduce log noise
- Only critical errors and warnings will be logged
- Print session tracking remains active for troubleshooting

## Troubleshooting Workflow

1. **Identify the session ID** of the failed print job
2. **Filter logs** by that session ID
3. **Look for the first ❌ or ⚠️** in the sequence
4. **Check the detailed error** in ReceiptBuilder logs
5. **Verify font loading** if Arabic rendering fails
6. **Check printer connection** if transmission fails
7. **Review timing** if performance is slow

## Example: Debugging a Failed Kitchen Print

1. Find the failed session:
```bash
flutter logs | grep "PRINT-SESSION" | grep "FAILED"
```

2. Get all logs for that session:
```bash
flutter logs | grep "PRINT-SESSION-1704812567000"
```

3. Look for the first error:
```bash
flutter logs | grep "PRINT-SESSION-1704812567000" | grep "❌\|✗"
```

4. Check Arabic validation:
```bash
flutter logs | grep "PRINT-SESSION-1704812567000" | grep "ArabicValidation"
```

5. Review the detailed error from ReceiptBuilder

## Log Retention

Logs are ephemeral and only available during the app session. For permanent logging:

1. Consider implementing a file logger
2. Send critical errors to a crash reporting service (Firebase Crashlytics, Sentry)
3. Store print session summaries in local database

---

**Created**: January 9, 2025  
**Last Updated**: January 9, 2025  
**Status**: Active
