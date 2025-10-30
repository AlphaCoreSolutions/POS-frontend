import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/customer_model.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
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
        TextEditingController(text: customer?.Name ?? '');
    final TextEditingController emailController =
        TextEditingController(text: customer?.Email ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: customer?.Phone ?? '');
    final TextEditingController addressController =
        TextEditingController(text: customer?.Address ?? '');
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
                  CustomerId: customer?.CustomerId ?? 0,
                  OrganizationId: orgId!.toInt(),
                  Name: nameController.text,
                  Email: emailController.text,
                  Phone: phoneController.text,
                  Address: addressController.text,
                );

                if (customer == null) {
                  await apiHandler.addCustomer(customer: newCustomer);
                } else {
                  await apiHandler.updateCustomer(
                      id: customer.CustomerId, customer: newCustomer);
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
      body: FutureBuilder<List<Customer>>(
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
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.Name[0]),
                    backgroundColor: Colors.orange,
                  ),
                  title: Text(customer.Name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${translation(context).customerEmail}: ${customer.Email}'),
                      Text(
                          '${translation(context).customerPhone}: ${customer.Phone}'),
                      Text(
                          '${translation(context).customerAddress}: ${customer.Address}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showCustomerDialog(customer: customer),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCustomer(customer.CustomerId),
                      ),
                    ],
                  ),
                ),
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
