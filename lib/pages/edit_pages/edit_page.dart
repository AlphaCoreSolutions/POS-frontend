import 'package:fixed_pos/language_changing/constants.dart';
import 'package:fixed_pos/pages/essential_pages/api_handler.dart';
import 'package:fixed_pos/models/user_model.dart';
import 'package:fixed_pos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;

class EditPage extends StatefulWidget {
  final User user;
  const EditPage({super.key, required this.user});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _formkey = GlobalKey<FormBuilderState>();
  ApiHandler apiHandler = ApiHandler();
  late http.Response response;
  // ignore: unused_field
  int? _orgId = 0;

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() {
      _orgId = orgId;
    });
  }

  @override
  void initState() {
    _loadOrganizationId();
    super.initState();
  }

  void updateData() async {
    if (_formkey.currentState!.saveAndValidate()) {
      final data = _formkey.currentState!.value;
      final user = User(
          id: widget.user.id,
          OrganizationId: _orgId!.toInt(),
          FullName: data['fullname'],
          UserName: data['UserName'],
          Email: data['email'],
          Password: data['Password'],
          PhoneNumber: data['phone'],
          Role: data['Role']);

      response = await apiHandler.updateUser(id: widget.user.id, user: user);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).edit),
        centerTitle: true,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: updateData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formkey,
              initialValue: {
                'fullname': widget.user.FullName,
                'UserName': widget.user.UserName,
                'Password': widget.user.Password,
                'email': widget.user.Email,
                'phone': widget.user.PhoneNumber,
                'Role': widget.user.Role,
              },
              child: Column(
                children: [
                  buildTextField('fullname', 'Full Name', Icons.person),
                  buildTextField('UserName', 'Username', Icons.account_circle),
                  buildTextField('Password', 'Password', Icons.lock,
                      obscureText: true),
                  buildTextField('email', 'Email', Icons.email),
                  buildTextField('phone', 'Phone Number', Icons.phone),
                  buildTextField('Role', 'Role', Icons.admin_panel_settings),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String name, String label, IconData icon,
      {bool obscureText = false}) {
    bool isPassword = name.toLowerCase() == 'password';
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: FormBuilderTextField(
            name: name,
            obscureText: isPassword ? obscureText : false,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.black54),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: FormBuilderValidators.compose(
                [FormBuilderValidators.required()]),
          ),
        );
      },
    );
  }
}
