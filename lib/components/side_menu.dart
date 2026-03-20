import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/main.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/user_model.dart';
import 'package:visionpos/pages/system_pages/Settings.dart';
import 'package:visionpos/pages/system_pages/customers.dart';
import 'package:visionpos/pages/system_pages/enhanced_dashboard.dart';
import 'package:visionpos/pages/system_pages/reports_page.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/system_pages/products_page.dart';
import 'package:visionpos/pages/system_pages/profile_page.dart';
import 'package:visionpos/pages/system_pages/suppliers.dart';
import 'package:visionpos/pages/system_pages/support_page.dart';
//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerPage extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DrawerPage({
    super.key,
    this.isCollapsed = false,
    VoidCallback? onToggleCollapse,
  }) : onToggleCollapse = onToggleCollapse ?? _defaultCallback;

  static void _defaultCallback() {
    // Default empty callback
  }

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final ApiHandler apiHandler = ApiHandler();
  List<User> data = [];

  void getUsername() async {
    // Simulate an API call
    final user = await apiHandler.getUserData();
    if (mounted) {
      setState(() {
        data = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUsername(); // Fetch user data
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Responsive sizing based on screen width
    double sidebarWidth;
    if (isMobile) {
      sidebarWidth = screenWidth * 0.75;
    } else if (isTablet) {
      sidebarWidth = 220;
    } else {
      sidebarWidth = 280;
    }
    
    double topPadding = isTablet ? 12 : 16;
    double leftPadding = isTablet ? 12 : 16;

    return Container(
      width: sidebarWidth,
      color: const Color(0xFF36454F),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, left: leftPadding, right: leftPadding, bottom: 16),
        child: Column(
          children: <Widget>[
            // Collapse/Expand button
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: Icon(
                    widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: widget.onToggleCollapse,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            // User profile section with better styling
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.isCollapsed
                  ? // Collapsed view - centered icon only
                  CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: data.isNotEmpty
                            ? Image(
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                image: AssetImage("lib/assets/profile photo.jpg"),
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    )
                  : // Expanded view - icon + name
                  Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: screenWidth < 600 ? 20 : 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(screenWidth < 600 ? 20 : 30),
                            child: data.isNotEmpty
                                ? Image(
                                    fit: BoxFit.cover,
                                    width: screenWidth < 600 ? 40 : screenWidth * 0.15,
                                    height: screenWidth < 600 ? 40 : screenHeight * 0.15,
                                    image: AssetImage("lib/assets/profile photo.jpg"),
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: screenWidth < 600 ? 20 : 30,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: screenWidth < 600 ? 20 : 30,
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth < 600 ? 12 : screenWidth * 0.02,
                        ),
                        Flexible(
                          child: data.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data[0].fullName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            screenWidth < 600 ? 12 : screenWidth * 0.015,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Expanded(
              child: ListView(
                children: <Widget>[
                  SideBar_Item(
                    icon: Icons.money,
                    text: translation(context).balanceSheet,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EnhancedDashboard()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.assessment,
                    text: 'Reports',
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReportsPage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.person_outline,
                    text: AppLocalizations.of(context)!.profile,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.file_present,
                    text: AppLocalizations.of(context)!.products,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductsPage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.support_agent,
                    text: AppLocalizations.of(context)!.support,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SupportPage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.error_outline,
                    text: AppLocalizations.of(context)!.settings,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.person,
                    text: translation(context).customers,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomersPage()),
                      );
                    },
                  ),
                  SideBar_Item(
                    icon: Icons.construction,
                    text: translation(context).suppliers,
                    isCollapsed: widget.isCollapsed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SupplierPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // ✅ Safely restart the app from Main
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Main()),
                  (_) => false,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  border: Border.all(color: Colors.redAccent, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.isCollapsed
                    ? Tooltip(
                        message: AppLocalizations.of(context)!.logout,
                        child: Icon(
                          Icons.logout_outlined,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      )
                    : Row(
                        children: <Widget>[
                          Icon(
                            Icons.logout_outlined,
                            color: Colors.redAccent,
                            size: screenWidth < 600 ? 18 : 24,
                          ),
                          SizedBox(width: screenWidth < 600 ? 12 : screenWidth * 0.03),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!.logout,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    screenWidth < 600 ? 12 : screenWidth * 0.017,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SideBar_Item extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isCollapsed;

  const SideBar_Item({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  State<SideBar_Item> createState() => _SideBar_ItemState();
}

class _SideBar_ItemState extends State<SideBar_Item> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double iconSize = screenWidth < 600 ? 18 : screenWidth * 0.025;
    double fontSize = screenWidth < 600 ? 12 : screenWidth * 0.017;
    double spacing = screenWidth < 600 ? 12 : screenWidth * 0.03;
    double verticalPadding = screenHeight < 600 ? 12 : 16;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: spacing,
            vertical: verticalPadding * 0.5,
          ),
          decoration: BoxDecoration(
            color: _isHovered 
                ? Colors.white.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.isCollapsed
              ? // Collapsed view - centered icon only
              Tooltip(
                  message: widget.text,
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                )
              : // Expanded view - icon + text
              Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    SizedBox(width: spacing),
                    Flexible(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
