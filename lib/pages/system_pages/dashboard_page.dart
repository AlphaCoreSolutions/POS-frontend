import 'dart:async';
//import 'dart:io';
import 'package:fixed_pos/models/product_model.dart';
import 'package:fixed_pos/pages/essential_pages/api_handler.dart';
import 'package:fixed_pos/language_changing/constants.dart';
import 'package:fixed_pos/pages/system_pages/orderDetails_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting dates

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController searchController = TextEditingController();
  final ApiHandler apiHandler = ApiHandler();
  double totalGrandAmount = 0.0;
  String _searchQuery = '';
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  List<OrderDto> ordersList = [];
  int lowStockCount = 0;
  String? bestSellerText;
  int maxUsage = 0;
  DateTime? trendFromDate;
  DateTime? trendToDate;
  List<FlSpot> trendSpots = [];
  bool isTrendLoading = false;

  Timer? _debounce;

  Future<void> fetchBestSeller() async {
    String? bestSellerName = await apiHandler.fetchBestSellingProduct();

    setState(() {
      bestSellerText = bestSellerName ?? "No Data Available"; // Update UI
    });
  }

  Future<void> checkAllProducts(List<int> productIds) async {
    int count = 0;

    for (var id in productIds) {
      final productDetails = await apiHandler.fetchProductDetails(id);
      if (productDetails != null &&
          productDetails.containsKey('productInventory')) {
        double productInventory = productDetails['productInventory'];
        if (productInventory < 5) {
          count++;
        }
      }
    }

    setState(() {
      lowStockCount = count; // Update stock count when done
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshPage(); // Call the method to refresh page data
    fetchBestSeller();
  }

  void _refreshPage() async {
    setState(() {
      // This will trigger a UI update when data is fetched
      _searchQuery = ''; // Reset search query, if necessary
      selectedFromDate = null;
      selectedToDate = null;
    });
    // Fetch product IDs dynamically
    List<int> productIds = await apiHandler.fetchAllProductIds();

    // Check stock levels
    await checkAllProducts(productIds);
    // If you need to fetch fresh data (e.g., orders list):
    List<OrderDto> orders = await _fetchFilteredOrders();
    setState(() {
      ordersList = orders; // Update your state with fresh data
    });
  }

  @override
  void dispose() {
    // Clean up the timer and controller when the widget is disposed
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search Orders By Number...",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (query) {
        // Cancel any previous debounce timers if they're still active
        if (_debounce?.isActive ?? false) {
          _debounce?.cancel();
        }
        // Start a new debounce timer
        _debounce = Timer(const Duration(milliseconds: 1000), () {
          setState(() {
            _searchQuery =
                query; // Update search query only after the debounce time
          });
          // Call your filtering logic here based on _searchQuery
          print(
              'Search Query: $_searchQuery'); // Example: Use this value to filter your list
        });
      },
    );
  }

  // Function to fetch orders and filter them
  Future<List<OrderDto>> _fetchFilteredOrders() async {
    List<OrderDto> orders = await apiHandler.fetchOrderHistory();
    return orders.where((order) {
      return order.id.toString().contains(_searchQuery);
    }).toList();
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime? initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
  }

/*  
  Future<Map<String, dynamic>?> _fetchOrderByIdAndDateRange(int orderId, DateTime fromDate, DateTime toDate) async {
  try {
    // Fetch order details from API
    Map<String, dynamic> order = await apiHandler.fetchOrderDetailsById(orderId);

    // Parse 'orderPlaced' date from API response
    DateTime orderPlacedDate = DateTime.parse(order['orderPlaced']);

    // Check if the order's date is within the selected range
    if (orderPlacedDate.isAfter(fromDate.subtract(Duration(days: 1))) &&
        orderPlacedDate.isBefore(toDate.add(Duration(days: 1)))) {
      return order; // ✅ Order found within the range
    } else {
      return null;  // ❌ Order is outside the date range
    }
  } catch (e) {
    print("Error fetching order: $e");
    return null;
  }
}

void _fetchOrdersForSelectedDateRange() async {
  if (selectedFromDate == null || selectedToDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select both From and To dates")),
    );
    return;
  }

  int orderId = int.tryParse(searchController.text) ?? -1;
  if (orderId == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please enter a valid Order ID")),
    );
    return;
  }

  Map<String, dynamic>? order = await _fetchOrderByIdAndDateRange(orderId, selectedFromDate!, selectedToDate!);

  if (order != null) {
    print("Order Found: $order");
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No order found in the selected date range.")),
    );
  }
}


  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
}
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(translation(context).balanceSheet,
            style: GoogleFonts.poppins()),
        backgroundColor: Color(0xFF36454F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDashboardCards(context),
              SizedBox(height: 20),
              _buildCharts(),
              SizedBox(height: 20),
              Row(
                children: [
                  // From Date Button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        selectedFromDate =
                            await _selectDate(context, selectedFromDate);
                        setState(() {});
                      },
                      icon: const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF5D4037)),
                      label: Text(
                        selectedFromDate == null
                            ? 'From Date'
                            : DateFormat('yyyy-MM-dd')
                                .format(selectedFromDate!),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFF1E4D4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFBCAAA4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

// To Date Button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        selectedToDate =
                            await _selectDate(context, selectedToDate);
                        setState(() {});
                      },
                      icon: const Icon(Icons.date_range_outlined,
                          size: 18, color: Color(0xFF5D4037)),
                      label: Text(
                        selectedToDate == null
                            ? 'To Date'
                            : DateFormat('yyyy-MM-dd').format(selectedToDate!),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFF1E4D4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFBCAAA4)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Search Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedFromDate != null && selectedToDate != null) {
                        List<OrderDto> result =
                            await apiHandler.searchOrdersByDateRange(
                                selectedFromDate!, selectedToDate!);
                        setState(() {
                          ordersList = result;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select both dates",
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Color(0xFF36454F),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white, // dark grey
                    ),
                    label: const Text(
                      "Search",
                      style: TextStyle(color: Colors.white), // dark grey
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB87333), // copper color
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(
                height: 20,
              ),

              // Use FutureBuilder to load and display orders dynamically
              _buildSearchField(),
              SizedBox(
                height: 10,
              ),
              FutureBuilder<List<OrderDto>>(
                future: Future.value(ordersList),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: Color(0xFFB87333),
                    ));
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error loading orders: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No orders available"));
                  }
                  List<OrderDto> orders = snapshot.data!;
                  // Return the filtered orders here
                  return _buildRecentOrders(orders);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dashboard Cards for Summary Metrics
  Widget _buildDashboardCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _dashboardCardSales(translation(context).sales, "Loading...",
            Icons.attach_money, Colors.green, ordersList),
        _dashboardCard(translation(context).transactions,
            ordersList.length.toString(), Icons.shopping_cart, Colors.blue),
        _dashboardCard(translation(context).topSellingProducts,
            "$bestSellerText", Icons.coffee, Colors.orange),
        _dashboardCardProfit(
            'Profit', Icons.trending_up, Colors.teal, ordersList)

        /*
        _dashboardCard(translation(context).stockLevel,
            lowStockCount.toStringAsFixed(0), Icons.warning, Colors.red),
      */
      ],
    );
  }

  Widget _dashboardCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _getTotalSales(List<OrderDto> orders) async {
    double totalSales = 0.0;

    // Loop through the list of orders and sum up their grandTotal
    for (var order in orders) {
      totalSales += order.GrandTotal; // Access grandTotal from OrderDto
    }

    return totalSales;
  }

  Widget _dashboardCardSales(String title, String value, IconData icon,
      Color color, List<OrderDto> orders) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                FutureBuilder<double>(
                  future: _getTotalSales(
                      orders), // Pass the orders list to get total sales
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading...",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold));
                    } else if (snapshot.hasError) {
                      return Text("Error",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold));
                    } else if (snapshot.hasData) {
                      return Text(
                        "\$${snapshot.data!.toStringAsFixed(2)}", // Display the total sales
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return Text("No Data",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTrend() async {
    if (trendFromDate == null || trendToDate == null) return;

    setState(() => isTrendLoading = true);
    try {
      final result = await apiHandler.fetchSalesDataByDateRange(
          trendFromDate!, trendToDate!);
      setState(() {
        trendSpots = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading trend data")),
      );
    } finally {
      setState(() => isTrendLoading = false);
    }
  }

  // ---------- helpers & cache ----------
  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  final Map<int, _Price> _priceCache = {}; // productId -> prices

  Set<int> _collectProductIds(List<OrderDto> orders) {
    final ids = <int>{};
    for (final o in orders) {
      final items = (o as dynamic).orderItems as List? ?? const [];
      for (final it in items) {
        final d = it as dynamic;
        final pid = d.productId as int? ?? int.tryParse('${d.productId}') ?? -1;
        if (pid > 0) ids.add(pid);
      }
    }
    return ids;
  }

  Future<void> _warmPriceCacheForOrders(List<OrderDto> orders) async {
    final ids = _collectProductIds(orders)
        .where((id) => !_priceCache.containsKey(id))
        .toList();
    if (ids.isEmpty) return;

    // fetch all missing product details in parallel
    await Future.wait(ids.map((id) async {
      final p = await apiHandler.fetchProductDetails(id); // returns Map
      final sell = _asDouble(p?['sellingPrice']);
      final cost = _asDouble(p?['purchasePrice']);
      _priceCache[id] = _Price(sell, cost);
    }));
  }

  /// Profit = Σ ((selling - purchase) * qty) for all order items.
  /// Uses product price cache (built from fetchProductDetails).
  Future<double> _getTotalProfit(List<OrderDto> orders) async {
    if (orders.isEmpty) return 0;

    await _warmPriceCacheForOrders(orders);

    double profit = 0.0;
    for (final o in orders) {
      final items = (o as dynamic).orderItems as List? ?? const [];
      for (final it in items) {
        final d = it as dynamic;
        final pid = d.productId as int? ?? int.tryParse('${d.productId}') ?? -1;
        final qty = _asDouble(d.quantity);

        final price = _priceCache[pid];
        final sell = price?.sell ?? 0;
        final cost = price?.cost ?? 0;

        profit += (sell - cost) * qty;
      }
    }
    return profit;
  }

  Widget _dashboardCardProfit(
    String title,
    IconData icon,
    Color color,
    List<OrderDto> orders,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                FutureBuilder<double>(
                  future: _getTotalProfit(orders),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Text('Loading…',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold));
                    }
                    if (snap.hasError) {
                      debugPrint('[Profit] ${snap.error}');
                      // show 0 instead of “Error”
                      return Text('0.00 JOD',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32)));
                    }
                    final v = (snap.data ?? 0).toDouble();
                    final isPositive = v >= 0;
                    return Text(
                      '\$${v.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sales & Revenue Charts
  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translation(context).salesTrends,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // 🔶 Date Range Filter
        Row(
          children: [
            // From Date
            Expanded(
              child: TextButton.icon(
                onPressed: () async {
                  trendFromDate = await _selectDate(context, trendFromDate);
                  setState(() {});
                },
                icon: const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Color(0xFF5D4037)),
                label: Text(
                  trendFromDate == null
                      ? "From Date"
                      : DateFormat('yyyy-MM-dd').format(trendFromDate!),
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF1E4D4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFBCAAA4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // To Date
            Expanded(
              child: TextButton.icon(
                onPressed: () async {
                  trendToDate = await _selectDate(context, trendToDate);
                  setState(() {});
                },
                icon: const Icon(Icons.date_range_outlined,
                    size: 18, color: Color(0xFF5D4037)),
                label: Text(
                  trendToDate == null
                      ? "To Date"
                      : DateFormat('yyyy-MM-dd').format(trendToDate!),
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF1E4D4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFBCAAA4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Filter Button
            ElevatedButton.icon(
              onPressed: () {
                if (trendFromDate != null && trendToDate != null) {
                  _loadTrend(); // Load the trend chart
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select both dates",
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Color(0xFF36454F),
                      behavior: SnackBarBehavior.floating,
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.trending_up, color: Colors.white),
              label:
                  const Text("Filter", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB87333),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 📈 Trend Chart
        if (isTrendLoading)
          const Center(
              child: CircularProgressIndicator(
            color: Color(0xFFB87333),
          ))
        else if (trendSpots.isEmpty)
          const Text("No sales data available",
              style: TextStyle(color: Colors.black54))
        else
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFD7CCC8).withOpacity(0.2),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendSpots,
                    isCurved: true,
                    color: Color(0xFFB87333),
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color(0xFFB87333).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Recent Orders Table
  Widget _buildRecentOrders(List<OrderDto> orders) {
    return Container(
      height: 600,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                SizedBox(height: 0),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Order ID: ${order.id}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Total: \$${order.GrandTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                Text(
                                  'Tips: ${order.tip.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE2725B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4),

                        // Order Placed Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder(
                              future:
                                  apiHandler.fetchOrderDetailsById(order.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading...');
                                }
                                if (snapshot.hasError) {
                                  return Text('Error fetching order details');
                                }
                                if (snapshot.hasData) {
                                  var orderDetails = snapshot.data;
                                  String formattedDate =
                                      DateFormat('yyyy-MM-dd H:mm').format(
                                    DateTime.parse(
                                        orderDetails?['orderPlaced']),
                                  );
                                  return Text(
                                    'Placed on: $formattedDate',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[800]),
                                  );
                                }
                                return Text('Order not found');
                              },
                            ),
                            Text(
                              'Payment Method: ${order.PaymentMethod}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Order Items List
                        Column(
                          children: order.orderItems.map((item) {
                            return FutureBuilder(
                              future: apiHandler
                                  .fetchProductDetails(item.productId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator(
                                    color: Color(0xFFB87333),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text('Error fetching product details');
                                }
                                if (snapshot.hasData) {
                                  var product = snapshot.data;
                                  ordersList = orders;

                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 2,
                                    child: ListTile(
                                      /* leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (product?['productPicture'] != null && product?['productPicture'].isNotEmpty)
                                            ? Image.file( // Only display local file path images
                                                File(product?['productPicture'].replaceAll('\\', '/')),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset( // Default image if no picture is available
                                                'lib/assets/fries.webp',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                      ),*/
                                      title: Text(
                                        product?['productName'] ??
                                            'Unknown Product',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              product?['productCategory'] ??
                                                  'No Category',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          Text(
                                              '${item.quantity} x \$${product?['sellingPrice'].toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                      trailing: Text(
                                        '\$${(item.quantity * (product?['sellingPrice'] ?? 0)).toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  );
                                }
                                return Text('Product not found');
                              },
                            );
                          }).toList(),
                        ),

                        Divider(),

                        // View Details Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE2725B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.arrow_forward,
                                size: 18, color: Colors.white),
                            label: Text(translation(context).viewDetails,
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        OrdersPage(), // Pass orderId here
                                    settings:
                                        RouteSettings(arguments: order.id)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Price {
  final double sell;
  final double cost;
  const _Price(this.sell, this.cost);
}
