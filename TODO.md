# TODO: Make Non-Responsive Pages Responsive

## Steps to Complete

- [x] Update login_page.dart: Wrap main content in LayoutBuilder, make card width responsive (maxWidth based on screen width, e.g., <600: 90% width, else fixed 400), adjust padding dynamically.
- [x] Update orderDetails_page.dart: Use LayoutBuilder for padding and card margins, adjust font sizes with MediaQuery.
- [x] Update customers.dart: Implement adaptive list/grid layout using LayoutBuilder (list on mobile, grid on larger screens), adjust card sizes.
- [x] Update profile_page.dart: Wrap in LayoutBuilder, adjust padding and avatar size based on screen width, use MediaQuery for font sizes.
- [x] Update suppliers.dart: Similar to customers.dart, adaptive list/grid layout.
- [x] Update support_page.dart: Use LayoutBuilder for padding and expansion tile sizes, adjust text sizes with MediaQuery.
- [x] Test changes: Run Flutter app in web mode and verify responsiveness on different screen sizes using browser tools.

## Notes
- Use breakpoints: <600 mobile, 600-1200 tablet, >1200 desktop.
- Ensure no hardcoded values; use proportional sizing.
- After edits, run `flutter run --web` and use browser to resize window to test.
