import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/pages/add_pages/add_category.dart';
import 'package:visionpos/pages/add_pages/add_products.dart';
import 'package:visionpos/pages/edit_pages/edit_product_page.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late List<Product> data = [];
  late List<Category> categories = [];
  var user;
  ApiHandler apiHandler = ApiHandler();
  // ignore: unused_field
  int? _orgId = 1;

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() {
      _orgId = orgId;
    });
  }

  Map<int, String>? _catCache; // id -> name

  int _coerceId(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? -1;

  Future<String> _categoryNameFor(dynamic catId) async {
    // Build cache once
    if (_catCache == null) {
      final cats = await apiHandler.getCategoryData();
      _catCache = {for (final c in cats) c.id: c.categoryName};
    }
    return _catCache![_coerceId(catId)] ?? 'Uncategorized';
  }

  @override
  void initState() {
    _loadOrganizationId();
    super.initState();
    CategoryData();
    getData();
  }

  void CategoryData() async {
    categories = await apiHandler.getCategoryData();
    setState(() {
      if (data.isEmpty) {
        print("Cateory data not her");
      }
    });
  }

  void getData() async {
    data = await apiHandler.getProductData();
    setState(() {
      if (data.isEmpty) {
        print("data not her");
      }
    });
  }

  /*
  late List categoryIcons = [
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
  ];
  */
  void deleteCategory(int categoryID) async {
    await apiHandler.deleteCategory(categoryID: categoryID);
    setState(() {});
  }

  void deleteProduct(int productID) async {
    await apiHandler.deleteProducts(productID: productID);
    setState(() {});
  }

  void getUserInfo() async {
    user = await apiHandler.getUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).products),
        backgroundColor: Color(0xFF36454F),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 45.0, right: 50.0, bottom: 8.0, top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(translation(context).categories,
                          style: TextStyle(
                              fontSize: screenWidth * 0.02,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(197, 0, 0, 0))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: () {
                                CategoryData();
                                getData();
                              }),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddCategory(initialOrgId: _orgId),
                                    ));
                              },
                              icon: Icon(Icons.add))
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 150,
                  child: categories.isEmpty
                      ? Center(
                          child: Text(
                              translation(context).no_available_categories))
                      : Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {},
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 10),
                                  width: screenWidth * 0.2,
                                  height: screenHeight * 0.035,
                                  child: Padding(
                                    padding: EdgeInsets.zero,
                                    child: Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.01),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          /*
                                      Icon(
                                        categoryIcons[index],
                                        size: screenHeight * 0.065,
                                        color: Color(0xFFE2725B),
                                      ),
                                      */
                                          SizedBox(
                                            height: screenHeight * 0.015,
                                          ),
                                          Text(
                                            categories[index].categoryName,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.015,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Color.fromARGB(166, 0, 0, 0),
                                            ),
                                          ),
                                          SizedBox(
                                            height: screenHeight * 0.001,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        translation(context)
                                                            .confirm_deletion),
                                                    content: Text(translation(
                                                            context)
                                                        .delete_product_confirm),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog
                                                        },
                                                        child: Text(
                                                          translation(context)
                                                              .cancel,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          deleteCategory(
                                                              categories[index]
                                                                  .id); // Call delete function
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog after deletion
                                                        },
                                                        child: Text(
                                                            translation(context)
                                                                .delete,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: Icon(Icons.delete),
                                            iconSize: screenHeight * 0.035,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Divider(
                  thickness: 2,
                  indent: 50,
                  endIndent: 50,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 50.0, right: 50.0, bottom: 8.0, top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(translation(context).products,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(197, 0, 0, 0))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          /*
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: getData,
                            ), */
                          FloatingActionButton(
                            onPressed: () {
                              Navigator.push(
                                  (context),
                                  MaterialPageRoute(
                                      builder: (context) => AddProducts()));
                            },
                            backgroundColor: Color(0xFFE2725B),
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: screenHeight * 0.65,
                  width: screenWidth * 0.9,
                  child: data.isEmpty
                      ? Center(
                          child: Text(translation(context)
                              .no_available_products)) // Show a loader if data is still loading
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: data
                              .length, // Use the length of the fetched product list
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                /*----------------------------here is where to make it go to order details-------------------------------*/
                              },
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      // Name of the product
                                      Text(
                                        data[index].ProductName,
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.015,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      // Category of the product
                                      FutureBuilder<String>(
                                        future: _categoryNameFor(
                                            data[index].ProductCategory),
                                        builder: (_, snap) => Text(
                                          snap.connectionState ==
                                                  ConnectionState.done
                                              ? (snap.data ?? 'Uncategorized')
                                              : '…', // tiny placeholder while caching builds
                                          style: TextStyle(
                                              fontSize: screenWidth * 0.01,
                                              color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      Text(
                                        'Stock: ${data[index].ProductInventory.toStringAsFixed(0)}', // Display the price formatted to 2 decimal places
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.015,
                                            color: Colors.green),
                                        textAlign: TextAlign.center,
                                      ),

                                      // Price of the product
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            'Selling: ${data[index].SellingPrice.toStringAsFixed(2)} JOD', // Display the price formatted to 2 decimal places
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.01,
                                                color: Colors.green),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            'Purchase: ${data[index].PurchasePrice.toStringAsFixed(2)} JOD', // Display the price formatted to 2 decimal places
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.01,
                                                color: Colors.red),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        translation(context)
                                                            .confirm_deletion),
                                                    content: Text(translation(
                                                            context)
                                                        .delete_product_confirm),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog
                                                        },
                                                        child: Text(
                                                          translation(context)
                                                              .cancel,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          deleteProduct(data[
                                                                  index]
                                                              .id); // Call delete function
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog after deletion
                                                        },
                                                        child: Text(
                                                            translation(context)
                                                                .delete,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: Icon(Icons.delete),
                                            iconSize: screenHeight * 0.035,
                                          ),
                                          SizedBox(
                                            width: 20,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          UpdateProduct(
                                                              product: data[
                                                                  index])));
                                            },
                                            icon: Icon(Icons.edit_note_sharp),
                                            iconSize: screenHeight * 0.035,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
