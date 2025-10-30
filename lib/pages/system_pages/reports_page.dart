import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  final ApiHandler _apiHandler = ApiHandler();
  int? _orgId;
  bool _isLoading = false;

  late TabController _tabController;

  // Date filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Data holders
  Map<String, dynamic>? _salesByDateRange;
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _salesByPaymentMethod = [];
  List<Map<String, dynamic>> _salesByCategory = [];
  Map<String, dynamic>? _inventoryStatus;
  Map<String, dynamic>? _profitAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOrganizationId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() => _orgId = orgId);
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiHandler.getSalesByDateRange(_startDate, _endDate, _orgId),
        _apiHandler.getTopSellingProducts(_startDate, _endDate, _orgId, 10),
        _apiHandler.getSalesByPaymentMethod(_startDate, _endDate, _orgId),
        _apiHandler.getSalesByCategory(_startDate, _endDate, _orgId),
        _apiHandler.getInventoryStatus(_orgId, 10),
        _apiHandler.getProfitAnalysis(_startDate, _endDate, _orgId),
      ]);

      setState(() {
        _salesByDateRange = results[0] as Map<String, dynamic>?;
        _topSellingProducts = results[1] as List<Map<String, dynamic>>;
        _salesByPaymentMethod = results[2] as List<Map<String, dynamic>>;
        _salesByCategory = results[3] as List<Map<String, dynamic>>;
        _inventoryStatus = results[4] as Map<String, dynamic>?;
        _profitAnalysis = results[5] as Map<String, dynamic>?;
      });
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAllReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Reports'),
        backgroundColor: const Color(0xFF36454F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllReports,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFB87333),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sales Overview'),
            Tab(text: 'Top Products'),
            Tab(text: 'Payment Methods'),
            Tab(text: 'Categories'),
            Tab(text: 'Inventory'),
            Tab(text: 'Profit Analysis'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSalesOverviewTab(),
                _buildTopProductsTab(),
                _buildPaymentMethodsTab(),
                _buildCategoriesTab(),
                _buildInventoryTab(),
                _buildProfitAnalysisTab(),
              ],
            ),
    );
  }

  Widget _buildSalesOverviewTab() {
    if (_salesByDateRange == null) {
      return const Center(child: Text('No data available'));
    }

    final totalOrders = _salesByDateRange!['totalOrders'] ?? 0;
    final totalSales = (_salesByDateRange!['totalSales'] ?? 0).toDouble();
    final avgOrderValue =
        (_salesByDateRange!['averageOrderValue'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeHeader(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Sales',
                  '\$${totalSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Average Order Value',
            '\$${avgOrderValue.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildTopProductsTab() {
    if (_topSellingProducts.isEmpty) {
      return const Center(child: Text('No product data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeHeader(),
          const SizedBox(height: 20),
          const Text(
            'Top Selling Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _topSellingProducts.isNotEmpty
                    ? (_topSellingProducts.first['totalQuantitySold'] ?? 0)
                            .toDouble() *
                        1.2
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _topSellingProducts.length) {
                          final product = _topSellingProducts[value.toInt()];
                          final name = product['productName'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 10
                                  ? '${name.substring(0, 10)}...'
                                  : name,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _topSellingProducts.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (entry.value['totalQuantitySold'] ?? 0).toDouble(),
                        color: Color(0xFFB87333),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildProductsList(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    if (_salesByPaymentMethod.isEmpty) {
      return const Center(child: Text('No payment data available'));
    }

    final total = _salesByPaymentMethod.fold<double>(
      0,
      (sum, item) => sum + ((item['totalAmount'] ?? 0) as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeHeader(),
          const SizedBox(height: 20),
          const Text(
            'Payment Method Distribution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: _salesByPaymentMethod.map((item) {
                  final amount = ((item['totalAmount'] ?? 0) as num).toDouble();
                  final percentage = total > 0 ? (amount / total * 100) : 0;
                  return PieChartSectionData(
                    value: amount,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    color:
                        _getColorForPaymentMethod(item['paymentMethod'] ?? ''),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._salesByPaymentMethod.map((item) {
            final method = item['paymentMethod'] ?? 'Unknown';
            final count = item['totalOrders'] ?? 0;
            final amount = ((item['totalAmount'] ?? 0) as num).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getIconForPaymentMethod(method),
                  color: _getColorForPaymentMethod(method),
                ),
                title: Text(method),
                subtitle: Text('$count orders'),
                trailing: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_salesByCategory.isEmpty) {
      return const Center(child: Text('No category data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeHeader(),
          const SizedBox(height: 20),
          const Text(
            'Sales by Category',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _salesByCategory.isNotEmpty
                    ? ((_salesByCategory.first['totalRevenue'] ?? 0) as num)
                            .toDouble() *
                        1.2
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _salesByCategory.length) {
                          final category = _salesByCategory[value.toInt()];
                          final name = category['categoryName'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 10
                                  ? '${name.substring(0, 10)}...'
                                  : name,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _salesByCategory.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: ((entry.value['totalRevenue'] ?? 0) as num)
                            .toDouble(),
                        color: const Color(0xFF36454F),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._salesByCategory.map((item) {
            final name = item['categoryName'] ?? 'Unknown';
            final quantity = item['totalQuantitySold'] ?? 0;
            final revenue = ((item['totalRevenue'] ?? 0) as num).toDouble();
            final productCount = item['productCount'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name),
                subtitle: Text('$productCount products • $quantity units sold'),
                trailing: Text(
                  '\$${revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_inventoryStatus == null) {
      return const Center(child: Text('No inventory data available'));
    }

    final totalProducts = _inventoryStatus!['totalProducts'] ?? 0;
    final totalStockValue =
        ((_inventoryStatus!['totalStockValue'] ?? 0) as num).toDouble();
    final lowStockCount = _inventoryStatus!['lowStockCount'] ?? 0;
    final outOfStockCount = _inventoryStatus!['outOfStockCount'] ?? 0;
    final products = (_inventoryStatus!['products'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Products',
                  totalProducts.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Stock Value',
                  '\$${totalStockValue.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Low Stock',
                  lowStockCount.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  outOfStockCount.toString(),
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...products.map<Widget>((product) {
            final name = product['productName'] ?? 'Unknown';
            final currentStock = (product['currentStock'] ?? 0);
            final isLowStock = product['isLowStock'] ?? false;
            final isOutOfStock = product['isOutOfStock'] ?? false;

            Color statusColor = Colors.green;
            String statusText = 'In Stock';
            if (isOutOfStock) {
              statusColor = Colors.red;
              statusText = 'Out of Stock';
            } else if (isLowStock) {
              statusColor = Colors.orange;
              statusText = 'Low Stock';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name),
                subtitle: Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
                trailing: Chip(
                  label: Text('$currentStock units'),
                  backgroundColor: statusColor.withOpacity(0.2),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProfitAnalysisTab() {
    if (_profitAnalysis == null) {
      return const Center(child: Text('No profit data available'));
    }

    final totalRevenue =
        ((_profitAnalysis!['totalRevenue'] ?? 0) as num).toDouble();
    final totalCost = ((_profitAnalysis!['totalCost'] ?? 0) as num).toDouble();
    final totalProfit =
        ((_profitAnalysis!['totalProfit'] ?? 0) as num).toDouble();
    final profitMargin =
        ((_profitAnalysis!['profitMargin'] ?? 0) as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeHeader(),
          const SizedBox(height: 20),
          const Text(
            'Profit Analysis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatCard(
            'Total Revenue',
            '\$${totalRevenue.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Cost',
            '\$${totalCost.toStringAsFixed(2)}',
            Icons.trending_down,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Profit',
            '\$${totalProfit.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Profit Margin',
            '${profitMargin.toStringAsFixed(2)}%',
            Icons.percent,
            Colors.purple,
          ),
          const SizedBox(height: 30),
          Container(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalCost,
                    title: 'Cost\n\$${totalCost.toStringAsFixed(0)}',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    color: Colors.red,
                  ),
                  PieChartSectionData(
                    value: totalProfit,
                    title: 'Profit\n\$${totalProfit.toStringAsFixed(0)}',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    color: Colors.green,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF36454F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.edit),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = (_salesByDateRange!['orders'] as List?) ?? [];

    if (orders.isEmpty) {
      return const Text('No orders found');
    }

    return Column(
      children: orders.take(5).map<Widget>((order) {
        final orderId = order['orderId'] ?? 0;
        final orderPlaced = DateTime.parse(
            order['orderPlaced'] ?? DateTime.now().toIso8601String());
        final grandTotal = ((order['grandTotal'] ?? 0) as num).toDouble();
        final itemCount = order['itemCount'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFB87333),
              child: Text('#$orderId',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text('Order #$orderId'),
            subtitle: Text(
              '${DateFormat('MMM dd, hh:mm a').format(orderPlaced)} • $itemCount items',
            ),
            trailing: Text(
              '\$${grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductsList() {
    return Column(
      children: _topSellingProducts.map<Widget>((product) {
        final name = product['productName'] ?? 'Unknown';
        final quantity = product['totalQuantitySold'] ?? 0;
        final revenue = ((product['totalRevenue'] ?? 0) as num).toDouble();
        final unitPrice = ((product['unitPrice'] ?? 0) as num).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(name),
            subtitle: Text(
                '$quantity units sold • \$${unitPrice.toStringAsFixed(2)}/unit'),
            trailing: Text(
              '\$${revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'visa':
      case 'credit card':
        return Colors.blue;
      case 'debit card':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'visa':
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
