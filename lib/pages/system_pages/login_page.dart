import 'package:visionpos/utils/session_manager.dart';
import 'package:visionpos/utils/api_config.dart';
import 'package:visionpos/components/quick_api_switcher.dart';
import 'package:flutter/material.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? errorMessage;
  String _currentEnvironment = ApiConfig.instance.environment;

  @override
  void initState() {
    super.initState();
    _currentEnvironment = ApiConfig.instance.environment;
  }

  void _onEnvironmentChanged() {
    setState(() {
      _currentEnvironment = ApiConfig.instance.environment;
    });
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(ApiConfig.instance.buildUrl('Authentication'));
    final response = await http.post(
      url.replace(queryParameters: {
        'username': usernameController.text,
        'password': passwordController.text,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['flag'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('refreshToken', data['refreshToken']);

        final int userId = data['userId'] as int;
        await prefs.setInt('userId', userId);

        // Fetch the user first
        final user = await ApiHandler().fetchUserById(userId);

        // ✅ Persist org id BEFORE navigating
        await SessionManager.setOrganizationId(user.OrganizationId);

        // (Optional) keep a single source of truth; no need to set the same key twice.
        // If you want both, do it before navigate (but it's redundant):
        // await prefs.setInt('organizationId', user.OrganizationId);

        // ✅ Now navigate
        widget.onLoginSuccess();
      } else {
        setState(() => errorMessage = data['message'] ?? 'Login failed');
      }
    } else {
      setState(() => errorMessage = 'Server error: ${response.statusCode}');
    }
    final stored = await SessionManager.getOrganizationId();
    debugPrint('✅ orgId persisted = $stored'); // should be > 0
  }

  String _getEnvironmentDisplayName(String environment) {
    switch (environment) {
      case ApiConfig.LOCAL:
        return 'Local Development';
      case ApiConfig.PRODUCTION:
        return 'Production';
      case ApiConfig.STAGING:
        return 'Staging';
      case ApiConfig.CUSTOM:
        return 'Custom';
      default:
        return environment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkCharcoal = const Color(0xFF36454F);
    final copper = const Color(0xFFB87333);
    final brown = const Color(0xFF8B5C42);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'VisionPOS Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkCharcoal,
        elevation: 0,
        actions: [
          QuickApiSwitcher(onEnvironmentChanged: _onEnvironmentChanged),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: darkCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              // API Environment Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentEnvironment == ApiConfig.LOCAL
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  border: Border.all(
                    color: _currentEnvironment == ApiConfig.LOCAL
                        ? Colors.green
                        : Colors.blue,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _currentEnvironment == ApiConfig.LOCAL
                          ? Colors.green
                          : Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'API: ${_getEnvironmentDisplayName(_currentEnvironment)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentEnvironment == ApiConfig.LOCAL
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Username
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Username is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Password is required'
                              : null,
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: copper,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            // optionally handle “Forgot password?”
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: brown,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Apply the same input theme globally on this page
      // so focused borders turn copper:
      // (could also be set in your MaterialApp theme)
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: copper,
              ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: copper),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
