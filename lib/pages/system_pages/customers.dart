import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/customer_model.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  _CustomersPageState createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final ApiHandler apiHandler = ApiHandler();
  late Future<List<Customer>> customersFuture;

  @override
  void initState() {
    super.initState();
    customersFuture = apiHandler.getCustomerData();
  }

  void _refreshData() {
    setState(() {
      customersFuture = apiHandler.getCustomerData();
    });
  }

  Future<void> _showCustomerDialog({Customer? customer}) async {
    final TextEditingController nameController =
        TextEditingController(text: customer?.name ?? '');
    final TextEditingController emailController =
        TextEditingController(text: customer?.email ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: customer?.phone ?? '');
    final TextEditingController addressController =
        TextEditingController(text: customer?.address ?? '');
    final orgId = await SessionManager.getOrganizationId();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            customer == null ? 'Add Customer' : 'Edit Customer',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF36454F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStyledField(
                    controller: nameController,
                    label: translation(context).customerName),
                const SizedBox(height: 10),
                _buildStyledField(
                    controller: emailController,
                    label: translation(context).customerEmail),
                const SizedBox(height: 10),
                _buildStyledField(
                    controller: phoneController,
                    label: translation(context).phone_number),
                const SizedBox(height: 10),
                _buildStyledField(
                    controller: addressController,
                    label: translation(context).address),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context).cancel,
                  style: const TextStyle(color: Color(0xFF36454F))),
            ),
            ElevatedButton(
              onPressed: () async {
                Customer newCustomer = Customer(
                  customerId: customer?.customerId ?? 0,
                  organizationId: orgId!.toInt(),
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );

                if (customer == null) {
                  await apiHandler.addCustomer(customer: newCustomer);
                } else {
                  await apiHandler.updateCustomer(
                      id: customer.customerId, customer: newCustomer);
                }

                Navigator.pop(context);
                _refreshData();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB87333)),
              child: Text(
                customer == null ? 'Add' : 'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomer(int customerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            translation(context).deleteCustomer,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF36454F)),
          ),
          content: const Text(
            'Are you sure you want to delete this customer?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context).cancel,
                  style: const TextStyle(color: Color(0xFF36454F))),
            ),
            TextButton(
              onPressed: () async {
                await apiHandler.deleteCustomers(customerId: customerId);
                Navigator.pop(context);
                _refreshData();
              },
              child: Text(translation(context).delete,
                  style: const TextStyle(
                      color: Color(0xFFB87333), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStyledField(
      {required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF36454F)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB87333)),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).customers),
        backgroundColor: Color(0xFF36454F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
          final horizontalMargin = isMobile
              ? 16.0
              : isTablet
                  ? 24.0
                  : 32.0;
          final verticalMargin = isMobile ? 8.0 : 12.0;
          final avatarRadius = isMobile ? 20.0 : 24.0;
          final titleFontSize = isMobile ? 16.0 : 18.0;
          final subtitleFontSize = isMobile ? 14.0 : 16.0;
          final iconSize = isMobile ? 20.0 : 24.0;

          return FutureBuilder<List<Customer>>(
            future: customersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: Color(0xFFB87333),
                ));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading customers'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No customers found'));
              }

              List<Customer> customers = snapshot.data!;

              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(
                        vertical: verticalMargin, horizontal: horizontalMargin),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.orange,
                        child: Text(customer.name[0],
                            style: TextStyle(fontSize: titleFontSize)),
                      ),
                      title: Text(customer.name,
                          style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${translation(context).customerEmail}: ${customer.email ?? ''}',
                              style: TextStyle(fontSize: subtitleFontSize)),
                          Text(
                              '${translation(context).customerPhone}: ${customer.phone}',
                              style: TextStyle(fontSize: subtitleFontSize)),
                          Text(
                              '${translation(context).customerAddress}: ${customer.address ?? ''}',
                              style: TextStyle(fontSize: subtitleFontSize)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: Colors.blue, size: iconSize),
                            onPressed: () =>
                                _showCustomerDialog(customer: customer),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.red, size: iconSize),
                            onPressed: () =>
                                _deleteCustomer(customer.customerId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerDialog(),
        backgroundColor: Color(0xFFB87333),
        child: Icon(
          Icons.add,
          color: Color(0xFF36454F),
        ),
      ),
    );
  }
}
