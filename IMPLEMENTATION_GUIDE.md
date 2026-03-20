# Dynamic Print Category Routing - Implementation Guide

## Overview
This implementation allows users to dynamically configure which product categories should be printed to which kitchen/printer role, with changes persisted to the device's cache (SharedPreferences).

## Architecture

### Components

#### 1. PrintCategoryManager (`lib/services/print_category_manager.dart`)
**Purpose**: Manages the persistence and state of category routing

**Key Methods**:
- `load()` - Load saved routing from SharedPreferences
- `setFalafelCategories(Set<int>)` - Save falafel kitchen category IDs
- `setShawarmaSnacksCategories(Set<int>)` - Save shawarma kitchen category IDs
- `setAllCategories({required Set<int> falafel, required Set<int> shawarma})` - Save both at once
- `getConfigurationSummary(List<Category>)` - Get human-readable summary

**Properties**:
- `falafelCategoryIds` - Unmodifiable set of category IDs
- `shawarmaSnacksCategoryIds` - Unmodifiable set of category IDs
- `isConfigured` - Returns true if any categories are assigned

**Storage Keys**:
- `print_falafel_categories` - JSON array of falafel category IDs
- `print_shawarma_categories` - JSON array of shawarma category IDs

#### 2. PrintCategorySelectionDialog (`lib/components/print_category_selection_dialog.dart`)
**Purpose**: UI for assigning categories to printers

**Features**:
- Three-column layout (Falafel | Shawarma & Snacks | Unassigned)
- Drag-and-drop style category assignment
- Only shows leaf categories (no parent categories)
- Visual feedback with colored chips
- Save/Cancel buttons

**Usage**:
```dart
showDialog(
  context: context,
  builder: (_) => PrintCategorySelectionDialog(
    allCategories: categories,
    categoryManager: manager,
  ),
);
```

#### 3. Enhanced PrinterSetupDialog (`lib/components/printer_setup_dialog.dart`)
**Purpose**: Main printer configuration dialog with category routing option

**Changes**:
- Added optional `categories` and `categoryManager` parameters
- New "Configure Categories" button in actions
- Calls `_showCategoryConfig()` to open the selection dialog
- Updated `showPrinterSetupDialog()` function signature

**Function Signature**:
```dart
Future<void> showPrinterSetupDialog(
  BuildContext context, 
  {List<Category>? categories, 
   PrintCategoryManager? categoryManager}
)
```

#### 4. Main Page Integration (`lib/pages/system_pages/main_page.dart`)
**Changes**:
- Added `PrintCategoryManager _printCategoryManager` instance variable
- Load in `initState()`: `_printCategoryManager.load()`
- Updated `_printReceipts()` to use dynamic category routing
- Pass manager and categories to printer dialog

**Printing Logic**:
```dart
// In _printReceipts()
final falafelIds = _printCategoryManager.falafelCategoryIds.isNotEmpty 
    ? _printCategoryManager.falafelCategoryIds 
    : {2}; // Default fallback

final shawarmaIds = _printCategoryManager.shawarmaSnacksCategoryIds.isNotEmpty 
    ? _printCategoryManager.shawarmaSnacksCategoryIds 
    : {3, 6, 7, 8, 9}; // Default fallback

final router = KitchenRouter(
  falafelCategoryIds: falafelIds,
  shawarmaSnacksCategoryIds: shawarmaIds
);
```

## User Flow

### Step 1: Open Printer Setup
User clicks the printer icon in the top-right of MainPage
```
Icon(Icons.print) → showPrinterSetupDialog()
```

### Step 2: Show Setup Dialog
PrinterSetupDialog displays three sections:
- Printer assignments (Customer, Falafel, Shawarma & Snacks)
- Test buttons
- "Configure Categories" button

### Step 3: Configure Categories
User clicks "Configure Categories" button
```
→ PrintCategorySelectionDialog opens
```

### Step 4: Assign Categories
User clicks categories to move them between:
- 🍗 Falafel Kitchen
- 🌯 Shawarma & Snacks
- ❌ Unassigned

### Step 5: Save Configuration
User clicks "Save Configuration" button
```
→ PrintCategoryManager.setAllCategories() called
→ SharedPreferences updated
→ Dialog closes
```

### Step 6: Automatic Routing
Next time an order is printed:
```
1. _printReceipts() calls _printCategoryManager
2. Loads saved category IDs from cache
3. Creates KitchenRouter with dynamic IDs
4. Routes items to correct kitchen printer
```

## Default Behavior

If no configuration is saved, the app falls back to defaults:
- **Falafel Kitchen**: Category ID 2
- **Shawarma & Snacks**: Category IDs {3, 6, 7, 8, 9}

This ensures backward compatibility.

## Data Storage

### SharedPreferences Keys
```
print_falafel_categories      → JSON: [2, 7, 15]
print_shawarma_categories     → JSON: [3, 6, 8, 9]
```

### Example Stored Data
```json
{
  "print_falafel_categories": "[2, 7]",
  "print_shawarma_categories": "[3, 6, 8, 9, 10]"
}
```

## Debug Output

All operations include debug prints for troubleshooting:

```dart
📋 PrintCategoryManager loaded - Falafel: {2, 7}, Shawarma: {3, 6}
✅ Saved falafel categories: {2, 7}
✅ Saved shawarma categories: {3, 6, 8, 9}
✅ Saved all categories - Falafel: {2, 7}, Shawarma: {3, 6, 8, 9}
✅ Cleared all print categories
❌ Error loading print categories: (error details)
❌ Print error: (error details)
```

## Error Handling

### No Categories Available
- Dialog shows "No categories assigned" message
- Fallback defaults are used for printing
- User can reconfigure anytime

### Save Failures
- Error is logged to debugPrint
- User sees snackbar notification
- Previous configuration remains unchanged

### Missing Data
- If categories not passed to dialog, show error message
- Printer setup continues to work normally

## Testing Checklist

- [ ] Open printer setup dialog
- [ ] Click "Configure Categories" button
- [ ] Drag categories between sections
- [ ] Click "Save Configuration"
- [ ] Verify data in SharedPreferences (debug)
- [ ] Create order and print
- [ ] Verify correct printer receives correct items
- [ ] Restart app and verify categories still remembered
- [ ] Test fallback if SharedPreferences cleared

## Future Enhancements

1. **Add Support for More Kitchens**
   - Extend `PrinterRole` enum
   - Add more `KitchenRouter` constructor parameters
   - Create additional columns in dialog

2. **Drag-and-Drop**
   - Implement full drag-and-drop between sections
   - Add visual feedback during drag

3. **Category Groups**
   - Pre-defined category groups for quick setup
   - "Use Defaults" button

4. **Export/Import Configuration**
   - Export routing as JSON
   - Import configuration from another device

5. **Category Hierarchy Support**
   - Show parent categories
   - Allow category group selection

## Integration with KitchenRouter

The `KitchenRouter` class (`lib/services/kitchen_router.dart`) expects:
```dart
KitchenRouter({
  required Set<int> falafelCategoryIds,
  required Set<int> shawarmaSnacksCategoryIds,
})
```

The `split()` method routes items based on product `categoryId`:
```dart
Map<String, List<Map<String, dynamic>>> split(Map<String, dynamic> order) {
  // Splits order items by category into buckets
  // Returns: {'falafel': [...], 'shawarmaSnacks': [...]}
}
```

## Integration with TriplePrinter

The `TriplePrinter` class (`lib/services/triple_printer.dart`) uses the router:
```dart
TriplePrinter(
  btManager: bt,
  router: router, // Uses our dynamic router
)
```

When `printAll()` is called, it:
1. Calls `router.split()` to distribute items
2. Prints falafel items to falafel printer
3. Prints shawarma items to shawarma printer
4. Prints receipt to customer printer

