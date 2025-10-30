import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:visionpos/utils/pdf_service.dart';
import 'package:intl/intl.dart';

class EnhancedDashboard extends StatefulWidget {
  const EnhancedDashboard({super.key});

  @override
  State<EnhancedDashboard> createState() => _EnhancedDashboardState();
}

class _EnhancedDashboardState extends State<EnhancedDashboard> {
  final ApiHandler _apiHandler = ApiHandler();
  int? _orgId;
  bool _isLoading = false;

  // Dashboard data
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _quickStats;
  List<Map<String, dynamic>> _salesTrend = [];
  List<Map<String, dynamic>> _revenueByHour = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _paymentDistribution = [];
  List<Map<String, dynamic>> _monthlyComparison = [];
  Map<String, dynamic>? _lowStockAlert;

  @override
  void initState() {
    super.initState();
    _loadOrganizationId();
  }

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() => _orgId = orgId);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiHandler.getDashboardSummary(_orgId),
        _apiHandler.getQuickStats(_orgId),
        _apiHandler.getSalesTrend(30, _orgId),
        _apiHandler.getRevenueByHour(DateTime.now(), _orgId),
        _apiHandler.getTopProducts(5, _orgId),
        _apiHandler.getTopCategories(5, _orgId),
        _apiHandler.getRecentOrders(10, _orgId),
        _apiHandler.getPaymentMethodDistribution(null, null, _orgId),
        _apiHandler.getMonthlyComparison(6, _orgId),
        _apiHandler.getLowStockAlert(10, _orgId),
      ]);

      setState(() {
        _summary = results[0] as Map<String, dynamic>?;
        _quickStats = results[1] as Map<String, dynamic>?;
        _salesTrend = results[2] as List<Map<String, dynamic>>;
        _revenueByHour = results[3] as List<Map<String, dynamic>>;
        _topProducts = results[4] as List<Map<String, dynamic>>;
        _topCategories = results[5] as List<Map<String, dynamic>>;
        _recentOrders = results[6] as List<Map<String, dynamic>>;
        _paymentDistribution = results[7] as List<Map<String, dynamic>>;
        _monthlyComparison = results[8] as List<Map<String, dynamic>>;
        _lowStockAlert = results[9] as Map<String, dynamic>?;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdfBytes = await PdfService.generateDashboardReport(
        summary: _summary ?? {},
        salesTrend: _salesTrend,
        topProducts: _topProducts,
        topCategories: _topCategories,
        recentOrders: _recentOrders,
      );

      final fileName =
          'Dashboard_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = await PdfService.savePdf(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dashboard exported to: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF36454F),
        foregroundColor: Colors.white,
        actions: [
          // Export to PDF Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _exportToPDF,
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStatsSection(),
                    const SizedBox(height: 20),
                    _buildSalesTrendChart(),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Stack vertically on mobile, side by side on desktop
                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              _buildRevenueByHourChart(),
                              const SizedBox(height: 16),
                              _buildPaymentDistributionChart(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRevenueByHourChart()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPaymentDistributionChart()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTopProductsSection(),
                    const SizedBox(height: 20),
                    _buildTopCategoriesSection(),
                    const SizedBox(height: 20),
                    _buildMonthlyComparisonChart(),
                    const SizedBox(height: 20),
                    _buildLowStockAlert(),
                    const SizedBox(height: 20),
                    _buildRecentOrdersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStatsSection() {
    if (_quickStats == null) return const SizedBox();

    final todayOrders = _quickStats!['todayOrders'] ?? 0;
    final todaySales = ((_quickStats!['todaySales'] ?? 0) as num).toDouble();
    final totalProducts = _quickStats!['totalProducts'] ?? 0;
    final totalCustomers = _quickStats!['totalCustomers'] ?? 0;
    final lowStockAlerts = _quickStats!['lowStockAlerts'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate number of cards per row based on screen width
            int crossAxisCount = 5; // Default for desktop
            if (constraints.maxWidth < 600) {
              crossAxisCount = 1; // Mobile: 1 card per row
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 2; // Tablet portrait: 2 cards per row
            } else if (constraints.maxWidth < 1200) {
              crossAxisCount = 3; // Tablet landscape: 3 cards per row
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: constraints.maxWidth < 600 ? 3 : 1.5,
              children: [
                _buildMetricCard(
                  'Today\'s Orders',
                  todayOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Today\'s Sales',
                  '\$${todaySales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Total Products',
                  totalProducts.toString(),
                  Icons.inventory,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Total Customers',
                  totalCustomers.toString(),
                  Icons.people,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Low Stock Alerts',
                  lowStockAlerts.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    if (_salesTrend.isEmpty) return const SizedBox();

    final spots = _salesTrend.asMap().entries.map((entry) {
      final sales = ((entry.value['totalSales'] ?? 0) as num).toDouble();
      return FlSpot(entry.key.toDouble(), sales);
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '30-Day Sales Trend',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 600 ? 200.0 : 250.0;
                return SizedBox(
                  height: chartHeight,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < _salesTrend.length) {
                                final date = DateTime.parse(
                                    _salesTrend[value.toInt()]['date']);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFFB87333),
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFB87333).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByHourChart() {
    if (_revenueByHour.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Hourly Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 600 ? 180.0 : 200.0;
                return SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _revenueByHour.isNotEmpty
                          ? ((_revenueByHour
                                          .map((h) => h['totalRevenue'] ?? 0)
                                          .reduce((a, b) => a > b ? a : b) ??
                                      0) as num)
                                  .toDouble() *
                              1.2
                          : 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}h',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _revenueByHour.map((hour) {
                        final h = hour['hour'] ?? 0;
                        final revenue =
                            ((hour['totalRevenue'] ?? 0) as num).toDouble();
                        return BarChartGroupData(
                          x: h,
                          barRods: [
                            BarChartRodData(
                              toY: revenue,
                              color: const Color(0xFF36454F),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDistributionChart() {
    if (_paymentDistribution.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 600 ? 180.0 : 200.0;
                return SizedBox(
                  height: chartHeight,
                  child: PieChart(
                    PieChartData(
                      sections: _paymentDistribution.map((item) {
                        final percentage =
                            ((item['percentage'] ?? 0) as num).toDouble();
                        final method = item['paymentMethod'] ?? 'Unknown';
                        return PieChartSectionData(
                          value: percentage,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: _getColorForPaymentMethod(method),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ..._paymentDistribution.map((item) {
              final method = item['paymentMethod'] ?? 'Unknown';
              final count = item['count'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getColorForPaymentMethod(method),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$method ($count)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    if (_topProducts.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._topProducts.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final product = entry.value;
              final name = product['productName'] ?? 'Unknown';
              final quantity = product['totalQuantitySold'] ?? 0;
              final revenue =
                  ((product['totalRevenue'] ?? 0) as num).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRankColor(index).withOpacity(0.1),
                      _getRankColor(index).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _getRankColor(index).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$quantity units sold',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${revenue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _getRankColor(index),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesSection() {
    if (_topCategories.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 600 ? 200.0 : 250.0;
                return SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _topCategories.isNotEmpty
                          ? ((_topCategories.first['totalRevenue'] ?? 0) as num)
                                  .toDouble() *
                              1.2
                          : 100,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final category = _topCategories[group.x.toInt()];
                            return BarTooltipItem(
                              '${category['categoryName']}\n\$${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < _topCategories.length) {
                                final name = _topCategories[value.toInt()]
                                        ['categoryName'] ??
                                    '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name.length > 8
                                        ? '${name.substring(0, 8)}...'
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
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 50),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _topCategories.asMap().entries.map((entry) {
                        final revenue =
                            ((entry.value['totalRevenue'] ?? 0) as num)
                                .toDouble();
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: revenue,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFB87333),
                                  const Color(0xFFD4A574),
                                ],
                              ),
                              width: 30,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparisonChart() {
    if (_monthlyComparison.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '6-Month Sales Comparison',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 600 ? 200.0 : 250.0;
                return SizedBox(
                  height: chartHeight,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < _monthlyComparison.length) {
                                final monthName =
                                    _monthlyComparison[value.toInt()]
                                            ['monthName'] ??
                                        '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    monthName,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 50),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                              _monthlyComparison.asMap().entries.map((entry) {
                            final sales =
                                ((entry.value['totalSales'] ?? 0) as num)
                                    .toDouble();
                            return FlSpot(entry.key.toDouble(), sales);
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF36454F),
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF36454F).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    if (_lowStockAlert == null) return const SizedBox();

    final lowStockCount = _lowStockAlert!['lowStockCount'] ?? 0;
    final outOfStockCount = _lowStockAlert!['outOfStockCount'] ?? 0;

    if (lowStockCount == 0 && outOfStockCount == 0) return const SizedBox();

    return Card(
      elevation: 4,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory Alert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$lowStockCount products low in stock, $outOfStockCount out of stock',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to inventory page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    if (_recentOrders.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._recentOrders.take(5).map((order) {
              final orderId = order['orderId'] ?? 0;
              final orderPlaced = DateTime.parse(
                  order['orderPlaced'] ?? DateTime.now().toIso8601String());
              final grandTotal = ((order['grandTotal'] ?? 0) as num).toDouble();
              final itemCount = order['itemCount'] ?? 0;
              final paymentMethod = order['paymentMethod'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFB87333),
                    child: Text(
                      '#$orderId',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('Order #$orderId'),
                  subtitle: Text(
                    '${DateFormat('MMM dd, hh:mm a').format(orderPlaced)} • $itemCount items • $paymentMethod',
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
          ],
        ),
      ),
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return const Color(0xFF36454F);
    }
  }
}
