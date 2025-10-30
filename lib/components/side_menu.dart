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
  DrawerPage({super.key});

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
    return Container(
      color: Colors.blueGrey,
      child: Padding(
        padding: EdgeInsets.only(top: 35, left: 40, bottom: 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(
                        fit: BoxFit.cover,
                        width: screenWidth * 0.15,
                        height: screenHeight * 0.15,
                        image: AssetImage("lib/assets/profile photo.jpg")),
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.015,
                ),
                data.isNotEmpty
                    ? Text(
                        data[0].FullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.015,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : CircularProgressIndicator(color: Colors.white),
              ],
            ),
            Column(
              children: <Widget>[
                SideBar_Item(
                  icon: Icons.money,
                  text: translation(context).balanceSheet,
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CustomersPage()),
                    );
                  },
                ),
                SideBar_Item(
                  icon: Icons.construction,
                  text: translation(context).suppliers,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SupplierPage()),
                    );
                  },
                ),
              ],
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.logout_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      AppLocalizations.of(context)!.logout,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.017,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}

class SideBar_Item extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap; // Callback for tap event

  const SideBar_Item({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap, // Require the onTap function
  });

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap, // Handle tap event
      child: Row(
        children: [
          // Adjusting the icon size based on screen width
          Icon(
            icon,
            color: Colors.white,
            size: screenWidth * 0.025, // Adjust icon size to 8% of screen width
          ),
          SizedBox(
              width: screenWidth * 0.03), // Adjust space based on screen width

          // Adjusting text size based on screen width
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  screenWidth * 0.017, // Adjust font size to 5% of screen width
            ),
          ),
          SizedBox(
              height:
                  screenHeight * 0.095), // Adjust space based on screen height
        ],
      ),
    );
  }
}
