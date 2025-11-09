# TODO: Implement One-Shot Print with Server Order Number

## Information Gathered
- Legacy print calls found in main_page.dart: _printReceipt, _printReceipts, _printExampleReceipt, printArabicSmokeTest
- ReceiptBuilder _extractOrderNumber needs to prioritize server data
- TriplePrinter is already implemented but needs to be used with server data after POST
- Main page has submitOrder function that posts to API and then prints

## Plan
- [ ] Remove legacy print calls project-wide (keep only TriplePrinter)
- [ ] Add one-shot print guard in main screen (_isPrinting flag and _printOnce method)
- [ ] Update submitOrder to pass server response data to _printOnce after successful POST
- [ ] Update ReceiptBuilder _extractOrderNumber to prioritize server orderNumber
- [ ] Ensure TriplePrinter instantiation and usage with server data

## Dependent Files
- lib/pages/system_pages/main_page.dart
- lib/services/receipt_builder.dart
- lib/services/triple_printer.dart (minor updates if needed)

## Followup Steps
- Test printing after order submission
- Verify order number comes from server
- Ensure no duplicate prints
