//import 'package:visionpos/L10n/L10n.dart';
import 'dart:io';

import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/essential_pages/MyHttpOverrides.dart';
import 'package:visionpos/pages/system_pages/login_page.dart';
import 'package:visionpos/utils/api_config.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import 'package:visionpos/providers/locale_provider.dart'; // Import the provider for managing locale
//import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:visionpos/components/side_menu.dart'; // Assuming side_menu.dart exists
import 'package:visionpos/pages/system_pages/main_page.dart';
import 'package:http/io_client.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assuming main_page.dart exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialize API configuration
  await ApiConfig.instance.initialize();

  // Auto-switch to local API for development
  await ApiConfig.instance.setEnvironment(ApiConfig.LOCAL);

  runApp(Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();

  static void setLocale(BuildContext context, Locale newLocale) {
    print("Setting new locale: $newLocale");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _MainState? state = context.findAncestorStateOfType<_MainState>();
      state?.setLocale(newLocale);
    });
  }
}

class _MainState extends State<Main> {
  Locale? _locale;
  bool _loggedIn = false;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => setLocale(locale));
    super.didChangeDependencies();
  }

  IOClient createInsecureHttpClient() {
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final expiry = Jwt.getExpiryDate(token);
      print('Token expires at: $expiry');
    }

    if (token != null && !Jwt.isExpired(token)) {
      _loggedIn = true;
    } else {
      await prefs.clear();
      _loggedIn = false;
    }
    setState(() {
      _loggedIn = token != null && token.isNotEmpty;
    });
  }

  void handleLoginSuccess() {
    setState(() {
      _loggedIn = true;
      print("Login success triggered");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 11,
              top: 0,
              bottom: 0,
              child: DrawerPage(), // Your drawer (side menu)
            ),
            MainPage(), // Main page remains the same
            if (!_loggedIn)
              Positioned.fill(
                child: LoginScreen(onLoginSuccess: handleLoginSuccess),
              ),
          ],
        ),
      ),
    );
  }
}
