import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/user_model.dart';
import 'package:visionpos/pages/edit_pages/edit_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ApiHandler apiHandler = ApiHandler();
  List<User> data = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    try {
      List<User> fetchedData = await apiHandler.getUserData();
      setState(() {
        data = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translation(context).profile,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF36454F),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: "Refresh Data",
            onPressed: getData,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: Color(0xFFB87333),
            )) // Show loading spinner
          : hasError || data.isEmpty
              ? Center(
                  child: Text(
                    translation(context).failed_profile_load,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF36454F),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    AssetImage("lib/assets/profile photo.jpg")),
                            SizedBox(height: 10),
                            Text(
                              data[0].FullName,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 5),
                            Text(
                              data[0].Role,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildProfileItem(Icons.person,
                          translation(context).username, data[0].UserName),
                      _buildProfileItem(Icons.person,
                          translation(context).email, data[0].Email),
                      _buildProfileItem(
                          Icons.phone_enabled,
                          translation(context).phone_number,
                          data[0].PhoneNumber),
                      _buildProfileItem(
                          Icons.person,
                          translation(context).employee_id,
                          data[0].id.toString()),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          onTap: () {
            if (title == 'Employee ID') {
              print("id pressed");
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditPage(user: data[0])));
            }
          },
          leading: Icon(icon, color: Colors.grey),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value, style: TextStyle(fontSize: 16)),
          trailing: Icon(Icons.edit),
        ),
      ),
    );
  }
}
