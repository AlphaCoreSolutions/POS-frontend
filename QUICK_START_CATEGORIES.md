# Quick Start Guide - Dynamic Print Categories

## 🚀 What's New?

Your POS system now supports **dynamic category routing for printing**. Instead of hardcoded category assignments, users can configure which product categories print to which kitchen/printer with changes saved automatically.

## 📋 Quick Setup

### 1. Access the Configuration
In the main sales page, click the **printer icon** (🖨️) in the top-right corner.

### 2. Open Category Configuration
In the "Printer Setup" dialog, click the **"Configure Categories"** button.

### 3. Assign Categories
The configuration dialog shows three columns:

| 🍗 Falafel | 🌯 Shawarma & Snacks | ❌ Unassigned |
|-----------|-------------------|------------|
| Click categories to assign | Click categories to assign | Unassigned categories |

**How to assign:**
- **To move a category up**: Click a category in the "Click to assign" section
- **To unassign**: Click the ✕ on a chip

### 4. Save
Click **"Save Configuration"** to apply changes.

✅ **That's it!** Your configuration is saved to the device cache.

## 📝 Example Configuration

**Before:**
```
Falafel Kitchen → Category 2 only
Shawarma & Snacks → Categories 3, 6, 7, 8, 9
```

**After customization:**
```
Falafel Kitchen → Categories 2, 7, 15
Shawarma & Snacks → Categories 3, 6, 8, 9, 10
Unassigned → Category 4
```

## 🔄 How It Works

1. **Configure Once** - Set up your category routing
2. **Saved Automatically** - Configuration stored on device
3. **Applies to All Orders** - Every print uses your configuration
4. **Survives App Restart** - Settings persist after app closes

## 🛠️ Configuration Behavior

| Scenario | Behavior |
|----------|----------|
| First time setup | Uses default categories (2 for Falafel, 3,6,7,8,9 for Shawarma) |
| User configures categories | Uses custom configuration |
| App restarts | Loads saved configuration automatically |
| Configuration cleared | Falls back to defaults |

## 📍 Default Categories

If you don't configure, these defaults are used:

- **Falafel Kitchen**: Category ID 2
- **Shawarma & Snacks**: Category IDs 3, 6, 7, 8, 9

## ❓ Common Questions

**Q: Will my configuration survive app updates?**
A: Yes! Configuration is stored in device cache (SharedPreferences).

**Q: What if I change my mind?**
A: Open the configuration dialog anytime and reassign categories.

**Q: What if a category isn't assigned?**
A: Unassigned categories won't be printed to any kitchen printer.

**Q: Why doesn't my parent category appear?**
A: Only leaf categories (without subcategories) can be assigned for printing.

**Q: What if I have more than 2 kitchens?**
A: Currently supports Falafel, Shawarma & Snacks, and Customer. Contact support for custom configurations.

## 🔍 Troubleshooting

### Categories not being printed to the right printer

1. Open Printer Setup dialog
2. Click "Configure Categories"
3. Verify categories are assigned correctly
4. Check that your products have the correct category IDs
5. Print a test order

### Configuration doesn't persist

1. Check if your device has storage permissions
2. Restart the app
3. Reconfigure categories

### "Categories data not available" message

This shouldn't happen in normal use. If you see it:
1. Close the dialog
2. Refresh the categories list
3. Try again

## 📲 Technical Details

- **Storage**: SharedPreferences (device local storage)
- **Storage Keys**:
  - `print_falafel_categories` - Falafel category IDs
  - `print_shawarma_categories` - Shawarma category IDs
- **Format**: JSON array of category ID numbers
- **Persistence**: Survives app closes and restarts

## 🔗 Related Files

- `lib/services/print_category_manager.dart` - Manages category routing
- `lib/components/print_category_selection_dialog.dart` - UI for configuration
- `lib/pages/system_pages/main_page.dart` - Integration with printing system

