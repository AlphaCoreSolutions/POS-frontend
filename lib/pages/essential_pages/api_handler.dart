import 'dart:convert';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/customer_model.dart';
import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/org_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/promocodes_model.dart';
import 'package:visionpos/models/supplier_model.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/models/user_model.dart';
import 'package:visionpos/utils/api_config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<List<Organization>> getOrganizations() async {
    final response = await http.get(Uri.parse(OrgUrl));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Organization.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load organizations (${response.statusCode})');
    }
  }

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

    final response = await http.post(
      Uri.parse('$AdvanceSearcUri?searchQuery=$searchQuery'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'searchQuery': searchQuery}),
    );

    if (response.statusCode == 200) {
      try {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => OrderDto.fromJson(json)).toList();
      } catch (e) {
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
        double total = (order['grandTotal'] ?? 0).toDouble();
        DateTime date = DateTime.parse(order['orderPlaced']);
        double x = date.millisecondsSinceEpoch.toDouble();
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

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return true;
          } else {
            throw Exception('API Error: ${responseData['message']}');
          }
        }
        return true;
      } else {
        throw Exception('Failed to post order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> postOrderWithResponse(OrderDto order) async {
    try {
      final url = Uri.parse(ordersUri);
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode(order.toJson());

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success')) {
            if (responseData['success'] == true) {
              return responseData['data'] ?? responseData;
            } else {
              throw Exception('API Error: ${responseData['message']}');
            }
          }
          return responseData;
        }
        return null;
      } else {
        throw Exception('Failed to post order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<OrderDto>> fetchOrderHistory() async {
    try {
      final url = Uri.parse(ordersUri);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> responseData;

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          if (decoded['success'] == true) {
            responseData = decoded['data'] as List<dynamic>? ?? const [];
          } else {
            throw Exception('API Error: ${decoded['message']}');
          }
        } else if (decoded is List) {
          responseData = decoded;
        } else {
          throw Exception('Unexpected response structure');
        }

        return responseData.map((orderData) => OrderDto.fromJson(orderData)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOrderDetailsById(int orderId) async {
    try {
      final url = Uri.parse('$ordersUri/$orderId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  // --------------------------------- CATEGORY --------------------------------
  Future<List<Category>> getCategoryData() async {
    final uri = Uri.parse(CategoryUri);
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode > 299) {
        return [];
      }

      final decoded = json.decode(response.body);
      List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        if (decoded['success'] == true) {
          list = decoded['data'] as List<dynamic>? ?? const [];
        } else {
          return [];
        }
      } else if (decoded is List) {
        list = decoded;
      } else {
        return [];
      }

      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> getLeafCategoriesByOrg(int orgId) async {
    final uri = Uri.parse('$CategoryUri/subcategories/organization/$orgId');
    final resp = await http.get(
      uri,
      headers: {'Content-type': 'application/json; charset=UTF-8'},
    );
    if (resp.statusCode == 200) {
      final decoded = json.decode(resp.body);
      List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        if (decoded['success'] == true) {
          list = decoded['data'] as List<dynamic>? ?? const [];
        } else {
          throw Exception('API Error: ${decoded['message']}');
        }
      } else if (decoded is List) {
        list = decoded;
      } else {
        throw Exception('Unexpected response structure');
      }
      return list.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed leaf categories: ${resp.statusCode}');
  }

  Future<List<Category>> searchCategories(String searchQuery, {int? orgId}) async {
    final queryParams = <String, String>{};
    if (orgId != null) queryParams['orgId'] = orgId.toString();
    if (searchQuery.isNotEmpty) queryParams['categoryName'] = searchQuery;

    final uri = Uri.parse('$CategoryUri/search').replace(queryParameters: queryParams);
    final resp = await http.get(
      uri,
      headers: {'Content-type': 'application/json; charset=UTF-8'},
    );

    if (resp.statusCode == 200) {
      final decoded = json.decode(resp.body);
      List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        if (decoded['success'] == true) {
          list = decoded['data'] as List<dynamic>? ?? const [];
        } else {
          throw Exception('API Error: ${decoded['message']}');
        }
      } else if (decoded is List) {
        list = decoded;
      } else {
        throw Exception('Unexpected response structure');
      }
      return list.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to search categories: ${resp.statusCode}');
  }

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

    try {
      return await http.post(uri, headers: headers, body: payload);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> updateCategory({required Category category}) async {
    final uri = Uri.parse('$CategoryUri/${category.id}');
    try {
      return await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(category.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> deleteCategory({required int categoryID}) async {
    final uri = Uri.parse("$CategoryUri/$categoryID");
    try {
      return await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  //------------------------------------USER---------------------------------
  Future<List<User>> getUserData() async {
    final uri = Uri.parse(userUri);
    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<http.Response> updateUser({
    required int id,
    required User user,
  }) async {
    final uri = Uri.parse("$userUri/$id");
    try {
      return await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(user.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  //-----------------------------------PRODUCT-------------------------------
  Future<List<Product>> getProductData() async {
    final uri = Uri.parse(productUri);
    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decoded = json.decode(response.body);
        List<dynamic> jsonData;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          if (decoded['success'] == true) {
            jsonData = decoded['data'] as List<dynamic>? ?? const [];
          } else {
            return [];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          return [];
        }
        return jsonData.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<http.Response> updateProduct({
    required int id,
    required Product product,
  }) async {
    final uri = Uri.parse("$productUri/$id");
    try {
      return await http.put(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(product.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> AddProducts({required Product product}) async {
    final uri = Uri.parse(productUri);
    try {
      return await http.post(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(product.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<List<Product>> advanceSearchProducts(String filter) async {
    final uri = Uri.parse('$productUri/search').replace(queryParameters: {'productName': filter});
    try {
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> list;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          if (decoded['success'] == true) {
            list = decoded['data'] as List<dynamic>? ?? const [];
          } else {
            throw Exception('API Error: ${decoded['message']}');
          }
        } else if (decoded is List) {
          list = decoded;
        } else {
          throw Exception('Unexpected response structure');
        }
        return list.map((e) => Product.fromJson(e)).toList();
      }
      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  Future<http.Response> deleteProducts({required int productID}) async {
    final uri = Uri.parse("$productUri/$productID");
    try {
      return await http.delete(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<List<int>> fetchAllProductIds() async {
    try {
      final response = await http.get(Uri.parse(productUri));
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        return products.map<int>((product) => product['productId'] as int).toList();
      } else {
        throw Exception('Failed to fetch product IDs');
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProductDetails(int productId) async {
    try {
      final response = await http.get(Uri.parse('$productUri/$productId'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'] as Map<String, dynamic>;
        }
        if (decoded is Map<String, dynamic>) return decoded;
        throw Exception('Unexpected product response');
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> searchProductByName({required String productName}) async {
    final uri = Uri.parse('$productUri?name=$productName');
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => Product.fromJson(data)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<String?> fetchBestSellingProduct() async {
    try {
      final ordersResponse = await http.get(Uri.parse(ordersUri));
      if (ordersResponse.statusCode == 200) {
        List<dynamic> orders = json.decode(ordersResponse.body);
        Map<int, int> productUsage = {};

        for (var order in orders) {
          List<dynamic> orderItems = order['orderItems'] ?? [];
          for (var item in orderItems) {
            int itemProductId = item['productId'];
            productUsage[itemProductId] = (productUsage[itemProductId] ?? 0) + 1;
          }
        }

        int? bestSellerId = productUsage.entries.isNotEmpty
            ? productUsage.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null;

        if (bestSellerId != null) {
          Map<String, dynamic>? productDetails = await fetchProductDetails(bestSellerId);
          if (productDetails != null && productDetails.containsKey('productName')) {
            return productDetails['productName'].toString();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  //-----------------------------------CUSTOMER------------------------------
  Future<List<Customer>> getCustomerData() async {
    final uri = Uri.parse(customersUri);
    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Customer.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<http.Response> addCustomer({required Customer customer}) async {
    try {
      return await http.post(
        Uri.parse(customersUri),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(customer.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> updateCustomer({required int id, required Customer customer}) async {
    try {
      return await http.put(
        Uri.parse("$customersUri/$id"),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(customer.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> deleteCustomers({required int customerId}) async {
    try {
      return await http.delete(
        Uri.parse("$customersUri/$customerId"),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  //-----------------------------------SUPPLIER------------------------------
  Future<List<Supplier>> getSupplierData() async {
    final uri = Uri.parse(suppliersUri);
    try {
      final response = await http.get(
        uri,
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Supplier.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<http.Response> addSuuplier({required Supplier supplier}) async {
    try {
      return await http.post(
        Uri.parse(suppliersUri),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(supplier.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> updateSupplier({required int id, required Supplier supplier}) async {
    try {
      return await http.put(
        Uri.parse("$suppliersUri/$id"),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(supplier.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<http.Response> deleteSupplier({required int supplierId}) async {
    try {
      return await http.delete(
        Uri.parse("$suppliersUri/$supplierId"),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  //-----------------------------------PROMOCODES------------------------------
  Future<List<Promocodes>> fetchPromoCodes() async {
    try {
      final response = await http.get(Uri.parse(promoCodesUri));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Promocodes.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load promo codes');
      }
    } catch (e) {
      throw Exception('Exception while fetching promo codes: $e');
    }
  }

  Future<http.Response> postPromoCode(Promocodes promoCode) async {
    try {
      return await http.post(
        Uri.parse(promoCodesUri),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(promoCode.toJson()),
      );
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<bool> deletePromoCode(int id) async {
    try {
      final response = await http.delete(Uri.parse('$promoCodesUri/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
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

    try {
      final response = await http.put(
        Uri.parse(taxesUri),
        headers: {'Content-type': 'application/json; charset=UTF-8'},
        body: json.encode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      return false;
    }
  }

  // ==================== DASHBOARD APIs ====================
  String get dashboardUri => ApiConfig.instance.buildUrl('Dashboard');
  String get reportsUri => ApiConfig.instance.buildUrl('POSReports');

  Future<Map<String, dynamic>?> getDashboardSummary(int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/Summary?orgId=$orgId' : '$dashboardUri/Summary';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesTrend(int days, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/SalesTrend?days=$days&orgId=$orgId' : '$dashboardUri/SalesTrend?days=$days';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRevenueByHour(DateTime? date, int? orgId) async {
    try {
      final dateStr = date?.toIso8601String() ?? DateTime.now().toIso8601String();
      final url = orgId != null ? '$dashboardUri/RevenueByHour?date=$dateStr&orgId=$orgId' : '$dashboardUri/RevenueByHour?date=$dateStr';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int top, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/TopProducts?top=$top&orgId=$orgId' : '$dashboardUri/TopProducts?top=$top';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopCategories(int top, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/TopCategories?top=$top&orgId=$orgId' : '$dashboardUri/TopCategories?top=$top';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders(int count, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/RecentOrders?count=$count&orgId=$orgId' : '$dashboardUri/RecentOrders?count=$count';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethodDistribution(DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$dashboardUri/PaymentMethodDistribution';
      final params = <String>[];
      if (startDate != null) params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyComparison(int months, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/MonthlyComparison?months=$months&orgId=$orgId' : '$dashboardUri/MonthlyComparison?months=$months';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLowStockAlert(double threshold, int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/LowStockAlert?threshold=$threshold&orgId=$orgId' : '$dashboardUri/LowStockAlert?threshold=$threshold';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQuickStats(int? orgId) async {
    try {
      final url = orgId != null ? '$dashboardUri/QuickStats?orgId=$orgId' : '$dashboardUri/QuickStats';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== POS REPORTS APIs ====================
  Future<Map<String, dynamic>?> getSalesByDateRange(DateTime startDate, DateTime endDate, int? orgId) async {
    try {
      var url = '$reportsUri/SalesByDateRange?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDailySales(DateTime date, int? orgId) async {
    try {
      var url = '$reportsUri/DailySales?date=${date.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime? startDate, DateTime? endDate, int? orgId, int top) async {
    try {
      var url = '$reportsUri/TopSellingProducts?top=$top';
      if (startDate != null) url += '&startDate=${startDate.toIso8601String()}';
      if (endDate != null) url += '&endDate=${endDate.toIso8601String()}';
      if (orgId != null) url += '&orgId=$orgId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) return List<Map<String, dynamic>>.from(jsonResponse);
        if (jsonResponse is Map && jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/SalesByPaymentMethod';
      final params = <String>[];
      if (startDate != null) params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) return List<Map<String, dynamic>>.from(jsonResponse);
        if (jsonResponse is Map && jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByCategory(DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/SalesByCategory';
      final params = <String>[];
      if (startDate != null) params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) return List<Map<String, dynamic>>.from(jsonResponse);
        if (jsonResponse is Map && jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getInventoryStatus(int? orgId, double? lowStockThreshold) async {
    try {
      var url = '$reportsUri/InventoryStatus';
      final params = <String>[];
      if (orgId != null) params.add('orgId=$orgId');
      if (lowStockThreshold != null) params.add('lowStockThreshold=$lowStockThreshold');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionDetails(int orderId) async {
    try {
      final url = '$reportsUri/TransactionDetails/$orderId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfitAnalysis(DateTime? startDate, DateTime? endDate, int? orgId) async {
    try {
      var url = '$reportsUri/ProfitAnalysis';
      final params = <String>[];
      if (startDate != null) params.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
      if (orgId != null) params.add('orgId=$orgId');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }
}
