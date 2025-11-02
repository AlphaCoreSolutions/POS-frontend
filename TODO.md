# Main Page Refactoring TODO

## Phase 1: Preparation
- [x] Create constants.dart for colors, sizes, and strings
- [x] Create pos_provider.dart for state management using Provider
- [x] Create services/ directory for business logic separation

## Phase 2: Extract Widgets
- [ ] Create components/product_grid.dart
- [ ] Create components/order_summary.dart
- [ ] Create components/category_selector.dart
- [ ] Create components/promo_code_section.dart
- [ ] Create components/payment_section.dart
- [ ] Create components/printer_section.dart

## Phase 3: Business Logic Separation
- [x] Create services/order_service.dart for order calculations
- [x] Create services/print_service.dart for printing logic
- [x] Create services/barcode_service.dart for barcode handling

## Phase 4: Refactor Main Page
- [x] Create components/product_grid.dart for product display
- [x] Create components/order_summary.dart for order display
- [x] Create components/category_selector.dart for category selection
- [x] Create components/promo_code_section.dart for promo code input
- [x] Create components/payment_section.dart for payment method toggle
- [x] Create components/printer_section.dart for printer controls
- [x] Remove unused code and variables from main_page.dart
- [x] Integrate Provider for state management
- [x] Add welcome message to order summary when no items selected
- [ ] Replace large build method with smaller components
- [ ] Add proper error handling and loading states

## Phase 5: Testing and Cleanup
- [ ] Test all functionalities (product selection, ordering, printing, barcode)
- [ ] Verify responsiveness on different screen sizes
- [ ] Ensure data reloading and lifecycle management work correctly
- [ ] Clean up imports and dependencies
