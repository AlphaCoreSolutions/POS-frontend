import 'dart:convert';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/customer_model.dart';
import 'package:visionpos/models/org_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/promoCodes_model.dart';
import 'package:visionpos/models/supplier_model.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/models/user_model.dart';
import 'package:visionpos/utils/api_config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Select * from Orders Where OrderPlaced between N'2025-01-01' AND N'2025-03-31'

class ApiHandler {
  // Dynamic URLs using ApiConfig
  String get userUri => ApiConfig.instance.buildUrl('users');
  String get productUri => ApiConfig.instance.buildUrl('products');
  String get CategoryUri => ApiConfig.instance.buildUrl('Category');
  String get ordersUri => ApiConfig.instance.buildUrl('orders');
  String get customersUri => ApiConfig.instance.buildUrl('customers');
  String get suppliersUri => ApiConfig.instance.buildUrl('suppliers');
  String get promoCodesUri => ApiConfig.instance.buildUrl('promoCodes');
  String get taxesUri => ApiConfig.instance.buildUrl('taxes/1');
  String get AdvanceSearcUri =>
      ApiConfig.instance.buildUrl('Orders/AdvanceSearchWhere');
  String get OrgUrl => ApiConfig.instance.buildUrl('Organizations');

  Future<User> fetchUserById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$userUri/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return User.fromJson(jsonMap);
    } else {
      throw Exception('Failed to fetch user (status ${response.statusCode})');
    }
  }

  //----------------------------ORGANIZATION---------------------------------
  /// GET all organizations
  Future<List<Organization>> getOrganizations() async {
    final response = await http.get(Uri.parse(OrgUrl));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Organization.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load organizations (${response.statusCode})');
    }
  }

  /// GET a single organization by ID
  Future<Organization> getOrganization(int id) async {
    final response = await http.get(Uri.parse('$OrgUrl/$id'));
    if (response.statusCode == 200) {
      return Organization.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load organization ($id): ${response.statusCode}',
      );
    }
  }

  /// POST to add or modify an organization
  /// API returns a simple message in the response body
  Future<String> addModifyOrganization(Organization org) async {
    final response = await http.post(
      Uri.parse('$OrgUrl/AddModify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(org.toJson()),
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Save failed: ${response.statusCode}');
    }
  }

  /// DELETE an organization by ID
  Future<void> deleteOrganization(int id) async {
    final response = await http.delete(Uri.parse('$OrgUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }

  //-----------------------------------ORDER---------------------------------
  Future<List<OrderDto>> searchOrdersByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final formattedFrom = DateFormat('yyyy-MM-dd').format(from);
    final formattedTo = DateFormat('yyyy-MM-dd').format(to);

    final searchQuery =
        "OrderPlaced BETWEEN N'$formattedFrom' AND N'$formattedTo'";

    print("🟡 Sending POST to: $AdvanceSearcUri");
    print("🔵 Query: $searchQuery");

    final response = await http.post(
      Uri.parse('$AdvanceSearcUri?searchQuery=$searchQuery'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'searchQuery': searchQuery}),
    );

    print("🟢 Status Code: ${response.statusCode}");
    print("🟠 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => OrderDto.fromJson(json)).toList();
      } catch (e) {
        print("🔴 JSON decode error: $e");
        throw Exception('Failed to decode order data');
      }
    } else {
      throw Exception('Failed to fetch orders. Status: ${response.statusCode}');
    }
  }

  Future<List<FlSpot>> fetchSalesDataByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final formattedFrom = DateFormat('yyyy-MM-dd').format(from);
    final formattedTo = DateFormat('yyyy-MM-dd').format(to);

    final searchQuery =
        "OrderPlaced BETWEEN N'$formattedFrom' AND N'$formattedTo'";

    final response = await http.post(
      Uri.parse('$AdvanceSearcUri?searchQuery=$searchQuery'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'searchQuery': searchQuery}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<FlSpot> spots = [];

      for (var order in data) {
        double total = order['grandTotal']?.toDouble() ?? 0;
        DateTime date = DateTime.parse(order['orderPlaced']);
        double x =
            date.millisecondsSinceEpoch.toDouble(); // or convert to day number
        double y = total;
        spots.add(FlSpot(x, y));
      }

      return spots;
    } else {
      throw Exception('Failed to load sales data');
    }
  }

  Future<bool> postOrder(OrderDto order) async {
    try {
      final url = Uri.parse(ordersUri);
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode(order.toJson());

      // Debugging logs
      print("Posting order to: $url");
      print("Request Headers: $headers");
      print("Request Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      // Update the condition to accept 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Order posted successfully!");
        return true;
      } else {
        print("Failed to post order. Status Code: ${response.statusCode}");
        print("Response: ${response.body}");
        throw Exception('Failed to post order');
      }
    } catch (e) {
      print("Error posting order: $e");
      throw Exception('Error: $e');
    }
  }

  Future<List<OrderDto>> fetchOrderHistory() async {
    try {
      // API endpoint for fetching orders
      final url = Uri.parse(ordersUri);

      // Make the GET request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        List<OrderDto> orders = responseData
            .map((orderData) => OrderDto.fromJson(orderData))
            .toList();
        return orders;
      } else {
        print(
          'Error: Failed to load orders. Status code: ${response.statusCode}',
        );
        throw Exception('Failed to load orders ${response.statusCode}');
      }
    } catch (e) {
      print('Error: Failed to load orders - $e');
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOrderDetailsById(int orderId) async {
    try {
      // Updated to use local host orders URI
      final url = Uri.parse('$ordersUri/$orderId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching order details: ${response.statusCode}');
        throw Exception('Failed to fetch order details');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch order details');
    }
  }

  Future<List<OrderDto>> searchOrders({String searchQuery = ""}) async {
    try {
      final url = Uri.parse(ordersUri);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> ordersJson = json.decode(response.body);
        List<OrderDto> orders = ordersJson
            .map((orderJson) => OrderDto.fromJson(orderJson))
            .toList();

        if (searchQuery.isNotEmpty) {
          orders = orders
              .where((order) => order.id.toString().contains(searchQuery))
              .toList();
        }

        return orders;
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch orders');
    }
  }

  Future<List<FlSpot>> fetchSalesData() async {
    try {
      List<OrderDto> orders = await fetchOrderHistory();
      if (orders.isEmpty) return [];

      return orders
          .asMap()
          .entries
          .map(
            (entry) => FlSpot(
              entry.key.toDouble(),
              (entry.value.GrandTotal as num).toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching sales data from orders: $e');
      return [];
    }
  }

  Future<int?> findBestSellingProduct(List<int> orderIds) async {
    Map<int, int> productCount = {};

    for (int orderId in orderIds) {
      try {
        Map<String, dynamic> orderData = await fetchOrderDetailsById(orderId);
        List<dynamic> orderItems = orderData['orderItems'];

        for (var item in orderItems) {
          int productId = item['productId'];
          int quantity = item['quantity'];
          productCount[productId] = (productCount[productId] ?? 0) + quantity;
        }
      } catch (e) {
        print('Skipping order $orderId due to error: $e');
      }
    }

    int? bestSeller = productCount.entries.isNotEmpty
        ? productCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return bestSeller;
  }

  // --------------------------------- CATEGORY --------------------------------
  Future<List<Category>> getCategoryData() async {
    final uri = Uri.parse(CategoryUri);
    try {
      // If your API needs auth, pull token from prefs here.
      // final token = (await SharedPreferences.getInstance()).getString('token');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        // if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      debugPrint('[GET] $uri  -> ${response.statusCode}');
      // Log body when not 2xx to see server errors
      if (response.statusCode < 200 || response.statusCode > 299) {
        debugPrint('[GET] body: ${response.body}');
        return [];
      }

      final decoded = json.decode(response.body);
      // Your controller returns a List, but this makes it robust if it ever wraps:
      final List<dynamic> list =
          decoded is List ? decoded : (decoded['items'] as List? ?? const []);
      debugPrint('Raw API response: $list');

      return list
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getCategoryData() error: $e\n$st');
      return [];
    }
  }

  /// (Optional) server leaf-categories by org, if you want it:
  Future<List<Category>> getLeafCategoriesByOrg(int orgId) async {
    final uri = Uri.parse(
      '$CategoryUri/GetSubcategoriesByOrganization',
    ).replace(queryParameters: {'orgId': '$orgId'});
    final resp = await http.get(
      uri,
      headers: {'Content-type': 'application/json; charset=UTF-8'},
    );
    if (resp.statusCode == 200) {
      final List list = json.decode(resp.body);
      return list.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed leaf categories: ${resp.statusCode}');
  }

  /// Advanced search for categories
  Future<List<Category>> searchCategories(String searchQuery,
      {int? orgId}) async {
    final queryParams = <String, String>{
      'searchQuery': searchQuery,
    };

    // Add orgId if provided
    if (orgId != null) {
      queryParams['orgId'] = orgId.toString();
    }

    final uri = Uri.parse(
      '$CategoryUri/AdvanceSearch',
    ).replace(queryParameters: queryParams);

    print('🟡 [searchCategories] GET $uri');
    print('🔵 [searchCategories] searchQuery: $searchQuery, orgId: $orgId');

    final resp = await http.get(
      uri,
      headers: {'Content-type': 'application/json; charset=UTF-8'},
    );

    print('🟢 [searchCategories] Status: ${resp.statusCode}');
    print('🟢 [searchCategories] Body: ${resp.body}');

    if (resp.statusCode == 200) {
      final List list = json.decode(resp.body);
      return list.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to search categories: ${resp.statusCode}');
  }

  /// Client-side helpers
  Future<List<Category>> getCategoriesForOrg(int orgId) async {
    final all = await getCategoryData();
    return all.where((c) => c.organizationId == orgId).toList();
  }

  List<Category> rootsOf(List<Category> all) =>
      all.where((c) => c.mainCategoryId == null).toList();

  List<Category> childrenOf(int parentId, List<Category> all) =>
      all.where((c) => c.mainCategoryId == parentId).toList();

  Future<http.Response> AddCategory({required Category category}) async {
    final uri = Uri.parse(CategoryUri);
    final headers = {'Content-type': 'application/json; charset=UTF-8'};
    final payload = json.encode(category.toJson());

    // ── Pre-request logs ─────────────────────────────────────
    print('🟡 [AddCategory] POST $uri');
    print('🔵 [AddCategory] Headers: $headers');
    print('🔵 [AddCategory] Body: $payload');

    final sw = Stopwatch()..start();
    try {
      final response = await http.post(uri, headers: headers, body: payload);
      sw.stop();

      // ── Post-request logs ───────────────────────────────────
      print(
        '🟢 [AddCategory] Status: ${response.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      print('🟢 [AddCategory] Response headers: ${response.headers}');
      print('🟢 [AddCategory] Response body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('🔴 [AddCategory] Non-success status received.');
      }
      return response;
    } catch (e, st) {
      sw.stop();
      print(
        '🔴 [AddCategory] Exception after ${sw.elapsedMilliseconds} ms: $e',
      );
      print('🔴 [AddCategory] Stack: $st');
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> updateCategory({required Category category}) async {
    final uri = Uri.parse('$CategoryUri/${category.id}');
    try {
      final response = await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(category.toJson()),
      );
      return response;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> deleteCategory({required int categoryID}) async {
    final uri = Uri.parse("$CategoryUri/$categoryID");
    try {
      final response = await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
      return response;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  //------------------------------------USER---------------------------------
  Future<List<User>> getUserData() async {
    List<User> data = [];
    final uri = Uri.parse(userUri);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('Raw API response: $jsonData');
        data = jsonData.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return data;
  }

  Future<http.Response> updateUser({
    required int id,
    required User user,
  }) async {
    final uri = Uri.parse("$userUri/$id");
    late http.Response response;

    try {
      response = await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(user),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  //-----------------------------------PRODUCT-------------------------------
  Future<List<Product>> getProductData() async {
    List<Product> data = [];
    final uri = Uri.parse(productUri);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('Raw API Product response: $jsonData');
        data = jsonData.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return data;
  }

  Future<http.Response> updateProduct({
    required int id,
    required Product product,
  }) async {
    final uri = Uri.parse("$productUri/$id");
    late http.Response response;

    try {
      response = await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(product),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<http.Response> AddProducts({required Product product}) async {
    final uri = Uri.parse(productUri);
    late http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(product),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  // POST a link and get response data
  Future<Map<String, dynamic>> postLinkAndGetData(String searchQuery) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$productUri/AdvanceSearch?searchQuery=$searchQuery',
        ), // Your API endpoint
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization if needed:
          // 'Authorization': 'Bearer your_token',
        },
        body: jsonEncode({
          'searchQuery': searchQuery, // The link you want to post
          // Add other parameters if needed
        }),
      );

      if (response.statusCode == 200) {
        // Successful request
        return jsonDecode(response.body);
      } else {
        // Handle different status codes
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the API: $e');
    }
  }

  Future<List<Product>> advanceSearchProducts(String filter) async {
    // Build a clean, encoded URI
    final uri = Uri.parse(
      '$productUri/GetAdvanceSearch',
    ).replace(queryParameters: {'searchQuery': filter});

    print('🟡 GET $uri'); // <-- inspect the fully‑encoded URL
    print('🔵 Filter body: $filter');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    print('🟢 Status: ${response.statusCode}');
    print('🟢 Body:   ${response.body}');

    if (response.statusCode == 200) {
      final list = (json.decode(response.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
      print('🟢 Found ${list.length} products');
      return list;
    }
    throw Exception('Search failed: ${response.statusCode}');
  }

  Future<http.Response> deleteProducts({required int productID}) async {
    final uri = Uri.parse("$productUri/$productID");
    late http.Response response;

    try {
      response = await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<List<int>> fetchAllProductIds() async {
    try {
      final response = await http.get(Uri.parse(productUri));

      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        return products
            .map<int>((product) => product['productId'] as int)
            .toList();
      } else {
        throw Exception('Failed to fetch product IDs');
      }
    } catch (e) {
      print('Error fetching product IDs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProductDetails(int productId) async {
    try {
      final response = await http.get(Uri.parse('$productUri/$productId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  Future<List<Product>> searchProductByName({
    required String productName,
  }) async {
    final uri = Uri.parse('$productUri?name=$productName');
    List<Product> products = [];

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        products = jsonData.map((data) => Product.fromJson(data)).toList();
      } else {
        print('Error: Received status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
    return products;
  }

  Future<String?> fetchBestSellingProduct() async {
    try {
      // Use local host orders URI
      final ordersResponse = await http.get(Uri.parse(ordersUri));
      if (ordersResponse.statusCode == 200) {
        List<dynamic> orders = json.decode(ordersResponse.body);
        Map<int, int> productUsage = {};

        for (var order in orders) {
          List<dynamic> orderItems = order['orderItems'];
          for (var item in orderItems) {
            int itemProductId = item['productId'];
            productUsage[itemProductId] =
                (productUsage[itemProductId] ?? 0) + 1;
          }
        }

        int? bestSellerId = productUsage.entries.isNotEmpty
            ? productUsage.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : null;

        if (bestSellerId != null) {
          Map<String, dynamic>? productDetails = await fetchProductDetails(
            bestSellerId,
          );
          if (productDetails != null &&
              productDetails.containsKey('productName')) {
            return productDetails['productName'];
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching best-selling product: $e');
      return null;
    }
  }

  //-----------------------------------CUSTOMER------------------------------
  Future<List<Customer>> getCustomerData() async {
    List<Customer> data = [];
    final uri = Uri.parse(customersUri);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('Raw API response: $jsonData');
        data = jsonData.map((json) => Customer.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return data;
  }

  Future<http.Response> addCustomer({required Customer customer}) async {
    final uri = Uri.parse(customersUri);
    late http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(customer),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<http.Response> updateCustomer({
    required int id,
    required Customer customer,
  }) async {
    final uri = Uri.parse("$customersUri/$id");
    late http.Response response;

    try {
      response = await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(customer),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<http.Response> deleteCustomers({required int customerId}) async {
    final uri = Uri.parse("$customersUri/$customerId");
    late http.Response response;

    try {
      response = await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  //-----------------------------------SUPPLIER------------------------------
  Future<List<Supplier>> getSupplierData() async {
    List<Supplier> data = [];
    final uri = Uri.parse(suppliersUri);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('Raw API response: $jsonData');
        data = jsonData.map((json) => Supplier.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return data;
  }

  Future<http.Response> addSuuplier({required Supplier supplier}) async {
    final uri = Uri.parse(suppliersUri);
    late http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(supplier),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<http.Response> updateSupplier({
    required int id,
    required Supplier supplier,
  }) async {
    final uri = Uri.parse("$suppliersUri/$id");
    late http.Response response;

    try {
      response = await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(supplier),
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  Future<http.Response> deleteSupplier({required int supplierId}) async {
    final uri = Uri.parse("$suppliersUri/$supplierId");
    late http.Response response;

    try {
      response = await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return response;
    }
    return response;
  }

  //-----------------------------------PROMOCODES------------------------------
  Future<List<Promocodes>> fetchPromoCodes() async {
    final uri = Uri.parse(promoCodesUri);
    print('[GET] Sending request to: $uri');

    try {
      final response = await http.get(uri);
      print('[GET] Response Code: ${response.statusCode}');
      print('[GET] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('[GET] Parsed ${data.length} promo codes.');
        return data.map((json) => Promocodes.fromJson(json)).toList();
      } else {
        print('[GET] Failed to load promo codes: ${response.body}');
        throw Exception('Failed to load promo codes');
      }
    } catch (e) {
      print('[GET] Exception occurred: $e');
      throw Exception('Exception while fetching promo codes');
    }
  }

  Future<http.Response> postPromoCode(Promocodes promoCode) async {
    final uri = Uri.parse(promoCodesUri);
    final encodedBody = json.encode(promoCode.toJson());

    print('[POST] Sending promo code to: $uri');
    print('[POST] Payload: $encodedBody');

    late http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: encodedBody,
      );

      print('[POST] Response Code: ${response.statusCode}');
      print('[POST] Response Body: ${response.body}');
      return response;
    } catch (e) {
      print('[POST] Exception occurred: $e');
      return http.Response('Error sending request: $e', 500);
    }
  }

  Future<bool> deletePromoCode(int id) async {
    final url = Uri.parse('$promoCodesUri/$id');
    print('[DELETE] Sending request to: $url');

    try {
      final response = await http.delete(url);
      print('[DELETE] Response Code: ${response.statusCode}');
      print('[DELETE] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[DELETE] Promo code with ID $id deleted successfully.');
        return true;
      } else {
        print('[DELETE] Failed to delete promo code: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[DELETE] Exception occurred: $e');
      return false;
    }
  }

  //-----------------------------------TAXES------------------------------
  Future<Taxes> getTaxes() async {
    try {
      final response = await http.get(Uri.parse(taxesUri));
      if (response.statusCode == 200) {
        return Taxes.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load taxes');
      }
    } catch (e) {
      throw Exception('Error fetching taxes: $e');
    }
  }

  Future<void> postTaxes(Taxes taxes) async {
    try {
      final response = await http.post(
        Uri.parse(taxesUri),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(taxes.toJson()),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to post taxes data');
      }
    } catch (e) {
      throw Exception('Error posting taxes data: $e');
    }
  }

  Future<bool> updateTaxes(double inHouseTax, double takeOutTax) async {
    final Map<String, dynamic> payload = {
      'id': 1,
      'inHouse': inHouseTax,
      'takeout': takeOutTax,
    };

    final String jsonPayload = json.encode(payload);

    try {
      final response = await http.put(
        Uri.parse(taxesUri),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: jsonPayload,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      print('Error: $error');
      return false;
    }
  }

  // ==================== DASHBOARD APIs ====================

  String get dashboardUri => ApiConfig.instance.buildUrl('Dashboard');
  String get reportsUri => ApiConfig.instance.buildUrl('POSReports');

  Future<Map<String, dynamic>?> getDashboardSummary(int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/Summary?orgId=$orgId'
          : '$dashboardUri/Summary';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesTrend(int days, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/SalesTrend?days=$days&orgId=$orgId'
          : '$dashboardUri/SalesTrend?days=$days';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching sales trend: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRevenueByHour(
      DateTime? date, int? orgId) async {
    try {
      final dateStr =
          date?.toIso8601String() ?? DateTime.now().toIso8601String();
      final url = orgId != null
          ? '$dashboardUri/RevenueByHour?date=$dateStr&orgId=$orgId'
          : '$dashboardUri/RevenueByHour?date=$dateStr';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching hourly revenue: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int top, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/TopProducts?top=$top&orgId=$orgId'
          : '$dashboardUri/TopProducts?top=$top';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching top products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopCategories(
      int top, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/TopCategories?top=$top&orgId=$orgId'
          : '$dashboardUri/TopCategories?top=$top';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching top categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders(
      int count, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/RecentOrders?count=$count&orgId=$orgId'
          : '$dashboardUri/RecentOrders?count=$count';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching recent orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethodDistribution(
      DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$dashboardUri/PaymentMethodDistribution';
      final params = <String>[];

      if (startDate != null)
        params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');

      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching payment distribution: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyComparison(
      int months, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/MonthlyComparison?months=$months&orgId=$orgId'
          : '$dashboardUri/MonthlyComparison?months=$months';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching monthly comparison: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLowStockAlert(
      double threshold, int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/LowStockAlert?threshold=$threshold&orgId=$orgId'
          : '$dashboardUri/LowStockAlert?threshold=$threshold';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching low stock alert: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQuickStats(int? orgId) async {
    try {
      final url = orgId != null
          ? '$dashboardUri/QuickStats?orgId=$orgId'
          : '$dashboardUri/QuickStats';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching quick stats: $e');
      return null;
    }
  }

  // ==================== POS REPORTS APIs ====================

  Future<Map<String, dynamic>?> getSalesByDateRange(
      DateTime startDate, DateTime endDate, int? orgId) async {
    try {
      var url =
          '$reportsUri/SalesByDateRange?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching sales by date range: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDailySales(DateTime date, int? orgId) async {
    try {
      var url = '$reportsUri/DailySales?date=${date.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching daily sales: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      DateTime? startDate, DateTime? endDate, int? orgId, int top) async {
    try {
      var url = '$reportsUri/TopSellingProducts?top=$top';
      if (startDate != null) url += '&startDate=${startDate.toIso8601String()}';
      if (endDate != null) url += '&endDate=${endDate.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching top selling products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(
      DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/SalesByPaymentMethod';
      final params = <String>[];

      if (startDate != null)
        params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');

      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching sales by payment method: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByCategory(
      DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/SalesByCategory';
      final params = <String>[];

      if (startDate != null)
        params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');

      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching sales by category: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getInventoryStatus(
      int? orgId, double? lowStockThreshold) async {
    try {
      var url = '$reportsUri/InventoryStatus';
      final params = <String>[];

      if (orgId != null) params.add('orgId=$orgId');
      if (lowStockThreshold != null)
        params.add('lowStockThreshold=$lowStockThreshold');

      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching inventory status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionDetails(int orderId) async {
    try {
      final url = '$reportsUri/TransactionDetails/$orderId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching transaction details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfitAnalysis(
      DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/ProfitAnalysis';
      final params = <String>[];

      if (startDate != null)
        params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');

      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching profit analysis: $e');
      return null;
    }
  }
}
