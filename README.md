# VisionPOS

VisionPOS is a comprehensive Point of Sale (POS) system designed specifically for Vision CIT company. Built with Flutter, it provides a modern, cross-platform solution for retail management.

## Features

- **🛒 Sales Management**: Process transactions with ease
- **📦 Inventory Management**: Track products, categories, and stock levels
- **👥 Customer Management**: Maintain customer database and relationships
- **🏢 Supplier Management**: Manage supplier information and relationships
- **📊 Analytics & Reporting**: Generate sales reports and analytics
- **🌐 Multi-language Support**: Available in English, Arabic, German, and Spanish
- **🔧 Dynamic API Configuration**: Switch between development and production environments
- **🖨️ Thermal Printing**: Support for receipt printing via Bluetooth
- **💳 Multiple Payment Methods**: Cash, card, and other payment options
- **🎯 Promo Codes & Discounts**: Flexible promotion management
- **📱 Responsive Design**: Works on desktop, tablet, and mobile devices

## Technology Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider pattern
- **HTTP Client**: Native HTTP package
- **Local Storage**: SharedPreferences
- **Database**: RESTful API integration
- **Platforms**: Windows, Web, iOS, Android, macOS, Linux

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Visual Studio Code or Android Studio
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/AlphaCoreSolutions/POS-frontend.git
cd POS-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API endpoints (see API Configuration section)

4. Run the application:
```bash
flutter run -d windows  # For Windows
flutter run -d chrome   # For Web
```

## API Configuration

VisionPOS supports dynamic API configuration for different environments:

- **Local Development**: `https://localhost:5001/api`
- **Production**: `http://posapi.alphacorecit.com/api`
- **Staging**: `http://192.168.100.19/api`
- **Custom**: User-defined endpoints

Switch environments using:
1. Quick API Switcher (📡 icon in app bar)
2. Settings → API Configuration

## Building for Production

### Windows
```bash
flutter build windows --release
```

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── components/          # Reusable UI components
├── L10n/               # Localization files
├── language_changing/  # Language management
├── models/             # Data models
├── pages/              # Application screens
│   ├── add_pages/      # Create/Add functionality
│   ├── edit_pages/     # Edit functionality
│   ├── essential_pages/# Core pages (API handler, etc.)
│   └── system_pages/   # Main application pages
└── utils/              # Utility classes and helpers
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software owned by Vision CIT Company. All rights reserved.

## Support

For support and questions, please contact:
- Email: support@visioncit.com
- Website: https://visioncit.com

---

**© 2025 Vision CIT Company. All rights reserved.**
