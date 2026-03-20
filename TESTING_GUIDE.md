# Testing Guide - Dynamic Print Categories

## Test Environment Setup

### Prerequisites
- Running Android/iOS app (not web)
- Bluetooth printers paired (optional, can test without actual printers)
- Multiple product categories in your system

### Debug Mode
The implementation includes extensive debug output. Monitor logcat/console:
```
flutter logs
```

## Test Scenarios

### Test 1: Initial Load (Default Behavior)
**Objective**: Verify app loads with default categories

**Steps**:
1. Start app with fresh installation (or cleared SharedPreferences)
2. Navigate to Main Sales Page
3. Look for debug output: `📋 PrintCategoryManager loaded`
4. Verify defaults are loaded

**Expected**:
```
✓ Debug shows: Falafel: {2}, Shawarma: {3, 6, 7, 8, 9}
✓ Printer icon is visible and clickable in top-right
```

---

### Test 2: Open Printer Setup Dialog
**Objective**: Verify printer setup dialog opens correctly

**Steps**:
1. Click printer icon (🖨️) in top toolbar
2. Wait for dialog to load

**Expected**:
```
✓ PrinterSetupDialog appears
✓ Shows paired devices list
✓ Shows "Configure Categories" button
✓ No errors in console
```

---

### Test 3: Open Category Configuration Dialog
**Objective**: Verify category selection dialog opens with categories

**Steps**:
1. In PrinterSetupDialog, click "Configure Categories" button
2. Wait for dialog to load

**Expected**:
```
✓ PrintCategorySelectionDialog appears
✓ Shows three columns: Falafel | Shawarma & Snacks | Unassigned
✓ Shows "Click to assign" section with available categories
✓ Current assignments shown as chips
```

**Example Dialog State**:
```
🍗 Falafel          🌯 Shawarma & Snacks    ❌ Unassigned
├─ Chip: Category 2 ├─ Chip: Category 3     │
│                   ├─ Chip: Category 6     │
│                   ├─ Chip: Category 7     │
├─ Category 1 btn   ├─ Category 9 btn       └─ Category 4 btn
├─ Category 5 btn   └─ Category 8 btn
```

---

### Test 4: Assign Category to Kitchen
**Objective**: Verify categories can be assigned and moved

**Steps**:
1. In the Falafel section, click on "Category 5" button
2. Verify it appears as a chip in Falafel section

**Expected**:
```
✓ Category 5 button disappears from "Click to assign"
✓ Chip appears in Falafel section
✓ If it was in another section, it's removed from there
```

---

### Test 5: Unassign Category
**Objective**: Verify categories can be unassigned

**Steps**:
1. Find a chip in any section (e.g., "Category 3" in Shawarma)
2. Click the ✕ button on the chip

**Expected**:
```
✓ Chip is removed
✓ Category button reappears in "Click to assign" section
✓ Button becomes available again
```

---

### Test 6: Save Configuration
**Objective**: Verify configuration is saved to SharedPreferences

**Steps**:
1. Assign categories (e.g., add Category 5 to Falafel)
2. Click "Save Configuration" button
3. Check console for debug output

**Expected**:
```
✓ Debug shows: ✅ Saved all categories - Falafel: {2, 5}, Shawarma: {...}
✓ Snackbar shows: "✅ Print category routing saved"
✓ Dialog closes
✓ Returns to PrinterSetupDialog
```

---

### Test 7: Verify Persistent Storage
**Objective**: Verify configuration persists after app restart

**Steps**:
1. Configure categories (e.g., Falafel: {2, 7}, Shawarma: {3, 6})
2. Click "Save Configuration"
3. Close the app completely
4. Restart the app
5. Click printer icon → "Configure Categories"

**Expected**:
```
✓ Previous configuration is shown
✓ Falafel shows chips: Category 2, Category 7
✓ Shawarma shows chips: Category 3, Category 6
✓ Console shows: 📋 PrintCategoryManager loaded - Falafel: {2, 7}, Shawarma: {3, 6}
```

---

### Test 8: Print Order with Default Categories
**Objective**: Verify printing works with default categories

**Steps**:
1. Clear SharedPreferences to force defaults
2. Create an order with items from Category 2 and Category 3
3. Click print button
4. Complete the print dialog

**Expected**:
```
✓ Items from Category 2 route to Falafel printer
✓ Items from Category 3 route to Shawarma printer
✓ No routing errors in console
```

---

### Test 9: Print Order with Custom Categories
**Objective**: Verify printing works with custom configuration

**Steps**:
1. Configure: Falafel {2, 7}, Shawarma {3, 6}
2. Create order with items from Categories 2, 3, 7, 6
3. Click print button

**Expected**:
```
✓ Category 2 items → Falafel printer
✓ Category 7 items → Falafel printer
✓ Category 3 items → Shawarma printer
✓ Category 6 items → Shawarma printer
✓ Debug shows: routing completed successfully
```

---

### Test 10: Multiple Configuration Changes
**Objective**: Verify multiple save operations work correctly

**Steps**:
1. Configure and save: Falafel {2}, Shawarma {3, 6, 7}
2. Open dialog again and modify to: Falafel {2, 8}, Shawarma {3, 6}
3. Save again
4. Repeat 2-3 more times with different configurations

**Expected**:
```
✓ Each save creates new debug print
✓ Latest configuration is used for printing
✓ No duplicate entries or corruption
✓ SharedPreferences shows latest values
```

---

### Test 11: Unassigned Categories Behavior
**Objective**: Verify unassigned categories don't print

**Steps**:
1. Configure: Falafel {2}, Shawarma {3}, leave others unassigned
2. Create order with:
   - Category 2 (1 item)
   - Category 3 (1 item)
   - Category 4 (1 item) - unassigned
   - Category 5 (1 item) - unassigned
3. Print order
4. Check which items were printed

**Expected**:
```
✓ Category 2 → Falafel printer
✓ Category 3 → Shawarma printer
✓ Categories 4, 5 → NOT printed (or printed only to customer receipt)
✓ No routing errors for unassigned categories
```

---

### Test 12: Cancel Configuration Dialog
**Objective**: Verify unsaved changes are discarded

**Steps**:
1. Open configuration dialog
2. Assign some categories
3. Click "Cancel" button
4. Open dialog again

**Expected**:
```
✓ Dialog closes without saving
✓ When reopened, shows previous configuration
✓ Changes are not persisted
```

---

### Test 13: Category Display Names
**Objective**: Verify category names display correctly, not just IDs

**Steps**:
1. Open configuration dialog
2. Look at chips and buttons

**Expected**:
```
✓ Shows category names: "Falafel", "Shawarma", etc.
✓ NOT just numbers: "Category 2", "Category 3"
✓ Names match system category definitions
```

---

### Test 14: Large Number of Categories
**Objective**: Verify dialog handles many categories

**Steps**:
1. If system has 20+ categories
2. Open configuration dialog
3. Scroll through available categories

**Expected**:
```
✓ All categories are visible
✓ Dialog scrolls smoothly
✓ No layout issues
✓ All categories are assignable
```

---

### Test 15: No Categories Available
**Objective**: Verify graceful handling

**Steps**:
1. (If possible) Remove all categories from system
2. Open configuration dialog

**Expected**:
```
✓ Dialog shows helpful message
✓ No crash or error
✓ Graceful degradation
```

---

## Debug Checklist

Monitor these debug prints during testing:

```
📋 PrintCategoryManager loaded - Falafel: {...}, Shawarma: {...}
✅ Saved falafel categories: {...}
✅ Saved shawarma categories: {...}
✅ Saved all categories - Falafel: {...}, Shawarma: {...}
✅ Cleared all print categories
❌ Error saving falafel categories: {...}
❌ Error saving shawarma categories: {...}
❌ Error saving all categories: {...}
❌ Error clearing categories: {...}
❌ Print error: {...}
```

---

## SharedPreferences Inspection

To verify storage:

```dart
// In your test/debug code
import 'package:shared_preferences/shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();
print('Falafel: ${prefs.getString('print_falafel_categories')}');
print('Shawarma: ${prefs.getString('print_shawarma_categories')}');
```

Expected output:
```
Falafel: "[2,7,15]"
Shawarma: "[3,6,8,9]"
```

---

## Error Scenarios

### Scenario A: Permission Denied
**Test**: If SharedPreferences write fails
```
Expected: ❌ Error saving falafel categories: Permission denied
App should still function with defaults
```

### Scenario B: Corrupted Data
**Test**: Manually insert invalid JSON into SharedPreferences
```
Expected: App catches exception and ignores corrupt data
Uses defaults instead
```

### Scenario C: Missing Categories
**Test**: Reference non-existent category ID
```
Expected: Gracefully handles missing categories
Shows "(Unknown)" for missing category
```

---

## Performance Testing

### Test: Configuration Dialog Performance
- Measure dialog open time
- Measure scroll smoothness
- Measure save operation time

**Target**: 
- Dialog opens < 500ms
- Scroll is smooth (60 FPS)
- Save completes < 100ms

---

## Integration Testing

### With Real Printers
1. Pair 3 Bluetooth printers
2. Assign to Customer, Falafel, Shawarma roles
3. Configure categories
4. Print test orders
5. Verify correct printer receives correct items

### Without Real Printers
1. Test configuration ui without printers
2. Verify routing logic with mock data
3. Check debug prints match expected routing

---

## Regression Testing

Run these to ensure no existing functionality broke:

- [ ] Printer pairing still works
- [ ] Test print still works
- [ ] Print dialog still shows
- [ ] Orders still print to customer receipt
- [ ] Multiple printers can be configured
- [ ] Other POS features still work

