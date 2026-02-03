import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddProducts extends StatefulWidget {
  const AddProducts({super.key});

  @override
  State<AddProducts> createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final _formkey = GlobalKey<FormBuilderState>();
  ApiHandler apiHandler = ApiHandler();
  List<Category> categories = [];
  List<Category> filteredCategories = [];
  final TextEditingController _categorySearchController = TextEditingController();
  int? _orgId = 0;

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
      _fetchCategories();
    });
  }

  void _fetchCategories() async {
    final org = _orgId ?? await SessionManager.getOrganizationId() ?? 0;
    final fetchedCategories = await apiHandler.getCategoriesForOrg(org);
    setState(() {
      categories = fetchedCategories;
      filteredCategories = fetchedCategories;
    });
  }

  void _searchCategories(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        filteredCategories = categories;
      });
      return;
    }

    try {
      final searchResults = await apiHandler.searchCategories(query, orgId: _orgId);
      setState(() {
        filteredCategories = searchResults;
      });
    } catch (e) {
      setState(() {
        filteredCategories = categories
            .where((category) => category.categoryName
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void addProduct() async {
    if (_formkey.currentState!.saveAndValidate()) {
      final data = _formkey.currentState!.value;
      final catId = data['ProductCategory'] is int
          ? data['ProductCategory'] as int
          : int.tryParse(data['ProductCategory'].toString()) ?? 0;
      
      final product = Product(
        productId: 0,
        organizationId: _orgId ?? 0,
        categoryId: catId,
        productName: data['ProductName'],
        productDescription: data['ProductDescription'],
        sellingPrice: double.tryParse(data['sellingPrice'].toString()) ?? 0.0,
        purchasePrice: double.tryParse(data['BuyingPrice'].toString()) ?? 0.0,
      );

      try {
        final resp = await apiHandler.AddProducts(product: product);
        if (!mounted) return;
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: ${resp.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
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
        backgroundColor: const Color(0xFFCC5500),
        title: const Text('Add Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.greenAccent),
            onPressed: addProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formkey,
              child: Column(
                children: [
                  buildCategoryDropdown(),
                  buildTextField('ProductName', 'Product Name', Icons.label),
                  buildTextField('ProductDescription', 'Description', Icons.description),
                  buildTextField('BuyingPrice', 'Buying Price', Icons.money, isNumeric: true),
                  buildTextField('sellingPrice', 'Selling Price', Icons.sell, isNumeric: true),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _categorySearchController,
            decoration: InputDecoration(
              labelText: 'Search Categories',
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _categorySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
          FormBuilderDropdown<int>(
            name: 'ProductCategory',
            decoration: InputDecoration(
              labelText: 'Product Category',
              prefixIcon: const Icon(Icons.category, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: FormBuilderValidators.compose([FormBuilderValidators.required()]),
            items: filteredCategories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.categoryName),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String name, String label, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: FormBuilderTextField(
        name: name,
        keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: FormBuilderValidators.compose([FormBuilderValidators.required()]),
      ),
    );
  }
}
