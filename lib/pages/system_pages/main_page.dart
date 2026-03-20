import 'dart:async';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/components/printer_setup_dialog.dart';
import 'package:visionpos/components/side_menu.dart';
import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/order_item_addition_dto.dart';
import 'package:visionpos/models/order_item_dto.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/kitchen_router.dart';
import 'package:visionpos/services/triple_printer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainPage extends StatefulWidget {
  final bool sidebarCollapsed;

  const MainPage({
    super.key,
    this.sidebarCollapsed = false,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final _barcodeFocus = FocusNode();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool isLoading = false;
  int? _orgId;

  Category? selectedCategory;
  List<Category> _allCategories = [];
  List<Category> _rootCategories = [];
  List<Category> _activeSubs = [];
  int? _selectedSubId;
  
  ApiHandler apiHandler = ApiHandler();
  TextEditingController searchController = TextEditingController();
  
  List<OrderItemDto> selectedItems = [];
  double tips = 0.0;
  int paymentMethod = 1; 
  bool isCash = true; 
  double discount = 0.0;
  Taxes? currentTaxes;
  String selectedTaxType = 'In-House'; 

  final Map<int, List<int>> _subIdsByRoot = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (!kIsWeb) {
      requestPermissions();
    }
    _fetchTaxes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await _loadOrganizationId();
    await Future.wait([
      _loadCategories(),
      _loadProducts(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    if (mounted) {
      setState(() {
        _orgId = orgId;
      });
    }
  }

  Future<void> _loadCategories() async {
    final cats = await apiHandler.getCategoriesForOrg(_orgId ?? 0);
    setState(() {
      _allCategories = cats;
      _rootCategories = cats.where((c) => c.mainCategoryId == null).toList();
      _buildCategoryIndices(cats);
    });
  }

  Future<void> _loadProducts() async {
    final prods = await apiHandler.getProductData();
    setState(() {
      _allProducts = prods;
      _filteredProducts = prods;
    });
  }

  void _buildCategoryIndices(List<Category> all) {
    _subIdsByRoot.clear();
    for (final c in all) {
      final parentId = c.mainCategoryId;
      if (parentId != null) {
        (_subIdsByRoot[parentId] ??= <int>[]).add(c.id);
      }
    }
  }

  void _onRootTap(Category? cat) {
    setState(() {
      selectedCategory = cat;
      _selectedSubId = null;
      if (cat == null) {
        _activeSubs = const [];
        _filteredProducts = _allProducts;
      } else {
        _activeSubs = _allCategories.where((c) => c.mainCategoryId == cat.id).toList();
        _filterProducts();
      }
    });
  }

  void _onSubTap(Category sub) {
    setState(() {
      _selectedSubId = sub.id;
      _filterProducts();
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        if (selectedCategory == null) return true;
        if (_selectedSubId != null) return p.categoryId == _selectedSubId;
        return p.categoryId == selectedCategory!.id || (_subIdsByRoot[selectedCategory!.id]?.contains(p.categoryId) ?? false);
      }).toList();
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((p) => p.productName.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
  }

  Future<void> _fetchTaxes() async {
    try {
      currentTaxes = await apiHandler.getTaxes();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching taxes: $e');
    }
  }

  void _addToOrder(Product product) async {
    AdditionsSelectionResult? selection;
    if (product.additions.isNotEmpty) {
      selection = await showAdditionsDialog(context, product);
      if (selection == null) return;
    }

    setState(() {
      final int index = selectedItems.indexWhere((it) => it.productId == product.productId && (it.notes ?? '') == (selection?.notes ?? ''));
      if (index != -1) {
        selectedItems[index] = selectedItems[index].updateQuantity(selectedItems[index].quantity + 1);
      } else {
        selectedItems.add(OrderItemDto(
          productId: product.productId,
          quantity: 1,
          price: product.sellingPrice,
          notes: selection?.notes,
          additions: selection?.additions ?? [],
        ));
      }
    });
  }

  Future<AdditionsSelectionResult?> showAdditionsDialog(BuildContext context, Product product) {
    final selected = <int>{};
    final notesController = TextEditingController();
    return showDialog<AdditionsSelectionResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(product.productName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...product.additions.map((d) => CheckboxListTile(
                  title: Text('${d.name} (+${d.priceIncrease})'),
                  value: selected.contains(d.domainDetailId),
                  onChanged: (v) => setStateDialog(() => v! ? selected.add(d.domainDetailId) : selected.remove(d.domainDetailId)),
                )),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, AdditionsSelectionResult(
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                additions: selected.map((id) => OrderItemAdditionDto(domainDetailId: id)).toList(),
              )),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return selectedItems.fold(0.0, (sum, it) => sum + (it.price * it.quantity)) * (1 - discount / 100);
  }

  double _calculateTaxes() {
    if (currentTaxes == null) return 0.0;
    final rate = selectedTaxType == 'In-House' ? currentTaxes!.inHouse : currentTaxes!.takeOut;
    return _calculateSubtotal() * (rate / 100);
  }

  double _calculateTotal() => _calculateSubtotal() + _calculateTaxes() + tips;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VisionPOS',
          style: TextStyle(
            fontSize: isMobile ? 16 : isTablet ? 18 : 20,
          ),
        ),
        leading: isMobile ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null,
        actions: [
          if (!isMobile && !kIsWeb) IconButton(icon: const Icon(Icons.print), onPressed: () => showPrinterSetupDialog(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitialData),
        ],
      ),
      drawer: isMobile ? Drawer(child: DrawerPage(isCollapsed: widget.sidebarCollapsed)) : null,
      body: Row(
        children: [
          Expanded(
            flex: isMobile ? 1 : isTablet ? 3 : 4,
            child: _buildMainContent(isMobile, isTablet),
          ),
          if (!isMobile)
            SizedBox(
              width: isTablet ? 280 : 320,
              child: _buildOrderSidebar(),
            ),
        ],
      ),
      floatingActionButton: isMobile ? FloatingActionButton(
        onPressed: () => _showOrderModal(context),
        child: const Icon(Icons.shopping_cart),
      ) : null,
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 8,
                horizontal: isMobile ? 10 : 12,
              ),
              isDense: true,
            ),
            onChanged: _searchProducts,
          ),
        ),
        _buildCategoryList(),
        if (_activeSubs.isNotEmpty) _buildSubCategoryList(),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: EdgeInsets.all(isMobile ? 4 : 6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : (isTablet ? 4 : 7),
                  childAspectRatio: isMobile ? 0.65 : isTablet ? 0.7 : 0.65,
                  crossAxisSpacing: isMobile ? 4 : 6,
                  mainAxisSpacing: isMobile ? 4 : 6,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (ctx, i) => _buildProductCard(_filteredProducts[i]),
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final categoryHeight = isMobile ? 40 : 42;
    
    return SizedBox(
      height: categoryHeight.toDouble(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _rootCategories.length + 1,
        itemBuilder: (ctx, i) {
          final cat = i == 0 ? null : _rootCategories[i - 1];
          final isSelected = selectedCategory?.id == cat?.id;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 3),
            child: ChoiceChip(
              label: Text(
                cat?.categoryName ?? 'All',
                style: TextStyle(fontSize: isMobile ? 10 : 10.5),
              ),
              selected: isSelected,
              onSelected: (_) => _onRootTap(cat),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final subHeight = isMobile ? 38 : 40;
    
    return Container(
      height: subHeight.toDouble(),
      color: Colors.grey[100],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeSubs.length,
        itemBuilder: (ctx, i) {
          final sub = _activeSubs[i];
          final isSelected = _selectedSubId == sub.id;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 3),
            child: ChoiceChip(
              label: Text(
                sub.categoryName,
                style: TextStyle(fontSize: isMobile ? 9.5 : 10.5),
              ),
              selected: isSelected,
              onSelected: (_) => _onSubTap(sub),
              backgroundColor: Colors.white,
              selectedColor: Colors.blue[100],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    const textPadding = 4.0;
    const double fontSize = 7.5;
    const double iconSize = 18.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _addToOrder(p),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Icon(Icons.fastfood, size: iconSize, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(textPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${p.sellingPrice.toStringAsFixed(2)} JOD',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize - 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Expanded(child: _buildOrderList()),
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.separated(
      itemCount: selectedItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = selectedItems[i];
        final prod = _getProductById(item.productId);
        return ListTile(
          title: Text(prod.productName),
          subtitle: Text('Qty: ${item.quantity}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateItemQty(i, -1)),
              Text('${item.quantity.toInt()}'),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateItemQty(i, 1)),
            ],
          ),
        );
      },
    );
  }

  void _updateItemQty(int index, double delta) {
    setState(() {
      final newQty = selectedItems[index].quantity + delta;
      if (newQty <= 0) {
        selectedItems.removeAt(index);
      } else {
        selectedItems[index] = selectedItems[index].updateQuantity(newQty);
      }
    });
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _calculateSubtotal()),
          _summaryRow('Tax', _calculateTaxes()),
          const Divider(height: 8),
          _summaryRow('Total', _calculateTotal(), isTotal: true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedItems.isEmpty ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB87333),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 13 : 11)),
          Text('${value.toStringAsFixed(2)} JOD', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 13 : 11)),
        ],
      ),
    );
  }

  void _submitOrder() async {
    if (_orgId == null) await _loadOrganizationId();
    if (_orgId == null) return;

    final order = OrderDto(
      organizationId: _orgId!,
      orderItems: selectedItems,
      grandTotal: _calculateTotal(),
      paymentMethod: paymentMethod,
      tips: tips,
    );

    if (await apiHandler.postOrder(order)) {
      if (!kIsWeb) {
        await _printReceipts(
          orderNumber: order.id.toString(),
          paymentMethod: paymentMethod == 1 ? 'CASH' : 'VISA',
          items: selectedItems,
          subtotal: _calculateSubtotal(),
          tax: _calculateTaxes(),
          tips: tips,
          total: _calculateTotal(),
        );
      }
      if (mounted) {
        setState(() => selectedItems.clear());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order submitted!')));
      }
    }
  }

  void _showOrderModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: _buildOrderSidebar(),
      ),
    );
  }

  Product _getProductById(int id) {
    return _allProducts.firstWhere((p) => p.productId == id, orElse: () => Product(productId: 0, organizationId: 0, categoryId: 0, productName: 'Unknown', sellingPrice: 0, purchasePrice: 0));
  }

  Future<bool> _printReceipts({required String orderNumber, required String paymentMethod, required List<OrderItemDto> items, required double subtotal, required double tax, required double tips, required double total}) async {
    if (kIsWeb) return false;
    try {
      final bt = BluetoothPrinterManager();
      await bt.load();
      final router = KitchenRouter(falafelCategoryIds: {2}, shawarmaSnacksCategoryIds: {3, 6, 7, 8, 9});
      final p = TriplePrinter(btManager: bt, router: router);
      await p.printAll({'orderNumber': orderNumber, 'items': items.map((it) => it.toJson()).toList(), 'grandTotal': total});
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdditionsSelectionResult {
  final String? notes;
  final List<OrderItemAdditionDto> additions;
  AdditionsSelectionResult({this.notes, this.additions = const []});
}
