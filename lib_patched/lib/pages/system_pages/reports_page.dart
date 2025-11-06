import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/pdf_service.dart';
import 'package:visionpos/utils/session_manager.dart';

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

  // Date filters (inclusive start, exclusive end for convenience)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  // Data holders
  Map<String, dynamic>? _salesByDateRange; // summary map
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _salesByPaymentMethod = [];
  List<Map<String, dynamic>> _salesByCategory = [];
  Map<String, dynamic>? _inventoryStatus; // may contain counts or lists
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
    if (!mounted) return;
    setState(() => _orgId = orgId);
    if (_orgId != null) _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (_orgId == null) return;
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

      // Defensive casts to expected shapes
      _salesByDateRange = (results[0] as Map).cast<String, dynamic>();
      _topSellingProducts = (results[1] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      _salesByPaymentMethod = (results[2] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      _salesByCategory = (results[3] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      _inventoryStatus = (results[4] as Map).cast<String, dynamic>();
      _profitAnalysis = (results[5] as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('Failed to load reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final initialDateRange = DateTimeRange(start: _startDate, end: _endDate);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
    );
    if (picked != null) {
      setState(() {
        _startDate =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        // make end exclusive by adding one day
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day)
            .add(const Duration(days: 1));
      });
      _loadReportData();
    }
  }

  /// Writes [data] to a temp file, previews it with pdfx, and offers share/print.
  Future<void> _showPdf(Uint8List data) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(data, flush: true);

    final controller = PdfController(document: PdfDocument.openFile(path));

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 900,
          height: 1000,
          child: Column(
            children: [
              // Header with actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Preview',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Share / Print',
                        icon: const Icon(Icons.ios_share),
                        onPressed: () async {
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Report',
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: PdfView(
                  controller: controller,
                  builders: PdfViewBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, error) => Center(
                      child: Text('Failed to render PDF:\n$error'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
  }

  void _showFullPdfPreview() async {
    if (_salesByDateRange == null) return;

    final pdfData = await PdfService.generateDashboardReport(
      summary: _salesByDateRange!,
      salesTrend: _salesByPaymentMethod,
      topProducts: _topSellingProducts,
      topCategories: _salesByCategory,
      recentOrders: const [],
    );

    await _showPdf(pdfData);
  }

  Widget _buildExportButton(
    String label,
    Future<Uint8List> Function() onBuild,
  ) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(label),
      onPressed: () async {
        final data = await onBuild();
        await _showPdf(data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yMMMd');
    final dateLabel =
        '${df.format(_startDate)} — ${df.format(_endDate.subtract(const Duration(days: 1)))}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, color: Colors.white),
            label: Text(dateLabel, style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Reload',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _showFullPdfPreview,
            tooltip: 'Export All Reports as PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Top Products'),
            Tab(text: 'Payments'),
            Tab(text: 'Categories'),
            Tab(text: 'Inventory'),
            Tab(text: 'Profit'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSalesReportTab(),
                _buildTopProductsTab(),
                _buildPaymentTab(),
                _buildCategoryTab(),
                _buildInventoryTab(),
                _buildProfitTab(),
              ],
            ),
    );
  }

  // ——— Tabs ———

  Widget _buildSalesReportTab() {
    final totalSales = _salesByDateRange?['totalSales'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales Summary',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: _salesByDateRange ?? const {},
                  salesTrend: _salesByPaymentMethod,
                  topProducts: const [],
                  topCategories: const [],
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ListTile(
                title: const Text('Total Sales'),
                trailing: Text(totalSales?.toString() ?? '-'),
              ),
              const Divider(),
              ..._salesByPaymentMethod.map(
                (m) => ListTile(
                  title: Text(m['method']?.toString() ?? ''),
                  trailing: Text(m['amount']?.toString() ?? ''),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Selling Products',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: const {},
                  salesTrend: const [],
                  topProducts: _topSellingProducts,
                  topCategories: const [],
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _topSellingProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _topSellingProducts[index];
              return ListTile(
                leading: Text('${index + 1}'),
                title: Text(item['product']?.toString() ?? '—'),
                trailing: Text(item['sales']?.toString() ?? '0'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales by Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: const {},
                  salesTrend: _salesByPaymentMethod,
                  topProducts: const [],
                  topCategories: const [],
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _salesByPaymentMethod.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _salesByPaymentMethod[index];
              return ListTile(
                title: Text(item['method']?.toString() ?? '—'),
                trailing: Text(item['amount']?.toString() ?? '0'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales by Category',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: const {},
                  salesTrend: const [],
                  topProducts: const [],
                  topCategories: _salesByCategory,
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _salesByCategory.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _salesByCategory[index];
              return ListTile(
                title: Text(item['category']?.toString() ?? '—'),
                trailing: Text(item['amount']?.toString() ?? '0'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab() {
    final totalItems = _inventoryStatus?['totalItems']?.toString() ?? '—';
    final lowStock = _inventoryStatus?['lowStock']?.toString() ?? '—';
    final items =
        (_inventoryStatus?['items'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inventory Status',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: _inventoryStatus ?? const {},
                  salesTrend: const [],
                  topProducts: const [],
                  topCategories: const [],
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                title: const Text('Total Items'),
                trailing: Text(totalItems),
              ),
              ListTile(
                title: const Text('Low Stock'),
                trailing: Text(lowStock),
              ),
              const Divider(),
              ...items.map(
                (e) => ListTile(
                  title: Text(e['name']?.toString() ?? '—'),
                  subtitle: Text('Qty: ${e['quantity']?.toString() ?? '0'}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitTab() {
    final profit = _profitAnalysis?['profit']?.toString() ?? '—';
    final margin = _profitAnalysis?['margin']?.toString() ?? '—';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profit Analysis',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              _buildExportButton(
                'Export PDF',
                () => PdfService.generateDashboardReport(
                  summary: _profitAnalysis ?? const {},
                  salesTrend: const [],
                  topProducts: const [],
                  topCategories: const [],
                  recentOrders: const [],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ListTile(title: const Text('Profit'), trailing: Text(profit)),
              ListTile(title: const Text('Margin'), trailing: Text(margin)),
            ],
          ),
        ),
      ],
    );
  }
}
