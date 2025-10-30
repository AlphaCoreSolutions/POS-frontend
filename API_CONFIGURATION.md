# API Configuration System

This Flutter POS application now supports dynamic API base URL configuration that can be changed at runtime without rebuilding the app.

## Features

### 🔧 Dynamic API Configuration
- Switch between different API environments on-the-fly
- No need to rebuild the app when changing API endpoints
- Persistent settings that survive app restarts

### 🌐 Predefined Environments
- **Local Development**: `https://localhost:5001/api`
- **Production**: `http://posapi.alphacorecit.com/api`
- **Staging**: `https://staging.alphacorecit.com/api`
- **Custom URL**: Set any custom API endpoint

## How to Use

### Method 1: Quick API Switcher (In App Bar)
1. Launch the app
2. Look for the 📡 (wifi_tethering) icon in the top app bar
3. Click on it to see a dropdown menu with environment options
4. Select your desired environment:
   - **Local** (localhost:5001) - for development
   - **Production** (posapi.alphacorecit.com) - for live environment
   - **Staging** (staging.alphacorecit.com) - for testing

### Method 2: Settings Page (Detailed Configuration)
1. Go to **Settings** from the side menu
2. Find the **"API Configuration"** section
3. Click on **"API Server Configuration"**
4. In the dialog:
   - Choose from predefined environments, OR
   - Select "Custom URL" and enter your own API endpoint
5. Click **"Save"** to apply changes

### Method 3: Programmatic Configuration
```dart
// Set to local development
await ApiConfig.instance.setEnvironment(ApiConfig.LOCAL);

// Set to production
await ApiConfig.instance.setEnvironment(ApiConfig.PRODUCTION);

// Set custom URL
await ApiConfig.instance.setCustomBaseUrl('https://my-api.example.com');

// Get current configuration
String currentUrl = ApiConfig.instance.baseUrl;
String currentEnv = ApiConfig.instance.environment;
```

## Environment Details

| Environment | Base URL | Use Case |
|-------------|----------|----------|
| Local | `https://localhost:5001/api` | Development & Testing |
| Production | `http://posapi.alphacorecit.com/api` | Live Application |
| Staging | `https://staging.alphacorecit.com/api` | Pre-production Testing |
| Custom | User-defined | Special configurations |

## Technical Details

### Files Added/Modified
- `lib/utils/api_config.dart` - Core configuration management
- `lib/components/api_settings_dialog.dart` - Settings UI dialog
- `lib/components/quick_api_switcher.dart` - Quick access widget
- `lib/pages/essential_pages/api_handler.dart` - Updated to use dynamic URLs
- `lib/pages/system_pages/Settings.dart` - Added API configuration section
- `lib/pages/system_pages/main_page.dart` - Added quick switcher to app bar
- `lib/main.dart` - Initialize API configuration on app start

### Key Features
- **Persistent Storage**: Settings are saved using SharedPreferences
- **SSL Support**: Handles HTTPS for local development
- **Automatic URL Formatting**: Adds `/api` suffix automatically if missing
- **Error Handling**: Graceful handling of configuration errors
- **UI Feedback**: Visual confirmation when switching environments

## For Developers

### Setting Up Local Development
1. Ensure your local API server is running on `https://localhost:5001`
2. Use the Quick API Switcher to select "Local"
3. The app will now make all API calls to your local development server

### Adding New Environments
To add a new predefined environment:

1. Edit `lib/utils/api_config.dart`
2. Add a new constant and URL:
```dart
static const String NEW_ENV = 'new_env';
static const String _newEnvBaseUrl = "https://new-env.example.com/api";
```
3. Update the switch statement in `setEnvironment()` method
4. Add to `predefinedUrls` map

### Default Behavior
- App starts with **Production** environment by default
- First-time users will use the production API
- Environment preference is remembered between app sessions

## Troubleshooting

### Common Issues
1. **SSL Certificate Errors**: The app includes `MyHttpOverrides` to handle self-signed certificates for local development
2. **Network Connectivity**: Ensure the target API server is accessible from your device
3. **CORS Issues**: Make sure your API server allows requests from your app domain

### Debugging
- Check the current environment in Settings → API Configuration
- Look for API-related console output in debug mode
- Verify the correct base URL is being used by checking `ApiConfig.instance.baseUrl`

## Security Notes
- Custom URLs are stored locally and persist across app sessions
- Always use HTTPS for production environments
- Local development mode accepts self-signed certificates for convenience