import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;

class UpdateProduct extends StatefulWidget {
  final Product product;
  const UpdateProduct({super.key, required this.product});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _api = ApiHandler();

  int? _orgId;
  bool _loadingCats = true;
  List<Category> _categories = [];
  late http.Response response;

  @override
  void initState() {
    super.initState();
    _loadOrgAndCategories();
  }

  Future<void> _loadOrgAndCategories() async {
    try {
      final orgId = await SessionManager.getOrganizationId();
      final all = await _api.getCategoryData();
      setState(() {
        _orgId = orgId;
        _categories = (orgId ?? 0) > 0
            ? all.where((c) => c.organizationId == orgId).toList()
            : all;
        _loadingCats = false;
      });
    } catch (_) {
      setState(() {
        _categories = [];
        _loadingCats = false;
      });
    }
  }

  void _updateData() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final data = _formKey.currentState!.value;
    final catId = data['ProductCategory'] as int? ?? 0;

    final product = Product(
      id: widget.product.id,
      OrganizationId: (_orgId ?? 0),
      ProductCategory: catId,
      ProductName: data['ProductName'],
      ProductDescription: data['ProductDescription'],
      // match keys you set in initialValue:
      SellingPrice: double.tryParse(data['SellingPrice'].toString()) ?? 0.0,
      PurchasePrice: double.tryParse(data['purchasePrice'].toString()) ?? 0.0,
      ProductInventory:
          double.tryParse(data['ProductInventory'].toString()) ?? 0.0,
      Barcode: data['Barcode'],
    );

    response =
        await _api.updateProduct(id: widget.product.id, product: product);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catExists =
        _categories.any((c) => c.id == widget.product.ProductCategory);
    final initialCatId = catExists ? widget.product.ProductCategory : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        centerTitle: true,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.greenAccent),
            onPressed: _updateData,
          ),
        ],
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: {
                      // don't put category here; we set its initialValue on the field itself
                      'ProductName': widget.product.ProductName,
                      'ProductDescription': widget.product.ProductDescription,
                      'purchasePrice': widget.product.PurchasePrice.toString(),
                      'SellingPrice': widget.product.SellingPrice.toString(),
                      'ProductInventory':
                          widget.product.ProductInventory.toString(),
                      'Barcode': widget.product.Barcode,
                    },
                    child: Column(
                      children: [
                        // CATEGORY DROPDOWN (shows names, returns int id)
                        FormBuilderDropdown<int>(
                          name: 'ProductCategory',
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.required(),
                          initialValue: initialCatId,
                          items: [
                            ..._categories.map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.categoryName),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 14),

                        _text('ProductName', 'Product Name', Icons.label),
                        _text('ProductDescription', 'Description',
                            Icons.description),
                        _text('purchasePrice', 'Purchase Price', Icons.money,
                            numeric: true),
                        _text('SellingPrice', 'Selling Price', Icons.sell,
                            numeric: true),
                        _text(
                            'ProductInventory', 'Inventory', Icons.inventory_2,
                            numeric: true),
                        _text('Barcode', 'Barcode', Icons.qr_code),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _text(String name, String label, IconData icon,
      {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FormBuilderTextField(
        name: name,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: FormBuilderValidators.required(),
      ),
    );
  }
}
