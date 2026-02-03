import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';

import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/components/printer_setup_dialog.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/order_item_addition_dto.dart';
import 'package:visionpos/models/order_item_dto.dart';
import 'package:visionpos/models/promocodes_model.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/pages/add_pages/add_category.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/services/arabic_font_loader.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/receipt_builder.dart';
import 'package:visionpos/services/kitchen_router.dart';
import 'package:visionpos/services/triple_printer.dart';
import 'package:flutter/foundation.dart' show setEquals, listEquals;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  String _barcodeBuffer = '';
  late List<dynamic> data = [];
  Product? selectedProduct;
  List<Product> products = [];
  bool isLoading = false;
  List<Product> searchResults = [];
  Product? productSearch;
  OverlayEntry? overlayEntry;
  int userId = 1;
  int ordeId = 0;
  int? _orgId;
  List<Category> _categories = [];

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    if (mounted) setState(() => _orgId = orgId);
  }

  Future<void> _loadCategories() async {
    final org = await SessionManager.getOrganizationId();
    final cats = await ApiHandler().getCategoriesForOrg(org ?? 0);
    if (mounted) {
      setState(() {
        _all = cats;
        _rootCategories = cats.where((c) => c.mainCategoryId == null).toList();
        _buildCategoryIndices(cats);
      });
    }
  }

  Category? selectedCategory;
  List<Category> _all = [];
  List<Category> _rootCategories = [];
  List<Category> _activeSubs = [];
  int? _selectedSubId;
  late final ScrollController _subsCtrl;
  Map<int, String> get _catNameById => {
        for (final c in _all) c.id: c.categoryName,
      };

  ApiHandler apiHandler = ApiHandler();
  TextEditingController searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  
  List<OrderItemDto> selectedItems = [];
  Map<int, double> productPrices = {};
  double tips = 0.0;
  int paymentMethod = 1; 
  bool isCash = true; 
  double switchScale = 0.8;

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? get selectedRootId => selectedCategory?.id;

  final TextEditingController promoCodeController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  OverlayEntry? overlayEntrypromo;
  final LayerLink _layerLinkpromo = LayerLink();
  List<Promocodes> searchResultspromo = [];
  Promocodes? selectedPromoCode;
  double discount = 0.0;
  int orderCount = 0;
  
  Taxes? currentTaxes;
  String selectedTaxType = 'In-House'; 
  
  double xOffset = 0;
  double yOffset = 0;
  bool isDrawerOpen = false;
  
  bool connected = false;
  List<BluetoothDevice> items = [];
  
  final Map<int, Category> _catById = {};
  final Map<int, List<int>> _subIdsByRoot = {};

  void _buildCategoryIndices(List<Category> all) {
    _catById.clear();
    _subIdsByRoot.clear();

    for (final c in all) {
      _catById[c.id] = c;
      final parentId = _toInt(c.mainCategoryId);
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
      } else {
        _activeSubs = _all.where((c) => _toInt(c.mainCategoryId) == cat.id).toList();
      }
    });
  }

  void _onSubTap(Category sub) {
    setState(() => _selectedSubId = sub.id);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> getBluetoothDevices() async {
    final List<BluetoothDevice> listResult = await _bluetooth.getBondedDevices();
    if (mounted) {
      setState(() {
        items = listResult;
      });
    }
  }

  Future<void> connectToPrinter(String macAddress) async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      final device = devices.firstWhere((d) => d.address == macAddress);
      await _bluetooth.connect(device).timeout(const Duration(seconds: 5));
      if (mounted) setState(() => connected = true);
    } catch (e) {
      if (mounted) setState(() => connected = false);
    }
  }

  Future<void> _printReceipt() async {
    try {
      if (selectedItems.isEmpty) return;

      final btConnected = await _bluetooth.isConnected;
      if (!(connected == true && btConnected == true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer not connected')),
          );
        }
        return;
      }

      final productsById = {for (final p in data.cast<Product>()) p.productId: p};

      final List<Map<String, dynamic>> itemsForPrint = selectedItems.map((it) {
        final prod = productsById[it.productId];
        final double basePrice = (it.price != 0.0 ? it.price : (prod?.sellingPrice ?? 0.0));
        return {
          'productId': it.productId,
          'productName': (prod?.productName ?? '').toString().trim(),
          'quantity': it.quantity,
          'price': basePrice,
          'totalAfterTax': basePrice * it.quantity,
          'additions': it.additions.map((a) => {'domainDetailId': a.domainDetailId}).toList(),
          'notes': it.notes ?? '',
        };
      }).toList();

      final builder = await ReceiptBuilder.create(paper: PaperSize.mm80);
      final double sub = _calculateSubtotal(selectedItems);
      final double tax = _calculateTaxes(selectedItems);
      final double grand = _calculateTotal(selectedItems);

      final Map<String, dynamic> orderMap = {
        'data': {
          'orderNumber': (orderCount).toString().padLeft(4, '0'),
          'paymentMethod': paymentMethod,
          'orderItems': itemsForPrint,
          'totalAfterDiscount': sub,
          'taxTotal': tax,
          'tips': tips,
          'grandTotal': grand,
        },
        'items': itemsForPrint,
      };

      final List<int> bytes = await builder.printCustomer(
        orderMap,
        items: itemsForPrint,
        orderNumber: (orderCount).toString().padLeft(4, '0'),
        storeName: 'VisionPOS',
        resolve: (int id) => _getProductById(id),
      );

      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  void _togglePaymentMethod(bool value) {
    setState(() {
      isCash = value;
      paymentMethod = isCash ? 1 : 2;
    });
  }

  Future<void> _fetchTaxes() async {
    try {
      final taxes = await apiHandler.getTaxes();
      if (mounted) setState(() => currentTaxes = taxes);
    } catch (e) {
      debugPrint('Error fetching taxes: $e');
    }
  }

  void _removeProductFromOrder(int index) {
    setState(() {
      int productId = selectedItems[index].productId;
      selectedItems[index] = selectedItems[index].updateQuantity(selectedItems[index].quantity - 1);
      if (selectedItems[index].quantity <= 0) {
        productPrices.remove(productId);
        selectedItems.removeAt(index);
      }
    });
  }

  void _addQuantity(int index) {
    setState(() {
      selectedItems[index] = selectedItems[index].updateQuantity(selectedItems[index].quantity + 1);
    });
  }

  double _getProductPrice(int productId) => productPrices[productId] ?? 0.0;

  Future<void> addToOrder(Product product) async {
    AdditionsSelectionResult? selection;
    if (product.additions.isNotEmpty) {
      selection = await showAdditionsDialog(context, product);
      if (selection == null) return;
    }

    setState(() {
      final String? newNotes = selection?.notes;
      final newAdditions = selection?.additions ?? const <OrderItemAdditionDto>[];

      final int index = selectedItems.indexWhere((item) {
        if (item.productId != product.productId) return false;
        if ((item.notes ?? '').trim() != (newNotes ?? '').trim()) return false;
        final existingAddIds = item.additions.map((a) => a.domainDetailId).toSet();
        final targetAddIds = newAdditions.map((a) => a.domainDetailId).toSet();
        return setEquals(existingAddIds, targetAddIds);
      });

      if (index != -1) {
        selectedItems[index] = selectedItems[index].updateQuantity(selectedItems[index].quantity + 1);
      } else {
        selectedItems.add(OrderItemDto(
          productId: product.productId,
          quantity: 1,
          price: product.sellingPrice,
          notes: newNotes,
          additions: newAdditions,
        ));
      }
      productPrices[product.productId] = product.sellingPrice;
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

  double _calculateSubtotal(List<OrderItemDto> items) {
    double sub = items.fold(0.0, (sum, it) {
      double adds = it.additions.fold(0.0, (s, a) {
        final product = _getProductById(it.productId);
        final match = product.additions.where((d) => d.domainDetailId == a.domainDetailId);
        return s + (match.isNotEmpty ? match.first.priceIncrease : 0.0);
      });
      return sum + ((it.price + adds) * it.quantity);
    });
    return sub * (1 - discount / 100);
  }

  double _calculateTaxes(List<OrderItemDto> items) {
    if (currentTaxes == null) return 0.0;
    final rate = selectedTaxType == 'In-House' ? currentTaxes!.inHouse : currentTaxes!.takeOut;
    return _calculateSubtotal(items) * (rate / 100);
  }

  double _calculateTotal(List<OrderItemDto> items) => _calculateSubtotal(items) + _calculateTaxes(items) + tips;

  void submitOrder() async {
    if (_orgId == null) await _loadOrganizationId();
    if (_orgId == null) return;

    final order = OrderDto(
      organizationId: _orgId!,
      orderItems: selectedItems,
      grandTotal: _calculateTotal(selectedItems),
      paymentMethod: paymentMethod,
      tips: tips,
    );

    if (await ApiHandler().postOrder(order)) {
      await _printReceipts(
        orderNumber: order.id.toString(),
        paymentMethod: paymentMethod == 1 ? 'CASH' : 'VISA',
        items: selectedItems,
        subtotal: _calculateSubtotal(selectedItems),
        tax: _calculateTaxes(selectedItems),
        tips: tips,
        total: _calculateTotal(selectedItems),
      );
      if (mounted) {
        setState(() => selectedItems.clear());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order submitted!')));
      }
    }
  }

  void getData() async {
    final fetched = await apiHandler.getProductData();
    if (mounted) setState(() => data = fetched);
  }

  @override
  void initState() {
    super.initState();
    _subsCtrl = ScrollController();
    getData();
    _loadOrganizationId().then((_) => _loadCategories());
    requestPermissions();
    _fetchTaxes();
    getBluetoothDevices();
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_barcodeFocus));
  }

  void toggleMenu() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
      xOffset = isDrawerOpen ? 290 : 0;
      yOffset = isDrawerOpen ? 80 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.translationValues(xOffset, yOffset, 0)..scale(isDrawerOpen ? 0.85 : 1.0),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VisionPOS'),
          leading: IconButton(icon: Icon(isDrawerOpen ? Icons.arrow_back_ios : Icons.menu), onPressed: toggleMenu),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () { getData(); _loadCategories(); }),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Categories
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _rootCategories.length + 1,
                      itemBuilder: (ctx, i) {
                        final cat = i == 0 ? null : _rootCategories[i - 1];
                        return ActionChip(
                          label: Text(cat?.categoryName ?? 'All'),
                          onPressed: () => _onRootTap(cat),
                        );
                      },
                    ),
                  ),
                  // Subcategories
                  if (_activeSubs.isNotEmpty)
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeSubs.length,
                        itemBuilder: (ctx, i) => ActionChip(
                          label: Text(_activeSubs[i].categoryName),
                          onPressed: () => _onSubTap(_activeSubs[i]),
                        ),
                      ),
                    ),
                  // Products
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      itemCount: data.where((p) {
                        if (selectedCategory == null) return true;
                        if (_selectedSubId != null) return p.categoryId == _selectedSubId;
                        return p.categoryId == selectedCategory!.id || (_subIdsByRoot[selectedCategory!.id]?.contains(p.categoryId) ?? false);
                      }).length,
                      itemBuilder: (ctx, i) {
                        final filtered = data.where((p) {
                          if (selectedCategory == null) return true;
                          if (_selectedSubId != null) return p.categoryId == _selectedSubId;
                          return p.categoryId == selectedCategory!.id || (_subIdsByRoot[selectedCategory!.id]?.contains(p.categoryId) ?? false);
                        }).toList();
                        final p = filtered[i];
                        return Card(
                          child: InkWell(
                            onTap: () => addToOrder(p),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Text(p.productName), Text('${p.sellingPrice} JOD')],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Order Side
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedItems.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(_getProductById(selectedItems[i].productId).productName),
                        subtitle: Text('Qty: ${selectedItems[i].quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove), onPressed: () => _removeProductFromOrder(i)),
                            IconButton(icon: const Icon(Icons.add), onPressed: () => _addQuantity(i)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Text('Total: ${_calculateTotal(selectedItems).toStringAsFixed(2)} JOD'),
                  ElevatedButton(onPressed: submitOrder, child: const Text('Checkout')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Product _getProductById(int id) {
    return data.cast<Product>().firstWhere((p) => p.productId == id, orElse: () => Product(productId: 0, organizationId: 0, categoryId: 0, productName: 'Unknown', sellingPrice: 0, purchasePrice: 0));
  }

  Future<bool> _printReceipts({required String orderNumber, required String paymentMethod, required List<OrderItemDto> items, required double subtotal, required double tax, required double tips, required double total}) async {
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
