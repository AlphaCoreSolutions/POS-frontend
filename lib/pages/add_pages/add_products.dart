//import 'dart:io';

import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/category_model.dart'; // Ensure you have this model
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
//import 'package:image_picker/image_picker.dart';

class AddProducts extends StatefulWidget {
  const AddProducts({super.key});

  @override
  State<AddProducts> createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final _formkey = GlobalKey<FormBuilderState>();
  ApiHandler apiHandler = ApiHandler();
  List<Category> categories = []; // Store categories fetched from the API
  List<Category> filteredCategories =
      []; // Store filtered categories for search
  final TextEditingController _categorySearchController =
      TextEditingController();
  int? _orgId = 0;
  Category? _selectedCategory;
  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() {
      _orgId = orgId;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadOrganizationId().then((_) {
      _fetchCategories(); // Fetch categories after organization ID is loaded
    });
  }

  // Fetch categories from the API
  void _fetchCategories() async {
    if (_orgId != null && _orgId! > 0) {
      final fetchedCategories =
          await apiHandler.getLeafCategoriesByOrg(_orgId!);
      setState(() {
        categories = fetchedCategories;
        filteredCategories = fetchedCategories;
      });
    } else {
      // Fallback to getting all categories if no org ID
      final fetchedCategories = await apiHandler.getCategoryData();
      setState(() {
        categories = fetchedCategories;
        filteredCategories = fetchedCategories;
      });
    }
  }

  // Search categories using the AdvanceSearch API
  void _searchCategories(String query) async {
    if (query.trim().isEmpty) {
      // If search is empty, get all categories for the organization
      if (_orgId != null && _orgId! > 0) {
        try {
          final searchResults =
              await apiHandler.searchCategories('1 = 1', orgId: _orgId);
          setState(() {
            filteredCategories = searchResults;
          });
        } catch (e) {
          // Fallback to organization-specific categories
          final orgCategories =
              await apiHandler.getLeafCategoriesByOrg(_orgId!);
          setState(() {
            filteredCategories = orgCategories;
          });
        }
      } else {
        setState(() {
          filteredCategories = categories;
        });
      }
      return;
    }

    try {
      final searchResults =
          await apiHandler.searchCategories(query, orgId: _orgId);
      setState(() {
        filteredCategories = searchResults;
      });
    } catch (e) {
      // If search fails, filter locally
      setState(() {
        filteredCategories = categories
            .where((category) => category.categoryName
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void AddProduct() async {
    if (_formkey.currentState!.saveAndValidate()) {
      final data = _formkey.currentState!.value;
      final catId = data['ProductCategory'] is int
          ? data['ProductCategory'] as int
          : int.tryParse(data['ProductCategory'].toString()) ?? 0;
      final product = Product(
        id: 0,
        OrganizationId: _orgId!.toInt(),
        ProductCategory: catId,
        ProductName: data['ProductName'],
        ProductDescription: data['ProductDescription'],
        SellingPrice: double.tryParse(data['sellingPrice'].toString()) ?? 0.0,
        PurchasePrice: double.tryParse(data['purchasePrice'].toString()) ?? 0.0,
        ProductInventory:
            double.tryParse(data['ProductInventory'].toString()) ?? 0.0,
        Barcode: data['Barcode'],
      );

      try {
        await apiHandler.AddProducts(product: product);
        if (!mounted) return;
        // Return success result to indicate product was added
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        // Show error message but don't return a result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFCC5500),
        title: Text('Add Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.greenAccent),
            onPressed: AddProduct,
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
              child: Column(
                children: [
                  //buildImagePicker('ProductPicture'),
                  buildCategoryDropdown(), // Use a dropdown for categories
                  buildTextField('Barcode', 'Barcode', Icons.barcode_reader),
                  buildTextField('ProductName', 'Product Name', Icons.label),
                  buildTextField(
                      'ProductDescription', 'Description', Icons.description),
                  buildTextField('BuyingPrice', 'Buying Price', Icons.money,
                      isNumeric: true),
                  buildTextField('sellingPrice', 'Selling Price', Icons.sell,
                      isNumeric: true),
                  buildTextField(
                      'ProductInventory', 'Inventory', Icons.inventory_2),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build a searchable dropdown for categories
  Widget buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field for categories
          TextField(
            controller: _categorySearchController,
            decoration: InputDecoration(
              labelText: 'Search Categories',
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _categorySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _categorySearchController.clear();
                        _searchCategories('');
                      },
                    )
                  : null,
            ),
            onChanged: _searchCategories,
          ),
          const SizedBox(height: 10),
          // Category dropdown
          FormBuilderDropdown(
            name: 'ProductCategory',
            decoration: InputDecoration(
              labelText: 'Product Category',
              prefixIcon: Icon(Icons.category, color: Colors.black54),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: FormBuilderValidators.compose(
                [FormBuilderValidators.required()]),
            items: filteredCategories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.categoryName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = filteredCategories.firstWhere(
                  (category) => category.id == value,
                  orElse: () => filteredCategories.first,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // Build a text field
  Widget buildTextField(String name, String label, IconData icon,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: FormBuilderTextField(
        name: name,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator:
            FormBuilderValidators.compose([FormBuilderValidators.required()]),
      ),
    );
  }
/*
  Widget buildImagePicker(String name) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: FormBuilderField<String>(
      name: name,
      validator: FormBuilderValidators.required(errorText: 'Please select an image'),
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  field.didChange(pickedFile.path); // Store image path
                }
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: field.value == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.black54),
                            SizedBox(height: 5),
                            Text("Select an Image", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      )
                    : Image.file(File(field.value!.replaceAll('\\', '/')), fit: BoxFit.cover),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  field.errorText!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    ),
  );
}
*/
}
