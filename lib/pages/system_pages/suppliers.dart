import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/supplier_model.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';

class SupplierPage extends StatefulWidget {
  @override
  _SupplierPageState createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  late Future<List<Supplier>> futureSuppliers;
  final ApiHandler apiHandler = ApiHandler();

  @override
  void initState() {
    super.initState();
    futureSuppliers = apiHandler.getSupplierData();
  }

  void refreshData() {
    setState(() {
      futureSuppliers = apiHandler.getSupplierData();
    });
  }

  Future<void> showSupplierDialog({Supplier? supplier}) async {
    TextEditingController nameController =
        TextEditingController(text: supplier?.Name ?? '');
    TextEditingController emailController =
        TextEditingController(text: supplier?.Email ?? '');
    TextEditingController companynameController =
        TextEditingController(text: supplier?.CompanyName ?? '');
    TextEditingController addressController =
        TextEditingController(text: supplier?.Address ?? '');
    TextEditingController phoneController =
        TextEditingController(text: supplier?.Phone ?? '');
    final orgId = await SessionManager.getOrganizationId();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            supplier == null ? 'Add Supplier' : 'Edit Supplier',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF36454F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStyledField(
                    controller: nameController,
                    label: translation(context).supplierName),
                const SizedBox(height: 10),
                _buildStyledField(
                    controller: emailController,
                    label: translation(context).email),
                const SizedBox(height: 10),
                _buildStyledField(
                    controller: companynameController,
                    label: translation(context).company_name),
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
                Supplier newSupplier = Supplier(
                  SupplierId: supplier?.SupplierId ?? 0,
                  OrganizationId: orgId!.toInt(),
                  Name: nameController.text,
                  CompanyName: companynameController.text,
                  Email: emailController.text,
                  Phone: phoneController.text,
                  Address: addressController.text,
                );
                if (supplier == null) {
                  await apiHandler.addSuuplier(supplier: newSupplier);
                } else {
                  await apiHandler.updateSupplier(
                      id: supplier.SupplierId, supplier: newSupplier);
                }
                refreshData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB87333)),
              child: Text(
                supplier == null ? 'Add' : 'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSupplier(int supplierId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            translation(context).delete_supplier,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF36454F)),
          ),
          content: Text(
            translation(context).delete_supplier_confirm,
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context).cancel,
                  style: const TextStyle(color: Color(0xFF36454F))),
            ),
            TextButton(
              onPressed: () async {
                await apiHandler.deleteSupplier(supplierId: supplierId);
                Navigator.pop(context);
                refreshData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF36454F),
        foregroundColor: Colors.white,
        title: Text(translation(context).suppliers),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Supplier>>(
        future: futureSuppliers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
                child: CircularProgressIndicator(
              color: Color(0xFFB87333),
            ));
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No suppliers found'));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Supplier supplier = snapshot.data![index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(supplier.Name[0]),
                    backgroundColor: Colors.orange,
                  ),
                  title: Text(supplier.Name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${translation(context).company_name}: ${supplier.CompanyName}'),
                      Text('${translation(context).email}: ${supplier.Email}'),
                      Text(
                          '${translation(context).phone_number}: ${supplier.Phone}'),
                      Text(
                          '${translation(context).address}: ${supplier.Address}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showSupplierDialog(supplier: supplier),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSupplier(supplier.SupplierId),
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
        onPressed: () => showSupplierDialog(),
        backgroundColor: Color(0xFFB87333),
        child: Icon(
          Icons.add,
          color: Color(0xFF36454F),
        ),
      ),
    );
  }
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
