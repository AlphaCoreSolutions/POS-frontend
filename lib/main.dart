import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/essential_pages/MyHttpOverrides.dart';
import 'package:visionpos/pages/system_pages/login_page.dart';
import 'package:visionpos/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionpos/providers/pos_provider.dart' as pos_provider;
import 'package:visionpos/components/side_menu.dart';
import 'package:visionpos/pages/system_pages/main_page.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import dart:io only for non-web platforms to avoid compilation errors
import 'dart:io' as io;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // HttpOverrides is only available on IO platforms
    io.HttpOverrides.global = MyHttpOverrides();
  }

  // Initialize API configuration
  await ApiConfig.instance.initialize();

  // Auto-switch to local API for development
  await ApiConfig.instance.setEnvironment(ApiConfig.LOCAL);
  
  try {
    await rootBundle.load('lib/assets/fonts/NotoNaskhArabic-Regular.ttf');
  } catch (e) {
    debugPrint('Font load error: $e');
  }
  
  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();

  static void setLocale(BuildContext context, Locale newLocale) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _MainState? state = context.findAncestorStateOfType<_MainState>();
      state?.setLocale(newLocale);
    });
  }
}

class _MainState extends State<Main> {
  Locale? _locale;
  bool _loggedIn = false;
  bool _isSidebarCollapsed = false;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _toggleSidebarCollapse() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => setLocale(locale));
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token != null && token.isNotEmpty) {
      try {
        if (!Jwt.isExpired(token)) {
          setState(() => _loggedIn = true);
          return;
        }
      } catch (e) {
        debugPrint('Token check error: $e');
      }
    }
    
    await prefs.clear();
    setState(() => _loggedIn = false);
  }

  void handleLoginSuccess() {
    setState(() {
      _loggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // Responsive sidebar width based on collapsed state
        double sidebarWidth;
        if (isMobile) {
          sidebarWidth = 0;
        } else if (_isSidebarCollapsed) {
          sidebarWidth = 70; // Collapsed width - icons only
        } else if (isTablet) {
          sidebarWidth = 220;
        } else {
          sidebarWidth = 280;
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => pos_provider.PosProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _locale,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB87333)),
            ),
            home: Scaffold(
              body: Stack(
                children: [
                  if (!isMobile)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: sidebarWidth,
                        child: DrawerPage(
                          isCollapsed: _isSidebarCollapsed,
                          onToggleCollapse: _toggleSidebarCollapse,
                        ),
                      ),
                    ),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.only(left: sidebarWidth),
                    child: MainPage(
                      sidebarCollapsed: _isSidebarCollapsed,
                    ),
                  ),
                  if (!_loggedIn)
                    Positioned.fill(
                      child: LoginScreen(onLoginSuccess: handleLoginSuccess),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
