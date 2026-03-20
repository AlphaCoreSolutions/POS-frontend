# API Reference - Dynamic Print Categories

## PrintCategoryManager API

The `PrintCategoryManager` class is the core of the dynamic category routing system.

### Class Definition
```dart
class PrintCategoryManager with ChangeNotifier {
  // Getters
  Set<int> get falafelCategoryIds;
  Set<int> get shawarmaSnacksCategoryIds;
  bool get isConfigured;
  
  // Methods
  Future<void> load();
  Future<void> setFalafelCategories(Set<int> categoryIds);
  Future<void> setShawarmaSnacksCategories(Set<int> categoryIds);
  Future<void> setAllCategories({required Set<int> falafel, required Set<int> shawarma});
  Future<void> clear();
  String? getCategoryName(int categoryId, List<Category> allCategories);
  List<String> getFalafelCategoryNames(List<Category> allCategories);
  List<String> getShawarmaSnacksCategoryNames(List<Category> allCategories);
  String getConfigurationSummary(List<Category> allCategories);
}
```

### Properties

#### `falafelCategoryIds`
```dart
Set<int> get falafelCategoryIds
```
Returns an unmodifiable set of category IDs routed to the Falafel kitchen.

**Example**:
```dart
final ids = manager.falafelCategoryIds;  // Returns {2, 7, 15}
```

#### `shawarmaSnacksCategoryIds`
```dart
Set<int> get shawarmaSnacksCategoryIds
```
Returns an unmodifiable set of category IDs routed to the Shawarma & Snacks kitchen.

**Example**:
```dart
final ids = manager.shawarmaSnacksCategoryIds;  // Returns {3, 6, 8, 9}
```

#### `isConfigured`
```dart
bool get isConfigured
```
Returns `true` if any categories have been configured, `false` otherwise.

**Example**:
```dart
if (manager.isConfigured) {
  print('User has custom configuration');
} else {
  print('Using defaults');
}
```

### Methods

#### `load()`
```dart
Future<void> load()
```
Load saved category routing from SharedPreferences. Call this once during app initialization.

**Usage**:
```dart
@override
void initState() {
  super.initState();
  _printCategoryManager.load();
}
```

**Side Effects**:
- Reads from SharedPreferences
- Updates internal state
- Notifies listeners (for UI rebuild)
- Prints debug output

#### `setFalafelCategories()`
```dart
Future<void> setFalafelCategories(Set<int> categoryIds)
```
Save category IDs for the Falafel kitchen and persist to device cache.

**Parameters**:
- `categoryIds`: Set of category IDs (e.g., {2, 7, 15})

**Usage**:
```dart
await manager.setFalafelCategories({2, 7, 15});
```

**Side Effects**:
- Writes to SharedPreferences
- Updates internal state
- Notifies listeners
- Prints debug output

#### `setShawarmaSnacksCategories()`
```dart
Future<void> setShawarmaSnacksCategories(Set<int> categoryIds)
```
Save category IDs for the Shawarma & Snacks kitchen and persist to device cache.

**Parameters**:
- `categoryIds`: Set of category IDs (e.g., {3, 6, 8, 9})

**Usage**:
```dart
await manager.setShawarmaSnacksCategories({3, 6, 8, 9});
```

#### `setAllCategories()`
```dart
Future<void> setAllCategories({
  required Set<int> falafel,
  required Set<int> shawarma,
})
```
Save both Falafel and Shawarma category IDs in a single operation. Most efficient when setting both at once.

**Parameters**:
- `falafel`: Set of category IDs for Falafel kitchen
- `shawarma`: Set of category IDs for Shawarma & Snacks kitchen

**Usage**:
```dart
await manager.setAllCategories(
  falafel: {2, 7},
  shawarma: {3, 6, 8, 9},
);
```

**Advantages**:
- Single SharedPreferences write operation
- Single listener notification
- Atomic update (both succeed or both fail)

#### `clear()`
```dart
Future<void> clear()
```
Clear all saved category configuration and reset to empty state.

**Usage**:
```dart
// Reset to defaults
await manager.clear();
```

**Side Effects**:
- Removes keys from SharedPreferences
- Clears internal state
- Notifies listeners

#### `getCategoryName()`
```dart
String? getCategoryName(int categoryId, List<Category> allCategories)
```
Get the display name for a category ID.

**Parameters**:
- `categoryId`: Category ID number
- `allCategories`: List of all categories in system

**Returns**:
- Category name string, or `null` if not found

**Usage**:
```dart
final name = manager.getCategoryName(2, categories);  // Returns "Falafel"
```

#### `getFalafelCategoryNames()`
```dart
List<String> getFalafelCategoryNames(List<Category> allCategories)
```
Get all display names for categories routed to Falafel kitchen.

**Parameters**:
- `allCategories`: List of all categories in system

**Returns**:
- List of category names (e.g., ["Falafel", "Spicy Falafel"])

**Usage**:
```dart
final names = manager.getFalafelCategoryNames(categories);
print(names);  // ["Falafel", "Spicy Falafel"]
```

#### `getShawarmaSnacksCategoryNames()`
```dart
List<String> getShawarmaSnacksCategoryNames(List<Category> allCategories)
```
Get all display names for categories routed to Shawarma & Snacks kitchen.

**Parameters**:
- `allCategories`: List of all categories in system

**Returns**:
- List of category names

#### `getConfigurationSummary()`
```dart
String getConfigurationSummary(List<Category> allCategories)
```
Get human-readable summary of current configuration for display in UI.

**Parameters**:
- `allCategories`: List of all categories in system

**Returns**:
- String with emoji and category names, or "Not configured"

**Example**:
```dart
final summary = manager.getConfigurationSummary(categories);
print(summary);
// Output:
// 🍗 Falafel: Falafel, Spicy Falafel
// 🌯 Shawarma: Shawarma Chicken, Beef Shawarma, Chicken Wrap
```

---

## PrintCategorySelectionDialog Widget

The `PrintCategorySelectionDialog` provides the UI for users to assign categories.

### Constructor
```dart
PrintCategorySelectionDialog({
  required List<Category> allCategories,
  required PrintCategoryManager categoryManager,
})
```

### Parameters
- `allCategories`: List of all product categories
- `categoryManager`: Instance of PrintCategoryManager to save changes

### Usage
```dart
showDialog(
  context: context,
  builder: (_) => PrintCategorySelectionDialog(
    allCategories: _allCategories,
    categoryManager: _printCategoryManager,
  ),
);
```

### Features
- Three-column layout (Falafel | Shawarma & Snacks | Unassigned)
- Displays current assignments as chips
- Shows available categories as buttons
- Save and Cancel buttons
- Prevents same category in multiple kitchens

---

## Integration with KitchenRouter

The `KitchenRouter` is the bridge between configuration and actual printing.

### Updated Usage
```dart
// Before: Hardcoded categories
final router = KitchenRouter(
  falafelCategoryIds: {2},
  shawarmaSnacksCategoryIds: {3, 6, 7, 8, 9},
);

// After: Dynamic categories
final falafelIds = manager.falafelCategoryIds.isNotEmpty 
    ? manager.falafelCategoryIds 
    : {2};
final shawarmaIds = manager.shawarmaSnacksCategoryIds.isNotEmpty 
    ? manager.shawarmaSnacksCategoryIds 
    : {3, 6, 7, 8, 9};

final router = KitchenRouter(
  falafelCategoryIds: falafelIds,
  shawarmaSnacksCategoryIds: shawarmaIds,
);
```

---

## Storage Format

### SharedPreferences Keys
```
print_falafel_categories      String (JSON array)
print_shawarma_categories     String (JSON array)
```

### Data Format
Categories are stored as JSON arrays of integers:

```json
{
  "print_falafel_categories": "[2, 7, 15, 18]",
  "print_shawarma_categories": "[3, 6, 8, 9, 10]"
}
```

### Reading from SharedPreferences
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final prefs = await SharedPreferences.getInstance();

// Read falafel categories
final falafelJson = prefs.getString('print_falafel_categories');
final falafelIds = jsonDecode(falafelJson) as List;
final falafelSet = falafelIds.map((e) => e as int).toSet();
```

---

## State Management

### With Provider
If using Provider for state management:

```dart
// In your provider
class PrintCategoryProvider extends ChangeNotifier {
  final PrintCategoryManager _manager = PrintCategoryManager();
  
  Future<void> initialize() async {
    await _manager.load();
    notifyListeners();
  }
  
  Future<void> updateConfiguration(...) async {
    // ... update logic
    notifyListeners();  // Rebuild UI automatically
  }
}

// In your widget
Consumer<PrintCategoryProvider>(
  builder: (context, provider, child) {
    return Text(provider._manager.isConfigured ? 'Configured' : 'Default');
  },
)
```

### Listening for Changes
The `PrintCategoryManager` extends `ChangeNotifier`, so you can listen for changes:

```dart
manager.addListener(() {
  print('Categories changed!');
  setState(() {});
});
```

---

## Error Handling

### Expected Exceptions

#### SharedPreferences Write Failure
```dart
try {
  await manager.setFalafelCategories({2, 7});
} catch (e) {
  print('Failed to save: $e');
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to save configuration: $e')),
  );
}
```

#### Missing Category
```dart
final name = manager.getCategoryName(999, categories);
if (name == null) {
  print('Category 999 not found');
}
```

---

## Customization Guide

### Extend for Additional Kitchens

To add a third kitchen (e.g., Beverages):

1. **Update PrinterRole enum** (bluetooth_printing_service.dart):
```dart
enum PrinterRole { customer, falafel, shawarmaSnacks, beverages }
```

2. **Update PrintCategoryManager**:
```dart
class PrintCategoryManager with ChangeNotifier {
  Set<int> _beveragesCategoryIds = {};
  
  Set<int> get beveragesCategoryIds => Set.unmodifiable(_beveragesCategoryIds);
  
  Future<void> setBeveragesCategories(Set<int> categoryIds) async {
    // ... similar implementation
  }
}
```

3. **Update PrintCategorySelectionDialog**:
```dart
Row(
  children: [
    // ... existing columns
    Expanded(
      child: _buildKitchenSection(
        title: '🥤 Beverages',
        color: Colors.blue,
        selectedIds: _selectedBeverages,
        leafCategories: leafCategories,
        onToggle: _toggleBeverageCategory,
      ),
    ),
  ],
)
```

4. **Update KitchenRouter and TriplePrinter** to handle beverages

---

## Best Practices

### 1. Load During App Initialization
```dart
@override
void initState() {
  super.initState();
  _manager.load();  // Load early
}
```

### 2. Use setAllCategories When Saving
```dart
// Efficient: Single write operation
await manager.setAllCategories(
  falafel: selectedFalafel,
  shawarma: selectedShawarma,
);
```

### 3. Show Configuration Summary
```dart
Text(manager.getConfigurationSummary(_allCategories))
```

### 4. Provide Fallback to Defaults
```dart
final ids = manager.falafelCategoryIds.isNotEmpty
    ? manager.falafelCategoryIds
    : {2};  // Default fallback
```

### 5. Handle Missing Categories Gracefully
```dart
final name = manager.getCategoryName(id, categories) ?? 'Unknown Category';
```

---

## Migration Guide

### From Hardcoded to Dynamic

Before:
```dart
final router = KitchenRouter(
  falafelCategoryIds: {2},
  shawarmaSnacksCategoryIds: {3, 6, 7, 8, 9},
);
```

After:
```dart
final manager = PrintCategoryManager();
await manager.load();

final router = KitchenRouter(
  falafelCategoryIds: manager.falafelCategoryIds.isEmpty ? {2} : manager.falafelCategoryIds,
  shawarmaSnacksCategoryIds: manager.shawarmaSnacksCategoryIds.isEmpty ? {3, 6, 7, 8, 9} : manager.shawarmaSnacksCategoryIds,
);
```

---

## Debugging

### Enable Debug Output
All operations print debug information:

```
✅ Saved falafel categories: {2, 7, 15}
✅ Saved shawarma categories: {3, 6, 8, 9}
📋 PrintCategoryManager loaded - Falafel: {2, 7}, Shawarma: {3, 6, 8, 9}
❌ Error saving falafel categories: Connection failed
```

### Inspect SharedPreferences
```dart
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
for (final key in keys) {
  if (key.startsWith('print_')) {
    print('$key: ${prefs.getString(key)}');
  }
}
```

### Reset for Testing
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('print_falafel_categories');
await prefs.remove('print_shawarma_categories');
```

