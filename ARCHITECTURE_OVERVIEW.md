# Visual Architecture Overview

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MAIN APP (main_page.dart)                   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ _MainPageState                                               │   │
│  │ ┌────────────────────────────────────────────────────────┐   │   │
│  │ │ _printCategoryManager: PrintCategoryManager            │   │   │
│  │ │ _allCategories: List<Category>                         │   │   │
│  │ │ _printReceipts(): Future<bool>                         │   │   │
│  │ └────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ initState() calls load()
         ├──────────────────────────────┐
         │                              │
         ▼                              ▼
     [LOAD]                         [SAVE]
         │                              │
         ▼                              ▼
┌────────────────────────┐  ┌────────────────────────────┐
│ PrintCategoryManager   │  │PrintCategorySelectionDialog│
│                        │  │(StatefulWidget)            │
│ • load()               │  │                            │
│ • setFalafel()         │  │ • Show 3 columns           │
│ • setShawarma()        │  │ • Assign categories        │
│ • setAllCategories()   │  │ • Save button              │
│ • getConfigSummary()   │  │                            │
│ • falafelCategoryIds   │  │ onSave:                    │
│ • shawarmaIds          │  │  setAllCategories()        │
└────────────────────────┘  └────────────────────────────┘
         │                          ▲
         │                          │
         │                          │ shown by
         │                          │
         ├──────────────────────────┤
         │                          │
         ▼                          ▼
    [Persistence]          [Printer Setup Dialog]
         │                          
         ▼                          
┌────────────────────────┐
│ SharedPreferences      │
│                        │
│ Keys:                  │
│ • print_falafel_      │
│   categories           │
│ • print_shawarma_     │
│   categories           │
│                        │
│ Format: JSON array     │
│ ["[2,7,15]",          │
│  "[3,6,8,9]"]         │
└────────────────────────┘
         │
    ┌────┴───────────────────────────────┐
    │ On each print order:               │
    │                                    │
    │ Load saved categories              │
    ▼                                    ▼
┌──────────────────┐         ┌──────────────────┐
│ KitchenRouter    │         │ TriplePrinter    │
│                  │         │                  │
│ split(order)     │         │ printAll(order)  │
│                  │         │                  │
│ Returns:         │         │ Uses Router to   │
│ {               │         │ route items      │
│   'falafel': [] │         │                  │
│   'shawarma': []│         │ Prints to 3      │
│ }               │         │ printers via     │
└──────────────────┘         │ BluetoothPrinter│
                             │                  │
                             │ • Customer       │
                             │ • Falafel        │
                             │ • Shawarma       │
                             └──────────────────┘
```

---

## User Flow Diagram

```
┌─────────────────┐
│  User clicks    │
│ Printer icon 🖨️ │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ PrinterSetupDialog opens │
│                          │
│ • Paired devices         │
│ • Printer assignments    │
│ • Test buttons           │
│ • Save button            │
│ • [Configure Categories] │◄─── NEW BUTTON
└────────┬─────────────────┘
         │
         │ User clicks
         │ "Configure Categories"
         ▼
┌────────────────────────────────────────────────┐
│   PrintCategorySelectionDialog opens          │
│                                                │
│  🍗 Falafel   │ 🌯 Shawarma & Snacks │ ❌ Unassigned │
│  ┌──────────┼──────────────────┼─────────────┐
│  │ Chip:    │ Chip:            │ (Empty)     │
│  │ Cat 2    │ Cat 3            │             │
│  │ Chip:    │ Chip:            │             │
│  │ Cat 7 ✕  │ Cat 6 ✕          │             │
│  │          │                  │             │
│  │ [Click to assign]           │             │
│  │ Cat 1    │ Cat 2            │ Cat 4       │
│  │ Cat 5    │ Cat 8            │ Cat 9       │
│  │ Cat 10   │ Cat 11           │             │
│  └──────────┴──────────────────┴─────────────┘
│                                                │
│              [Cancel] [Save Configuration]   │
└────────┬───────────────────────────────────────┘
         │
         └── User assigns categories
              (Click buttons to move)
         │
         └── User clicks "Save Configuration"
             │
             ▼
        setAllCategories()
             │
             ▼
        SharedPreferences.setString()
             │
             ◄─── SAVED TO DEVICE CACHE
             │
             ▼
        ChangeNotifier.notifyListeners()
             │
             ▼
        Dialog closes
             │
             ▼
        Back to PrinterSetupDialog
             │
             ▼
        User clicks "Save" to save printers
             │
             ▼
        Configuration complete ✓
```

---

## Data Flow Diagram

```
USER ACTION                  INTERNAL STATE              STORAGE
═══════════════════════════════════════════════════════════════════

Tap Category              PrintCategoryManager          SharedPreferences
     │                         │
     ├─ _selected += cat       │
     │     _unassigned -= cat  │
     │                         │
     └─ setState()             │
           │                   │
           └─ UI redraws       │

Click "Save"                    │
     │                         ▼
     ├─ setAllCategories()     
     │                    save to prefs
     │                         │
     └─────────────────────────►
                               │
                        print_falafel_categories
                        print_shawarma_categories
                               │
                          [JSON stored]

App restart          load() called
     │                         │
     ├─ PrintCategoryManager   │
     │    .load()              │
     │        │                │
     │        └─ Read from prefs
     │              │          │
     │              └──────────►
     │                    restore state
     │
     └─ _printCategoryManager
            ready to use
            
When printing      _printReceipts()
     │                   │
     ├─ Load categories   │
     │   from manager     │
     │        │           │
     │        ▼           │
     ├─ Create router with those IDs
     │        │           │
     │        ▼           │
     ├─ Print order routes based on categories
     │        │
     │        └─ Each item sends to correct kitchen
```

---

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    PRINTER SETUP FLOW                             │
└──────────────────────────────────────────────────────────────────┘

     ShowPrinterSetupDialog()
            │
            ├─ categories: List<Category>?
            ├─ categoryManager: PrintCategoryManager?
            │
            ▼
     PrinterSetupDialog
            │
            ├─ [Configure Categories] button ◄─── NEW
            │        │
            │        ▼
            │   _showCategoryConfig()
            │        │
            │        └─ Show PrintCategorySelectionDialog
            │             with categories + manager
            │             │
            │             ▼
            │        PrintCategorySelectionDialog
            │             │
            │             ├─ Display current assignments
            │             │
            │             ├─ Allow user to reassign
            │             │
            │             └─ manager.setAllCategories()
            │                  → saved to SharedPreferences
            │                  → ChangeNotifier notifies
            │                  → dialog closes
            │
            ├─ [Save] button
            │   └─ Save printer assignments
            │
            └─ [Test] button
                └─ Test each printer

┌──────────────────────────────────────────────────────────────────┐
│                    PRINTING FLOW                                   │
└──────────────────────────────────────────────────────────────────┘

Order created + User prints
        │
        ▼
   _printReceipts()
        │
        ├─ Load saved config:
        │     falafelIds = manager.falafelCategoryIds
        │     shawarmaIds = manager.shawarmaSnacksCategoryIds
        │
        ├─ Create KitchenRouter with those IDs
        │
        ├─ Create TriplePrinter with router
        │
        └─ printAll(order) 
             │
             ├─ router.split(order)
             │      └─ Distribute items by category
             │
             └─ Print each bucket:
                  • Falafel items → Falafel printer
                  • Shawarma items → Shawarma printer  
                  • Receipt → Customer printer
```

---

## State Management Lifecycle

```
┌───────────────────────────────────────────────────────────────┐
│              PrintCategoryManager State Transitions            │
└───────────────────────────────────────────────────────────────┘

Initial State:
   _falafelCategoryIds = {} (empty)
   _shawarmaSnacksCategoryIds = {} (empty)
        │
        │ App startup: load()
        │
        ▼
Loaded State:
   _falafelCategoryIds = {2, 7}          (from prefs)
   _shawarmaSnacksCategoryIds = {3, 6}   (from prefs)
        │
        │ Dialog opens: User assigns categories
        │
        ▼
User modifies in dialog:
   Temp state in PrintCategorySelectionDialog
   (changes not persisted yet)
        │
        ├─ User clicks Save
        │     │
        │     └─ manager.setAllCategories({2, 7}, {3, 6, 8})
        │        │
        │        └─ _falafelCategoryIds = {2, 7}
        │        └─ _shawarmaSnacksCategoryIds = {3, 6, 8}
        │        └─ Save to prefs
        │        └─ notifyListeners()
        │
        └─ User clicks Cancel
             └─ Discard changes, no state update

Saved State:
   _falafelCategoryIds = {2, 7}
   _shawarmaSnacksCategoryIds = {3, 6, 8}
        │
        │ Print order: Use these IDs
        │
        ▼
Printing:
   KitchenRouter uses {2, 7} and {3, 6, 8}
   to route items to correct printers
        │
        │ App restart
        │
        ▼
Back to Loaded State:
   load() restores from prefs
   {2, 7} and {3, 6, 8} are reloaded
```

---

## File Organization

```
lib/
├── services/
│   ├── print_category_manager.dart          [NEW]
│   │   └── PrintCategoryManager class
│   ├── kitchen_router.dart                  (existing)
│   ├── triple_printer.dart                  (existing)
│   └── bluetooth_printing_service.dart      (existing)
│
├── components/
│   ├── print_category_selection_dialog.dart [NEW]
│   │   └── PrintCategorySelectionDialog widget
│   ├── printer_setup_dialog.dart            [MODIFIED]
│   │   └── Updated with category config option
│   └── ...
│
├── pages/
│   └── system_pages/
│       └── main_page.dart                   [MODIFIED]
│           └── Integrated PrintCategoryManager
│
└── models/
    └── category_model.dart                  (existing)

root/
├── IMPLEMENTATION_GUIDE.md                  [NEW]
├── QUICK_START_CATEGORIES.md                [NEW]
├── TESTING_GUIDE.md                         [NEW]
├── API_REFERENCE.md                         [NEW]
├── SUMMARY.md                               [NEW]
├── CHANGE_LIST.md                           [NEW]
└── (this file)                              [NEW]
```

---

## Configuration Example

```
BEFORE Implementation:
════════════════════════
Hardcoded in main_page.dart:
   final router = KitchenRouter(
      falafelCategoryIds: {2},
      shawarmaSnacksCategoryIds: {3, 6, 7, 8, 9},
   );

To change: Modify code & rebuild

AFTER Implementation:
════════════════════════
Configured via UI:
   SharedPreferences:
      print_falafel_categories: "[2, 7, 15]"
      print_shawarma_categories: "[3, 6, 8, 9, 10]"

To change: Open dialog & reassign categories
           Changes applied immediately
           Changes persist after restart
```

---

## Storage Timeline

```
Time    Event                              Storage State
────────────────────────────────────────────────────────
 0:00   App first launch (new install)     (empty)
 0:05   User opens printer setup           (empty)
 0:10   User clicks "Configure Categories" (empty)
 0:15   User assigns categories            (temporary, not saved)
 0:20   User clicks "Save Configuration"   [Save to prefs]
        (now stored)                       falafel: [2,7]
                                          shawarma: [3,6,8,9]
 0:25   Dialog closes                      [State updated]
 0:30   User creates & prints order        [Use saved config]
 1:00   User reassigns categories          [Load from prefs]
 1:05   User saves new config              [Save to prefs]
                                          falafel: [2,7,15]
                                          shawarma: [3,6,8]
 1:10   App closes                         [Config saved]
 5:00   App restarts                       [Load from prefs]
        Configuration restored              Config still there
```

---

## Error Handling Flow

```
Operation          Error                    Fallback
─────────────────────────────────────────────────────────
Load from prefs    Read fails               Use empty Set
                                           Fall back to defaults
                                           when printing

Save to prefs      Write fails              Show error to user
                                           Keep previous state
                                           Retry on next action

Missing category   ID not in list           Skip (getCategoryName returns null)
                                           Item not printed to that kitchen

No categories      None assigned            Use hardcoded defaults
assigned                                    {2} and {3,6,7,8,9}

Permission denied  User denies access       Use defaults
                                           Show message to user

Corrupted JSON     Invalid format           Ignore, use defaults
                                           No crash
```

