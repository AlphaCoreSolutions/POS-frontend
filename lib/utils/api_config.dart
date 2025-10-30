import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Default base URLs for different environments
  static const String _localBaseUrl = "https://localhost:5001/api";
  static const String _productionBaseUrl = "http://posapi.alphacorecit.com/api";
  static const String _stagingBaseUrl = "https://staging.alphacorecit.com/api";

  // Preference key for storing selected base URL
  static const String _baseUrlKey = 'api_base_url';

  // Environment types
  static const String LOCAL = 'local';
  static const String PRODUCTION = 'production';
  static const String STAGING = 'staging';
  static const String CUSTOM = 'custom';

  // Private constructor
  ApiConfig._();
  static final ApiConfig _instance = ApiConfig._();
  static ApiConfig get instance => _instance;

  String _currentBaseUrl = _productionBaseUrl;
  String _currentEnvironment = PRODUCTION;

  /// Initialize the config - call this when app starts
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);

    if (savedUrl != null) {
      _currentBaseUrl = savedUrl;
      _currentEnvironment = _getEnvironmentFromUrl(savedUrl);
    }
  }

  /// Get current base URL
  String get baseUrl => _currentBaseUrl;

  /// Get current environment
  String get environment => _currentEnvironment;

  /// Set base URL by environment
  Future<void> setEnvironment(String environment) async {
    String newBaseUrl;

    switch (environment) {
      case LOCAL:
        newBaseUrl = _localBaseUrl;
        break;
      case PRODUCTION:
        newBaseUrl = _productionBaseUrl;
        break;
      case STAGING:
        newBaseUrl = _stagingBaseUrl;
        break;
      default:
        throw ArgumentError('Invalid environment: $environment');
    }

    await _saveBaseUrl(newBaseUrl);
    _currentBaseUrl = newBaseUrl;
    _currentEnvironment = environment;
  }

  /// Set custom base URL
  Future<void> setCustomBaseUrl(String customUrl) async {
    // Ensure URL ends with /api
    String formattedUrl = customUrl.endsWith('/api')
        ? customUrl
        : customUrl.endsWith('/')
        ? '${customUrl}api'
        : '$customUrl/api';

    await _saveBaseUrl(formattedUrl);
    _currentBaseUrl = formattedUrl;
    _currentEnvironment = CUSTOM;
  }

  /// Get available environments
  static List<String> get availableEnvironments => [
    LOCAL,
    PRODUCTION,
    STAGING,
    CUSTOM,
  ];

  /// Get predefined URLs map
  static Map<String, String> get predefinedUrls => {
    LOCAL: _localBaseUrl,
    PRODUCTION: _productionBaseUrl,
    STAGING: _stagingBaseUrl,
  };

  /// Build full endpoint URL
  String buildUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    return '$_currentBaseUrl/$endpoint';
  }

  /// Save base URL to preferences
  Future<void> _saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  /// Determine environment from URL
  String _getEnvironmentFromUrl(String url) {
    if (url == _localBaseUrl) return LOCAL;
    if (url == _productionBaseUrl) return PRODUCTION;
    if (url == _stagingBaseUrl) return STAGING;
    return CUSTOM;
  }

  /// Reset to default (production)
  Future<void> resetToDefault() async {
    await setEnvironment(PRODUCTION);
  }
}
