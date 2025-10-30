import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  // Color scheme for VisionPOS
  static final PdfColor primaryColor = PdfColor.fromHex('#B87333'); // Copper
  static final PdfColor secondaryColor =
      PdfColor.fromHex('#36454F'); // Charcoal
  static final PdfColor accentColor = PdfColor.fromHex('#FFD700'); // Gold
  static final PdfColor lightGray = PdfColor.fromHex('#F5F5F5');

  /// Generate Dashboard Report PDF
  static Future<Uint8List> generateDashboardReport({
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> salesTrend,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> topCategories,
    required List<Map<String, dynamic>> recentOrders,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final time = DateFormat('hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Dashboard Report', date, time),
          pw.SizedBox(height: 20),

          // Summary Cards
          _buildSummarySection(summary),
          pw.SizedBox(height: 30),

          // Sales Trend Chart
          if (salesTrend.isNotEmpty) ...[
            _buildSectionTitle('30-Day Sales Trend'),
            pw.SizedBox(height: 10),
            _buildSalesTrendChart(salesTrend),
            pw.SizedBox(height: 30),
          ],

          // Top Products
          if (topProducts.isNotEmpty) ...[
            _buildSectionTitle('Top Selling Products'),
            pw.SizedBox(height: 10),
            _buildTopProductsTable(topProducts),
            pw.SizedBox(height: 30),
          ],

          // Top Categories
          if (topCategories.isNotEmpty) ...[
            _buildSectionTitle('Top Categories'),
            pw.SizedBox(height: 10),
            _buildTopCategoriesTable(topCategories),
            pw.SizedBox(height: 30),
          ],

          // Recent Orders
          if (recentOrders.isNotEmpty) ...[
            _buildSectionTitle('Recent Orders'),
            pw.SizedBox(height: 10),
            _buildRecentOrdersTable(recentOrders),
          ],

          // Footer
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Sales Report PDF
  static Future<Uint8List> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> dailySales,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> paymentMethods,
    required double totalRevenue,
    required int totalOrders,
  }) async {
    final pdf = pw.Document();
    final dateRange =
        '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Sales Report', dateRange,
              DateFormat('hh:mm a').format(DateTime.now())),
          pw.SizedBox(height: 20),

          // Summary Cards
          _buildSalesReportSummary(
              totalRevenue, totalOrders, dailySales.length),
          pw.SizedBox(height: 30),

          // Daily Sales Table
          if (dailySales.isNotEmpty) ...[
            _buildSectionTitle('Daily Sales Breakdown'),
            pw.SizedBox(height: 10),
            _buildDailySalesTable(dailySales),
            pw.SizedBox(height: 30),
          ],

          // Top Products
          if (topProducts.isNotEmpty) ...[
            _buildSectionTitle('Best Selling Products'),
            pw.SizedBox(height: 10),
            _buildTopProductsTable(topProducts),
            pw.SizedBox(height: 30),
          ],

          // Payment Methods
          if (paymentMethods.isNotEmpty) ...[
            _buildSectionTitle('Payment Methods Distribution'),
            pw.SizedBox(height: 10),
            _buildPaymentMethodsTable(paymentMethods),
          ],

          // Footer
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Inventory Report PDF
  static Future<Uint8List> generateInventoryReport({
    required List<Map<String, dynamic>> inventory,
    required List<Map<String, dynamic>> lowStock,
    required int totalProducts,
    required double totalValue,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Inventory Report', date,
              DateFormat('hh:mm a').format(DateTime.now())),
          pw.SizedBox(height: 20),

          // Summary
          _buildInventorySummary(totalProducts, totalValue, lowStock.length),
          pw.SizedBox(height: 30),

          // Low Stock Alert
          if (lowStock.isNotEmpty) ...[
            _buildSectionTitle('⚠️ Low Stock Alert', isWarning: true),
            pw.SizedBox(height: 10),
            _buildLowStockTable(lowStock),
            pw.SizedBox(height: 30),
          ],

          // Full Inventory
          if (inventory.isNotEmpty) ...[
            _buildSectionTitle('Complete Inventory'),
            pw.SizedBox(height: 10),
            _buildInventoryTable(inventory),
          ],

          // Footer
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Profit Analysis Report PDF
  static Future<Uint8List> generateProfitReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> profitData,
    required double totalRevenue,
    required double totalCost,
    required double totalProfit,
    required double profitMargin,
  }) async {
    final pdf = pw.Document();
    final dateRange =
        '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Profit Analysis Report', dateRange,
              DateFormat('hh:mm a').format(DateTime.now())),
          pw.SizedBox(height: 20),

          // Summary
          _buildProfitSummary(
              totalRevenue, totalCost, totalProfit, profitMargin),
          pw.SizedBox(height: 30),

          // Profit Breakdown
          if (profitData.isNotEmpty) ...[
            _buildSectionTitle('Detailed Profit Breakdown'),
            pw.SizedBox(height: 10),
            _buildProfitTable(profitData),
          ],

          // Footer
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // ==================== BUILDING BLOCKS ====================

  /// Build PDF Header with Logo and Title
  static pw.Widget _buildHeader(String title, String date, String time) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [secondaryColor, primaryColor],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VisionPOS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColor.fromInt(0xB3FFFFFF), // White with 70% opacity
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                time,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xB3FFFFFF), // White with 70% opacity
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Section Title
  static pw.Widget _buildSectionTitle(String title, {bool isWarning = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: pw.BoxDecoration(
        color: isWarning ? PdfColor.fromHex('#FFF3CD') : lightGray,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(
          color: isWarning ? PdfColor.fromHex('#FFC107') : primaryColor,
          width: 2,
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: isWarning ? PdfColor.fromHex('#856404') : secondaryColor,
        ),
      ),
    );
  }

  /// Build Summary Section
  static pw.Widget _buildSummarySection(Map<String, dynamic> summary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryCard(
            'Total Sales',
            '\$${summary['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
            primaryColor),
        _buildSummaryCard(
            'Total Orders', '${summary['totalOrders'] ?? 0}', secondaryColor),
        _buildSummaryCard(
            'Avg Order',
            '\$${summary['averageOrderValue']?.toStringAsFixed(2) ?? '0.00'}',
            accentColor),
      ],
    );
  }

  /// Build Summary Card
  static pw.Widget _buildSummaryCard(
      String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: pw.EdgeInsets.symmetric(horizontal: 5),
        padding: pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(10),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 5,
              offset: PdfPoint(0, 3),
            ),
          ],
        ),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromInt(0xB3FFFFFF), // White with 70% opacity
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Sales Trend Chart (simplified as table)
  static pw.Widget _buildSalesTrendChart(
      List<Map<String, dynamic>> salesTrend) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: secondaryColor),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Sales', isHeader: true),
            _buildTableCell('Orders', isHeader: true),
          ],
        ),
        // Data rows
        ...salesTrend.take(10).map((item) {
          final date = DateTime.parse(item['date']);
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('MMM dd').format(date)),
              _buildTableCell(
                  '\$${(item['totalSales'] ?? 0).toStringAsFixed(2)}'),
              _buildTableCell('${item['orderCount'] ?? 0}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Top Products Table
  static pw.Widget _buildTopProductsTable(List<Map<String, dynamic>> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: pw.FixedColumnWidth(30),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Qty Sold', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
          ],
        ),
        // Data rows
        ...products.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : lightGray,
            ),
            children: [
              _buildTableCell('$index'),
              _buildTableCell(item['productName'] ?? 'Unknown'),
              _buildTableCell('${item['totalQuantitySold'] ?? 0}'),
              _buildTableCell(
                  '\$${(item['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Top Categories Table
  static pw.Widget _buildTopCategoriesTable(
      List<Map<String, dynamic>> categories) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: secondaryColor),
          children: [
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Products Sold', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
          ],
        ),
        // Data rows
        ...categories.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item['categoryName'] ?? 'Unknown'),
              _buildTableCell('${item['totalQuantitySold'] ?? 0}'),
              _buildTableCell(
                  '\$${(item['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Recent Orders Table
  static pw.Widget _buildRecentOrdersTable(List<Map<String, dynamic>> orders) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _buildTableCell('Order ID',
                isHeader: true, headerColor: secondaryColor),
            _buildTableCell('Date',
                isHeader: true, headerColor: secondaryColor),
            _buildTableCell('Items',
                isHeader: true, headerColor: secondaryColor),
            _buildTableCell('Total',
                isHeader: true, headerColor: secondaryColor),
          ],
        ),
        // Data rows
        ...orders.take(10).map((item) {
          final date = DateTime.parse(item['orderPlaced']);
          return pw.TableRow(
            children: [
              _buildTableCell('#${item['orderId']}'),
              _buildTableCell(DateFormat('MMM dd, hh:mm a').format(date)),
              _buildTableCell('${item['itemCount'] ?? 0}'),
              _buildTableCell(
                  '\$${(item['grandTotal'] ?? 0).toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Daily Sales Table
  static pw.Widget _buildDailySalesTable(
      List<Map<String, dynamic>> dailySales) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Orders', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
            _buildTableCell('Avg Order', isHeader: true),
          ],
        ),
        // Data rows
        ...dailySales.map((item) {
          final date = DateTime.parse(item['date']);
          final revenue = (item['totalRevenue'] ?? 0).toDouble();
          final orders = item['totalOrders'] ?? 0;
          final avg = orders > 0 ? revenue / orders : 0.0;
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('MMM dd, yyyy').format(date)),
              _buildTableCell('$orders'),
              _buildTableCell('\$${revenue.toStringAsFixed(2)}'),
              _buildTableCell('\$${avg.toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Payment Methods Table
  static pw.Widget _buildPaymentMethodsTable(
      List<Map<String, dynamic>> methods) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: secondaryColor),
          children: [
            _buildTableCell('Method', isHeader: true),
            _buildTableCell('Orders', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('Percentage', isHeader: true),
          ],
        ),
        // Data rows
        ...methods.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item['paymentMethod'] ?? 'Unknown'),
              _buildTableCell('${item['totalOrders'] ?? 0}'),
              _buildTableCell(
                  '\$${(item['totalAmount'] ?? 0).toStringAsFixed(2)}'),
              _buildTableCell(
                  '${(item['percentage'] ?? 0).toStringAsFixed(1)}%'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Sales Report Summary
  static pw.Widget _buildSalesReportSummary(
      double totalRevenue, int totalOrders, int days) {
    final avgPerDay = days > 0 ? totalRevenue / days : 0.0;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryCard('Total Revenue',
            '\$${totalRevenue.toStringAsFixed(2)}', primaryColor),
        _buildSummaryCard('Total Orders', '$totalOrders', secondaryColor),
        _buildSummaryCard(
            'Avg/Day', '\$${avgPerDay.toStringAsFixed(2)}', accentColor),
      ],
    );
  }

  /// Build Inventory Summary
  static pw.Widget _buildInventorySummary(
      int totalProducts, double totalValue, int lowStock) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryCard('Total Products', '$totalProducts', secondaryColor),
        _buildSummaryCard(
            'Total Value', '\$${totalValue.toStringAsFixed(2)}', primaryColor),
        _buildSummaryCard(
            'Low Stock Items', '$lowStock', PdfColor.fromHex('#DC3545')),
      ],
    );
  }

  /// Build Low Stock Table
  static pw.Widget _buildLowStockTable(List<Map<String, dynamic>> lowStock) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#DC3545')),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Current Stock', isHeader: true),
            _buildTableCell('Min Required', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...lowStock.map((item) {
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF3CD')),
            children: [
              _buildTableCell(item['productName'] ?? 'Unknown'),
              _buildTableCell('${item['currentStock'] ?? 0}'),
              _buildTableCell('${item['minRequired'] ?? 0}'),
              _buildTableCell('⚠️ LOW'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Inventory Table
  static pw.Widget _buildInventoryTable(List<Map<String, dynamic>> inventory) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Stock', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Total Value', isHeader: true),
          ],
        ),
        // Data rows
        ...inventory.take(50).map((item) {
          final stock = item['stock'] ?? 0;
          final price = (item['unitPrice'] ?? 0).toDouble();
          final value = stock * price;
          return pw.TableRow(
            children: [
              _buildTableCell(item['productName'] ?? 'Unknown'),
              _buildTableCell('$stock'),
              _buildTableCell('\$${price.toStringAsFixed(2)}'),
              _buildTableCell('\$${value.toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Profit Summary
  static pw.Widget _buildProfitSummary(
      double revenue, double cost, double profit, double margin) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryColor, accentColor],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Revenue',
                  style: pw.TextStyle(
                      color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text('\$${revenue.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Cost',
                  style: pw.TextStyle(
                      color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text('\$${cost.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Profit',
                  style: pw.TextStyle(
                      color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text('\$${profit.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Margin',
                  style: pw.TextStyle(
                      color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text('${margin.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Profit Table
  static pw.Widget _buildProfitTable(List<Map<String, dynamic>> profitData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
            _buildTableCell('Cost', isHeader: true),
            _buildTableCell('Profit', isHeader: true),
            _buildTableCell('Margin', isHeader: true),
          ],
        ),
        // Data rows
        ...profitData.map((item) {
          final revenue = (item['revenue'] ?? 0).toDouble();
          final cost = (item['cost'] ?? 0).toDouble();
          final profit = revenue - cost;
          final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;
          return pw.TableRow(
            children: [
              _buildTableCell(item['productName'] ?? 'Unknown'),
              _buildTableCell('\$${revenue.toStringAsFixed(2)}'),
              _buildTableCell('\$${cost.toStringAsFixed(2)}'),
              _buildTableCell('\$${profit.toStringAsFixed(2)}'),
              _buildTableCell('${margin.toStringAsFixed(1)}%'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build Table Cell
  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? headerColor}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? (headerColor ?? PdfColors.white) : secondaryColor,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Build Footer
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by VisionPOS',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Save PDF to device
  static Future<String> savePdf(Uint8List pdfBytes, String fileName) async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}
