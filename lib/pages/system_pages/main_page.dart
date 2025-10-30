import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/promoCodes_model.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/pages/add_pages/add_category.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:visionpos/components/quick_api_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
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
  int? _orgId = 0;
  // ignore: unused_field
  List<Category> _categories = [];
  bool _hasBeenInitialized = false;

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() => _orgId = orgId);
  }

  Future<void> _loadCategories() async {
    if (_orgId != null) {
      final cats = await ApiHandler().getLeafCategoriesByOrg(_orgId!);
      setState(() => _categories = cats);
      print(
          '📂 Main page loaded ${cats.length} categories for organization $_orgId');
    } else {
      print('⚠️ Organization ID not available, skipping category load');
    }
  }

  // Method to reload all data when returning to main page
  Future<void> _reloadAllData() async {
    print('🔄 Reloading all data on main page...');
    setState(() {
      isLoading = true;
    });

    try {
      // Reload products data
      getData();

      // Reload organization ID and then categories
      await _loadOrganizationId();
      if (_orgId != null) {
        await _loadCategories();
        await categoryData();
      }

      // Reload taxes and promo codes
      await _fetchTaxes();
      await apiHandler.fetchPromoCodes();

      print('✅ Data reload completed');
    } catch (e) {
      print('❌ Error reloading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - reload data
      print('📱 App resumed, reloading data...');
      _reloadAllData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload after the initial setup is complete
    if (_hasBeenInitialized) {
      print('🔄 Returning to main page, reloading data...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reloadAllData();
        }
      });
    }
  }

  //---------------------------------------------------------------
  Category? selectedCategory;
  List<Category> _all = [];
  List<Category> _rootCategories = [];
  List<Category> _activeSubs = [];
  // ignore: unused_field
  Category? _selectedRoot;
  int? _selectedSubId;
  late final ScrollController _subsCtrl;
  Map<int, String> get _catNameById => {
        for (final c in _all) c.id: c.categoryName,
      }; // _all: List<Category>

  //--------------------------------------------------------------
  ApiHandler apiHandler = ApiHandler();
  TextEditingController searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  //---------------------------------------------------------------
  List<OrderItemDto> selectedItems = [];
  double subtotal = 0.0;
  double taxes = 0.0;
  double total = 0.0;
  Map<int, double> productPrices = {};
  double tips = 0.0;
  //String orderStatus = '';
  String paymentMethod = 'Cash'; // Default payment method
  bool isCash = true; // Initially set to 'Cash'
  double switchScale = 0.8;
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool _isRoot(Category c) {
    final p = _toInt(c.mainCategoryId);
    return p == null || p == 0;
  }

  int? get selectedRootId => selectedCategory?.id;
  int? get selectedSubId => _selectedSubId;
  //---------------------------------------------------------------
  final TextEditingController promoCodeController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  OverlayEntry? overlayEntrypromo;
  final LayerLink _layerLinkpromo = LayerLink();
  List<Promocodes> searchResultspromo = [];
  Promocodes? selectedPromoCode;
  double discount = 0.0;
  double discountPercentage = 0.0;
  int orderCount = 0;
  //---------------------------------------------------------------
  Taxes? currentTaxes;
  String selectedTaxType = 'In-House'; // Default is In-House
  //---------------------------------------------------------------
  double xOffset = 0;
  double yOffset = 0;
  bool isDrawerOpen = false;
  //---------------------------------------------------------------
  // ignore: unused_field
  String _info = "";
  // ignore: unused_field
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];
  // ignore: unused_field
  final TextEditingController _txtText = TextEditingController(
    text: "Hello developer",
  );
  // ignore: unused_field
  bool _progress = false;
  // ignore: unused_field
  String _msjprogress = "";
  // ignore: unused_field
  final String _selectSize = "2";
  String formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  List<Category> _allCategories = [];

  // ignore: unused_element
  Future<void> _loadCats() async {
    final org = await SessionManager.getOrganizationId();
    _allCategories = await ApiHandler().getCategoriesForOrg(org ?? 0);
    _rootCategories = ApiHandler().rootsOf(_allCategories);
    _buildCategoryIndices(_allCategories);
    setState(() {});
  }

  void _onCategoriesLoaded(List<Category> all) {
    setState(() {
      _allCategories = all;
      _rootCategories = all.where(_isRoot).toList();
    });
  }

  void _buildCategoryIndices(List<Category> all) {
    _catById.clear();
    _subIdsByRoot.clear();

    for (final c in all) {
      _catById[c.id] = c;
      final parent = c.id;
      if (parent != null) {
        (_subIdsByRoot[parent] ??= <int>[]).add(c.id);
      }
    }
  }

  Map<int, Category> _catById = {};
  Map<int, List<int>> _subIdsByRoot = {};

  void _onRootTap(Category? cat) {
    setState(() {
      selectedCategory = cat; // null => All
      _selectedSubId = null; // reset any sub
      if (cat == null) {
        _activeSubs = const [];
      } else {
        final rootId = _toInt(cat.mainCategoryId);
        _activeSubs = _allCategories
            .where(
              (c) => _toInt(c.mainCategoryId) == rootId,
            ) // children of this root
            .toList();
      }
    });
  }

  void _onSubTap(Category sub) {
    setState(() => _selectedSubId = sub.id);
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.storage,
    ].request();

    statuses.forEach((permission, status) {
      if (status.isDenied) {
        print('$permission is denied');
      } else if (status.isPermanentlyDenied) {
        print('$permission is permanently denied. Open app settings.');
      } else {
        print('$permission granted');
      }
    });
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int batteryPercentage = 0;

    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      batteryPercentage = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    _msj = result
        ? "Bluetooth enabled, please search and connect"
        : "Bluetooth not enabled";

    setState(() {
      _info = "$platformVersion ($batteryPercentage% battery)";
    });
  }

  Future<void> getBluetoothDevices() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });

    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _progress = false;
      items = listResult;
    });
  }

  Future<void> connectToPrinter(String macAddress) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });

    final bool result = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );

    if (result) {
      setState(() {
        connected = true;
      });
    }

    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnectPrinter() async {
    // ignore: unused_local_variable
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
  }

  void _printReceipt() async {
    if (connected) {
      List<int> bytes = await generateWindowsTicket(
        OrderDto(
          id: orderCount,
          orderItems: selectedItems,
          GrandTotal: _calculateGrandTotal(selectedItems),
          PaymentMethod: paymentMethod,
          tip: tips,
        ),
      );
      await PrintBluetoothThermal.writeBytes(bytes);
      print("Printing successful!");
    } else {
      print("No printer connected. Please select a printer first.");
    }
  }

  /*
  Future<void> printTestReceipt() async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;

    if (connectionStatus) {
      bool result;
      if (Platform.isWindows) {
        List<int> ticket = await generateWindowsTicket();
        result = await PrintBluetoothThermalWindows.writeBytes(bytes: ticket);
      } else {
        List<int> ticket = await generatePrintTicket();
        result = await PrintBluetoothThermal.writeBytes(ticket);
      }
      print("Print test result: $result");
    } else {
      disconnectPrinter();
    }
  }
*/
  Future<List<int>> generateWindowsTicket(OrderDto order) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Add the header
    bytes += generator.text(
      '2Go Cafe',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      'Time: ${formattedTime}',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.text(
      'Receipt # ${order.id}',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.text('', styles: PosStyles(align: PosAlign.center));

    bytes += generator.text(
      'Item:        Qty:         Price:',
      styles: PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.hr(); // Horizontal line

    // Iterate over order items and fetch product info
    for (var item in order.orderItems) {
      // Fetch product details
      Product product = await _getProductById(item.productId);

      // ignore: unnecessary_null_comparison
      if (product != null) {
        double totalPrice = item.quantity * product.SellingPrice;

        // Ensure proper spacing
        String productName = product.ProductName.padRight(
          12,
        ); // 20-character width
        String quantity = 'x${item.quantity}'.padLeft(
          5,
        ); // Right-align quantity
        String price = '${totalPrice.toStringAsFixed(2)} JOD'.padLeft(
          15,
        ); // Align price

        bytes += generator.text(
          '$productName$quantity$price',
          styles: PosStyles(align: PosAlign.left),
        );
      }
    }

    bytes += generator.hr(); // Horizontal line

    // Add subtotal, taxes, and total
    bytes += generator.text(
      'Subtotal:       ${_calculateSubtotal(selectedItems)} JOD',
      styles: PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.text(
      '${AppLocalizations.of(context)!.tax}(${selectedTaxType == "In-House" ? currentTaxes?.inHouse.toStringAsFixed(0) ?? 0 : currentTaxes?.takeOut.toStringAsFixed(0) ?? 0}%):      ${_calculateTaxes(selectedItems).toStringAsFixed(2)} JOD',
      styles: PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.text(
      'Total:      ${(order.GrandTotal + order.tip).toStringAsFixed(2)} JOD',
      styles: PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.feed(1);

    bytes += generator.text(
      'PaymentMethod:          ${order.PaymentMethod}    ',
      styles: PosStyles(align: PosAlign.right),
    );

    bytes += generator.text(
      'Tip:                    ${order.tip.toStringAsFixed(2)} JOD',
      styles: PosStyles(align: PosAlign.right),
    );

    bytes += generator.feed(3); // Space at the end
    bytes += generator.hr(); // Horizontal line
    /*
    bytes += generator.text('AlphaCore Solution',
        styles: PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1));
            */

    bytes += generator.text('', styles: PosStyles(align: PosAlign.center));

    bytes += generator.text(
      'Contact Information:',
      styles: PosStyles(align: PosAlign.center),
    );

    bytes += generator.text('', styles: PosStyles(align: PosAlign.center));

    bytes += generator.text(
      'Phone Number: +962 7 9702 0297',
      styles: PosStyles(align: PosAlign.center),
    );

    bytes += generator.text('', styles: PosStyles(align: PosAlign.center));
    /*
    bytes += generator.text('acsolutions.business@gmail.com',
        styles: PosStyles(align: PosAlign.center));
*/
    bytes += generator.feed(0);
    bytes += generator.cut(); // Cut the paper

    return bytes;
  }

  Future<List<int>> generatePrintTicket() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];
    bytes += generator.text("Test Print");
    bytes += generator.cut();

    return bytes;
  }

  void _showPrinterDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select Printer',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: const Color(0xFFB87333), // dark orange
                    ),
                dialogBackgroundColor: Colors.grey[100],
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5C42), // brown
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select a Printer',
                        style: TextStyle(
                          color: const Color(0xFF36454F),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: items.isNotEmpty
                            ? ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.grey.shade300,
                                  height: 1,
                                ),
                                itemBuilder: (ctx, i) {
                                  final device = items[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Navigator.pop(context);
                                        connectToPrinter(device.macAdress);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            device.name,
                                            style: TextStyle(
                                              color: Color(0xFF36454F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            device.macAdress,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.bluetooth,
                                            color: const Color(0xFFB87333),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  'No paired Bluetooth printers found.',
                                  style: TextStyle(color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  void _togglePaymentMethod(bool value) {
    setState(() {
      isCash = value;
      paymentMethod =
          isCash ? 'Cash' : 'Visa'; // Toggle between 'Cash' and 'Visa'
    });
  }

  Future<void> _fetchTaxes() async {
    try {
      final taxes = await apiHandler.getTaxes();
      setState(() {
        currentTaxes = taxes;
      });
    } catch (e) {
      print('Error fetching taxes: $e');
    }
  }

  void _removeOverlaypromo() {
    overlayEntrypromo?.remove();
    overlayEntrypromo = null;
  }

  void _showOverlaypromo(BuildContext context) {
    _removeOverlaypromo(); // Remove previous overlay if any

    final overlay = Overlay.of(context);
    if (searchResultspromo.isEmpty) return;

    overlayEntrypromo = OverlayEntry(
      builder: (context) => Positioned(
        width:
            MediaQuery.of(context).size.width * 0.42, // Adjust width if needed
        child: CompositedTransformFollower(
          link: _layerLinkpromo,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Adjust dropdown position
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: searchResultspromo.map((promo) {
                  return ListTile(
                    title: Text(promo.PromoCode),
                    onTap: () {
                      selectedPromoCode = promo; // Set the selected promo code
                      promoCodeController.text =
                          promo.PromoCode; // Update TextField
                      discount = promo.Percentage;
                      searchResultspromo = []; // Clear search results
                      _removeOverlaypromo(); // Hide dropdown
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntrypromo!); // Insert overlay into the widget tree
  }

  void findPromoCode(String query) async {
    if (query.isEmpty) {
      _removeOverlaypromo(); // Hide overlay if search is empty
      return;
    }

    List<Promocodes> allPromoCodes =
        await apiHandler.fetchPromoCodes(); // Use instance

    List<Promocodes> filteredPromoCodes = allPromoCodes
        .where(
          (promo) =>
              promo.PromoCode.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (filteredPromoCodes.isEmpty) {
      _removeOverlaypromo(); // Hide dropdown if no results
      return;
    }

    searchResultspromo = filteredPromoCodes; // Update search results
    _showOverlaypromo(context); // Show the dropdown above the TextField
  }

  void _removeProductFromOrder(int index) {
    if (index < 0 || index >= selectedItems.length) {
      print("Invalid index");
      return;
    }

    setState(() {
      int productId = selectedItems[index].productId;

      // Get the product using the function
      //var product = _getProductById(productId);
      /*
    // Restore the product quantity
    if (product.id != 0) {
      if(product.ProductInventory != 0){
        product.ProductInventory += 1;  // Increase quantity back
      }
    }
    */

      selectedItems[index] = selectedItems[index].updateQuantity(
        selectedItems[index].quantity - 1,
      );

      if (selectedItems[index].quantity == 0) {
        productPrices.remove(productId); // Remove price from map
        selectedItems.removeAt(index);
      }
    });
  }

  void _addQuantity(int index) {
    if (index < 0 || index >= selectedItems.length) {
      print("Invalid index");
    }
    setState(() {
      selectedItems[index] = selectedItems[index].updateQuantity(
        selectedItems[index].quantity + 1,
      );
    });
  }

  double _getProductPrice(int productId) {
    return productPrices[productId] ?? 0.0;
  }

  void addToOrder(Product product) {
    setState(
      () {
        int index = selectedItems.indexWhere(
          (item) => item.productId == product.id,
        );

        //if(product.ProductInventory != 0){}
        if (index != -1) {
          selectedItems[index] = selectedItems[index].updateQuantity(
            selectedItems[index].quantity + 1,
          );
        } else {
          selectedItems.add(OrderItemDto(productId: product.id, quantity: 1));
          productPrices[product.id] =
              product.SellingPrice; // Store product price
        }
      },

      /*
   else{
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product ${product.ProductName} Is Out Of Stock!'))
    );}
   */
    );
  }

  double _calculateGrandTotal(List<OrderItemDto> orderItems) {
    double subtotal = _calculateSubtotal(orderItems);
    double taxes = _calculateTaxes(orderItems);
    return subtotal + taxes;
  }

  void submitOrder() async {
    double grandTotal = _calculateGrandTotal(selectedItems);
    OrderDto order = OrderDto(
      id: 0,
      orderItems: selectedItems,
      GrandTotal: grandTotal,
      PaymentMethod: paymentMethod,
      //OrderStatus: OrderStatus,
      tip: tips,
    );

    bool success = await ApiHandler().postOrder(order);

    if (success) {
      /*
    // Update product inventory
    for (var item in selectedItems) {
      Product product = _getProductById(item.productId);
      
      if (product.id != 0) {
        // Deduct the quantity and update in DB
        product.ProductInventory -= item.quantity;
        print("🔄 Updating inventory for ${product.ProductName}: ${product.ProductInventory}");
        
        await ApiHandler().updateProductInventoryInDatabase(product);
      }
    }
    */

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Order submitted successfully!')),
      );

      setState(() {
        selectedItems.clear(); // Clear the list
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to submit order')));
    }
  }

  double _calculateSubtotal(List<OrderItemDto> orderItems) {
    // First, calculate the subtotal for all items
    double subtotal = orderItems.fold(0.0, (sum, item) {
      final price = _getProductPrice(item.productId); // Get price for each item
      return sum + (price * item.quantity);
    });

    // After calculating the subtotal, apply the discount if it's not zero
    if (discount != 0.0) {
      // Apply the discount as a percentage of the subtotal
      subtotal -= (discount / 100 * subtotal);
    }

    return subtotal;
  }

  double _calculateTaxes(List<OrderItemDto> orderItems) {
    double taxRate = 0.0;

    // Ensure that taxes are fetched and available
    if (currentTaxes != null) {
      if (selectedTaxType == 'In-House') {
        taxRate = currentTaxes!.inHouse;
      } else if (selectedTaxType == 'Takeout') {
        taxRate = currentTaxes!.takeOut;
      }
    }
    return _calculateSubtotal(orderItems) * (taxRate / 100);
  }

  double _calculateTotal(List<OrderItemDto> orderItems) {
    return _calculateSubtotal(orderItems) + _calculateTaxes(orderItems) + tips;
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay(); // Remove previous overlay if any

    final overlay = Overlay.of(context);
    if (searchResults.isEmpty) return;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width:
            MediaQuery.of(context).size.width * 0.42, // Adjust width if needed
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Adjust the dropdown’s position
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: searchResults.map((Product) {
                  return ListTile(
                    title: Text(Product.ProductName),
                    onTap: () {
                      setState(() {
                        productSearch =
                            Product; // Set the selected product for search
                        searchController.text =
                            Product.ProductName; // Update the search bar text
                        searchResults = []; // Clear the search results
                        addToOrder(Product);
                      });
                      _removeOverlay(); // Hide the dropdown after selection
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!); // Insert the overlay into the widget tree
  }

  void findProduct(String query) async {
    if (query.isEmpty) {
      _removeOverlay(); // Remove overlay when the search is empty
      return;
    }

    // Fetch all products (or use a cached list if available)
    List<Product> allProducts = await apiHandler.searchProductByName(
      productName: query,
    );

    // Filter products locally based on the query
    List<Product> filteredProducts = allProducts
        .where(
          (product) =>
              product.ProductName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (filteredProducts.isEmpty) {
      _removeOverlay(); // Hide dropdown if no results
      return;
    }

    setState(() {
      searchResults = filteredProducts; // Update search results
    });

    _showOverlay(); // Show the dropdown above the TextField
  }

  void getData() async {
    data = await apiHandler.getProductData();
    setState(() {
      if (data.isEmpty) {
        print("data not here");
      }
    });
  }

  Future<void> categoryData() async {
    if (_orgId == null) {
      print('⚠️ Organization ID not available, skipping category data load');
      return;
    }

    final result = await apiHandler.getLeafCategoriesByOrg(_orgId!);
    if (!mounted) return;

    // derive roots & clear subs
    final roots = result.where((c) => c.mainCategoryId == null).toList();

    setState(() {
      _all = result;
      _rootCategories = roots;
      _selectedRoot = null;
      _activeSubs = []; // collapsed initially
    });

    debugPrint('Roots: ${_rootCategories.length}');
    for (final r in _rootCategories) {
      debugPrint(
        ' root -> id=${r.id}, name=${r.categoryName}, main=${r.mainCategoryId}',
      );
    }
  }

  // tap handlers used by your UI

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

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

    getData();
    _subsCtrl = ScrollController();

    // Load organization ID first, then categories
    _loadOrganizationId().then((_) {
      _loadCategories();
      categoryData();
      // Mark initialization as complete
      setState(() {
        _hasBeenInitialized = true;
      });
    });

    requestPermissions();
    apiHandler.fetchPromoCodes();
    _fetchTaxes();
    getBluetoothDevices().then((_) {
      if (items.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          _showPrinterDialog();
        });
      }
    });

    // after first frame, give focus to our hidden field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_barcodeFocus);
    });
  }

  void _onBarcodeSubmitted(String code) {
    _barcodeController.clear();
    _processScannedBarcode(code.trim());
  }

  Future<void> _processScannedBarcode(String code) async {
    final api = ApiHandler();
    final filter = "Barcode LIKE N'%$code%'";

    // 1) Fetch matching products
    final products = await api.advanceSearchProducts(filter);

    if (products.isNotEmpty) {
      final prod = products.first;
      setState(() {
        // 2) Find index of an existing OrderItemDto with same productId
        final idx = selectedItems.indexWhere(
          (item) => item.productId == prod.id,
        );

        if (idx >= 0) {
          // 3a) If found, increment its quantity
          selectedItems[idx].quantity += 1;
        } else {
          // 3b) Otherwise add a brand‐new line
          selectedItems.add(OrderItemDto(productId: prod.id, quantity: 1));
        }
      });
    } else {
      // 4) Not found → prompt to create
      final newProd = await showDialog<Product>(
        context: context,
        builder: (_) => AddProductDialog(barcode: code),
      );
      if (newProd != null) {
        setState(() {
          selectedItems.add(OrderItemDto(productId: newProd.id, quantity: 1));
        });
      }
    }

    // 5) Re‑focus so the scanner keeps feeding here
    FocusScope.of(context).requestFocus(_barcodeFocus);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _tipController.dispose();
    _subsCtrl.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      if (isDrawerOpen) {
        xOffset = 0;
        yOffset = 0;
        isDrawerOpen = false;
      } else {
        xOffset = 290;
        yOffset = 80;
        isDrawerOpen = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(xOffset, yOffset, 0)
            ..scale(isDrawerOpen ? 0.85 : 1.0),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(context)!.welcomeMessage,
                style: TextStyle(fontSize: screenWidth * 0.017),
              ),
              centerTitle: true,
              backgroundColor: Color(0xFF36454F),
              foregroundColor: Colors.white,
              leading: GestureDetector(
                onTap: toggleMenu,
                child: Icon(isDrawerOpen ? Icons.arrow_back_ios : Icons.menu),
              ),
              actions: [
                QuickApiSwitcher(),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showPrinterDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(8), // Adjust button padding
                    minimumSize: Size(24, 24), // Set minimum button size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Rounded corners
                    ),
                  ),
                  child: Icon(
                    Icons.print,
                    size: 15, // Adjust icon size
                    color: Color(0xFFB87333),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  connected ? "Printer Connected" : "Printer Not Connected",
                  style: TextStyle(
                    color: connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    _reloadAllData();
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: SizedBox(
                height: screenHeight * 1.1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Left Section - Main content (Products and Categories)
                      Expanded(
                        flex:
                            3, // You can adjust this flex value based on the layout
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            CompositedTransformTarget(
                              link:
                                  _layerLink, // This should be defined as LayerLink _layerLink = LayerLink();
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: screenWidth * 0.13,
                                ),
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.02, // Horizontal padding
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.01, // Vertical padding
                                    ),
                                    labelText: translation(context).search,
                                    labelStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        width: 1.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: MediaQuery.of(context).size.height *
                                          0.035,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context)
                                            .size
                                            .width *
                                        0.02, // Set text size to 3.5% of screen width
                                  ),
                                  onChanged: (query) {
                                    findProduct(query);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.01,
                            ), // Space between the search bar and the grid view
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.categories,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.022,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(197, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),

                            // Category Grid View
                            // Main category row (horizontal)
                            SizedBox(
                              height: screenHeight * 0.18,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _rootCategories.length + 1,
                                itemBuilder: (context, index) {
                                  final isAll = index == 0;
                                  final cat =
                                      isAll ? null : _rootCategories[index - 1];
                                  final name =
                                      isAll ? 'All' : cat!.categoryName;

                                  return GestureDetector(
                                    onTap: () => _onRootTap(cat),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      width: screenWidth * 0.13,
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            name,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.016,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                166,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Animated subcategory rail (vertical, compact)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              key: ValueKey(_activeSubs.length),
                              curve: Curves.easeOut,
                              child: _activeSubs.isEmpty
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: screenHeight * 0.16,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: screenWidth * 0.12,
                                            margin: const EdgeInsets.only(
                                              left: 4,
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Scrollbar(
                                              controller: _subsCtrl,
                                              thumbVisibility: true,
                                              interactive: true,
                                              child: ListView.separated(
                                                controller: _subsCtrl,
                                                primary: false,
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount: _activeSubs.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 8),
                                                itemBuilder: (context, i) {
                                                  final sub = _activeSubs[i];
                                                  final selected =
                                                      sub.id == _selectedSubId;
                                                  final cs = Theme.of(
                                                    context,
                                                  ).colorScheme;

                                                  return Material(
                                                    color: selected
                                                        ? cs.primary
                                                            .withOpacity(0.08)
                                                        : Colors.white,
                                                    elevation: selected ? 2 : 0,
                                                    shadowColor: cs.primary
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(
                                                          () => _selectedSubId =
                                                              sub.id,
                                                        );
                                                        _onSubTap(sub);
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 160,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 12,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          border: Border.all(
                                                            color: selected
                                                                ? cs.primary
                                                                : Colors.grey
                                                                    .withOpacity(
                                                                    0.22,
                                                                  ),
                                                            width: selected
                                                                ? 1.25
                                                                : 1,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // circular icon chip
                                                            AnimatedContainer(
                                                              color: selected
                                                                  ? cs.primary
                                                                  : Colors.grey
                                                                      .withOpacity(
                                                                      0.18,
                                                                    ),
                                                              duration:
                                                                  const Duration(
                                                                milliseconds:
                                                                    160,
                                                              ),
                                                              width: 28,
                                                              height: 28,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: selected
                                                                    ? cs.primary
                                                                        .withOpacity(
                                                                        0.18,
                                                                      )
                                                                    : Colors
                                                                        .grey
                                                                        .shade200,
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .label_rounded,
                                                                size: 16,
                                                                color: selected
                                                                    ? cs.primary
                                                                    : Colors
                                                                        .grey
                                                                        .shade700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            // name
                                                            Expanded(
                                                              child: Text(
                                                                sub.categoryName,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      const Color(
                                                                    0xFF36454F,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      screenWidth *
                                                                          0.011,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            // chevron
                                                            Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              size: 18,
                                                              color: selected
                                                                  ? cs.primary
                                                                  : Colors.grey
                                                                      .shade600,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            SizedBox(height: screenHeight * 0.01),
                            Padding(
                              padding: EdgeInsets.only(
                                left: 8.0,
                                right: 50.0,
                                bottom: screenHeight * 0.005,
                                top: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.products,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.022,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(197, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Product Grid View
                            Expanded(
                              child: data.isEmpty
                                  ? Center(
                                      child: Text(
                                        translation(
                                          context,
                                        ).no_available_products,
                                      ),
                                    )
                                  : Builder(
                                      builder: (context) {
                                        final int? selectedSubId =
                                            _selectedSubId; // if you use subs
                                        // filter by ID, not by name
                                        final rootSubIds = (selectedRootId ==
                                                null)
                                            ? const <int>[]
                                            : _allCategories
                                                .where(
                                                  (c) =>
                                                      _toInt(c.id) ==
                                                      _toInt(selectedRootId),
                                                )
                                                .map(
                                                  (c) => _toInt(
                                                    c.mainCategoryId,
                                                  )!,
                                                )
                                                .toList();

                                        final filteredProducts = data.where((
                                          p,
                                        ) {
                                          final int? pCatId = _toInt(
                                            p.ProductCategory,
                                          );
                                          if (pCatId == null) return false;

                                          final bool matchesRoot =
                                              (selectedRootId == null) ||
                                                  pCatId ==
                                                      _toInt(selectedRootId) ||
                                                  rootSubIds.contains(pCatId);

                                          final bool matchesSub =
                                              (selectedSubId == null) ||
                                                  (pCatId ==
                                                      _toInt(selectedSubId));

                                          return matchesRoot && matchesSub;
                                        }).toList();

                                        return GridView.builder(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: filteredProducts
                                              .length, // use filtered length
                                          itemBuilder: (context, index) {
                                            final product =
                                                filteredProducts[index];

                                            // look up the category name from its id
                                            final categoryName = _catNameById[
                                                    product.ProductCategory] ??
                                                'Uncategorized';

                                            return GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () => addToOrder(product),
                                                );
                                              },
                                              child: Card(
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // Product Name
                                                    Text(
                                                      product.ProductName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.014,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    // Category Name
                                                    Text(
                                                      categoryName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.011,
                                                        color: Colors.grey,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    // Price
                                                    Text(
                                                      '${product.SellingPrice.toStringAsFixed(2)} JOD',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.012,
                                                        color: Colors.green,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Right Section - Order Details
                      SingleChildScrollView(
                        child: SizedBox(
                          height: screenHeight * 1,
                          child: Container(
                            height: screenHeight * 2.3,
                            width: screenWidth *
                                0.35, // Set a fixed width for the right section
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  spreadRadius: 4,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.orders,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.022,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(197, 0, 0, 0),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),

                                // Display selected products
                                if (selectedItems.isNotEmpty)
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: selectedItems.length,
                                      itemBuilder: (context, index) {
                                        final selected = selectedItems[index];
                                        // Cast data to List<Product> and fetch the product details
                                        final product = _getProductById(
                                          selected.productId,
                                        );
                                        return Card(
                                          elevation: 4,
                                          margin: EdgeInsets.only(
                                            bottom: screenHeight * 0.02,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              screenWidth * 0.0008,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: screenWidth * 0.001,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Adding ListTile here
                                                      ListTile(
                                                        title: Text(
                                                          product.ProductName,
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.013,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          'Quantity: ${selected.quantity}',
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.013,
                                                          ),
                                                        ),
                                                        trailing: Text(
                                                          '${product.SellingPrice.toStringAsFixed(2)} JOD',
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.015,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.remove_circle,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _removeProductFromOrder(
                                                        index,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.add_circle,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed: () =>
                                                          _addQuantity(index),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                // Divider line
                                Divider(height: 7, color: Colors.black45),
                                // Promo Code Section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CompositedTransformTarget(
                                          link: _layerLinkpromo,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              double textFieldWidth = constraints
                                                      .maxWidth *
                                                  0.8; // Adjust width dynamically
                                              double textSize = screenWidth *
                                                  0.013; // Adjust font size dynamically
                                              double paddingHorizontal =
                                                  screenWidth *
                                                      0.02; // Adjust padding dynamically
                                              double paddingVertical =
                                                  screenHeight * 0.015;

                                              return Container(
                                                width:
                                                    textFieldWidth, // Ensure it scales dynamically
                                                child: TextField(
                                                  controller:
                                                      promoCodeController,
                                                  style: TextStyle(
                                                    fontSize: textSize,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        AppLocalizations.of(
                                                      context,
                                                    )!
                                                            .discount,
                                                    labelStyle: TextStyle(
                                                      fontSize: textSize,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          paddingHorizontal,
                                                      vertical: paddingVertical,
                                                    ),
                                                  ),
                                                  onChanged: findPromoCode,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Handle promo code validation here

                                          if (selectedPromoCode != null) {
                                            setState(() {
                                              // Here you can add your validation logic
                                              // If valid, update the selectedPromoCode text
                                              // If not valid, you can show an error or reset the value
                                            });
                                          } else {
                                            // If no promo code selected, you can show an error or message
                                            setState(() {
                                              // Optionally show an error if no promo code is selected
                                              selectedPromoCode =
                                                  null; // Reset or handle the case where no promo code is selected
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFB87333),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.ok,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                //tips section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.001,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          width: screenWidth *
                                              0.2, // Adjust width as needed
                                          height: screenHeight *
                                              0.08, // Adjust height as needed
                                          child: TextField(
                                            controller: _tipController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: 'Enter tip amount',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                tips = double.tryParse(value) ??
                                                    0.0;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider line (for discount section)
                                Divider(
                                  height: screenHeight * 0.02,
                                  color: Colors.black45,
                                ),
                                /*
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTaxType =
                                              'In-House'; // Switch to In-House tax
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12), // Reduce padding
                                        minimumSize:
                                            Size(100, 45), // Adjust button size
                                        textStyle: TextStyle(
                                            fontSize: 14), // Make text smaller
                                      ),
                                      child: Text('In-House Tax'),
                                    ),
                                    SizedBox(
                                        height:
                                            8), // Reduce spacing between buttons
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTaxType =
                                              'Takeout'; // Switch to Takeout tax
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        minimumSize: Size(100, 45),
                                        textStyle: TextStyle(fontSize: 14),
                                      ),
                                      child: Text('Takeout Tax'),
                                    ),
                                  ],
                                ),

                            */
                                // Discount Section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.discount,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            selectedPromoCode != null
                                                ? '${selectedPromoCode!.PromoCode} (%${selectedPromoCode!.Percentage})' // Safe to access since we checked for null
                                                : 'No Promo Code', // Default text if no promo code is selected
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                              fontSize: screenWidth * 0.013,
                                            ),
                                          ),
                                          // Add the circular "X" button
                                          if (selectedPromoCode != null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  // Reset discount and selectedPromoCode when the "X" is tapped
                                                  discount = 0.0;
                                                  selectedPromoCode = null;
                                                });
                                              },
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                width:
                                                    24.0, // Set the size of the circle
                                                height:
                                                    24.0, // Set the size of the circle
                                                decoration: BoxDecoration(
                                                  color: Colors
                                                      .red, // Circle color
                                                  shape: BoxShape
                                                      .circle, // Make the container circular
                                                ),
                                                child: Icon(
                                                  Icons.close, // The "X" icon
                                                  color: Colors
                                                      .white, // Icon color
                                                  size: 16.0, // Icon size
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.001,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment Method', // You can change this to any localized text
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth *
                                              0.0115, // Adjust text size based on screen width
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            paymentMethod, // Show the current payment method
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth *
                                                  0.0115, // Adjust text size based on screen width
                                            ),
                                          ),
                                          Transform.scale(
                                            scale:
                                                switchScale, // Adjust the scale to change the switch size
                                            child: Switch(
                                              value: isCash, // Toggle value
                                              onChanged:
                                                  _togglePaymentMethod, // Update payment method on change
                                              activeColor: Colors
                                                  .green, // Color when 'Visa' is selected
                                              inactiveThumbColor: Colors
                                                  .blue, // Color when 'Cash' is selected
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Subtotal
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.total,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Text(
                                        '${_calculateSubtotal(selectedItems).toStringAsFixed(2)} JOD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Taxes
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.tax} (${selectedTaxType == "In-House" ? currentTaxes?.inHouse ?? 0 : currentTaxes?.takeOut ?? 0}%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Text(
                                        '${_calculateTaxes(selectedItems).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.grandTotal} - %${discount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.015,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_calculateTotal(selectedItems).toStringAsFixed(2)} JOD',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.016,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkout Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        submitOrder(); // First, submit the order
                                        // Then, print the receipt
                                        _printReceipt();
                                        orderCount++;
                                        setState(() {
                                          tips = 0.0;
                                          _tipController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.01,
                                          40,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.checkout,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.015,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF8B5C42),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.01,
                                          40,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 30,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!
                                            .printReceipt,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.011,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                /*
                                      // Charge button
                                      SizedBox(height: screenHeight * 0.03),
                                      Center(
                                      child: ElevatedButton(
                                        onPressed:_chargeOrder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(MediaQuery.of(context).size.width * 0.1, 50),
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: selectedItems.isNotEmpty
                                            ? Text('Charge \$${_calculateTotal(selectedItems).toStringAsFixed(2)}', style: TextStyle(fontSize: screenWidth * 0.0165))
                                            : Text(AppLocalizations.of(context)!.noData,textAlign: TextAlign.center ,style: TextStyle(fontSize: screenWidth * 0.0165, color: Colors.white,)),
                                      ),
                                    ),
                                    */
                              ],
                            ),
                          ),
                        ),
                      ),
                      // In your State class:

                      // 1) Put this in your widget tree—e.g. at the end of your Stack:
                      Focus(
                        focusNode: _barcodeFocus,
                        autofocus: true,
                        onKey: (FocusNode node, RawKeyEvent event) {
                          // 1) When keys come down, accumulate their characters
                          if (event is RawKeyDownEvent &&
                              event.character != null &&
                              event.character!.isNotEmpty) {
                            _barcodeBuffer += event.character!;
                            return KeyEventResult.handled;
                          }
                          // 2) On key-up of ENTER, submit the whole buffer once
                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                              event is RawKeyUpEvent) {
                            _onBarcodeSubmitted(_barcodeBuffer);
                            _barcodeBuffer = '';
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child:
                            const SizedBox.shrink(), // zero footprint, no IME
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  /*  
void _chargeOrder() async {
  if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(translation(context).no_products_selected)),
    );
    return;
  }

  // Update product inventory
  for (var item in selectedItems) {
    Product product = _getProductById(item.productId);
    if (product.id != 0) {
      // Subtract the quantity ordered from the product inventory
      product.ProductInventory -= item.quantity;
      print("Updated inventory for ${product.ProductName}: ${product.ProductInventory}");
      
      // Update the product inventory in the database (optional)
      await apiHandler.updateProductInventoryInDatabase(product);
    }
  }

  // Now post the order
  OrderDto order = OrderDto(id: 0, orderItems: selectedItems, GrandTotal: _calculateGrandTotal(selectedItems));
  bool success = await ApiHandler().postOrder(order);
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).order_success)));
    setState(() {
      selectedItems.clear();  // Clear the list
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).failed_order_submission)));
  }
}
*/

  Product _getProductById(int productId) {
    print("Looking up product with ID: $productId");

    // Cast the data list to a List<Product> and search for the product by its ID
    var product = (data as List<Product>).firstWhere(
      (product) => product.id == productId,
      orElse: () {
        // If product isn't found, fetch it from the API (or return a default)
        print(
          "Product with ID $productId not found in cache, fetching from API...",
        );
        return Product(
          id: 0,
          OrganizationId: _orgId!.toInt(),
          ProductCategory: 0,
          ProductName: 'Unknown Product',
          ProductDescription: 'No description available',
          PurchasePrice: 0,
          SellingPrice: 0,
          ProductInventory: 0,
          Barcode: '',
        );
      },
    );

    if (product.id == 0) {
      // If the product is still the default (not found), make an API call to fetch the product by ID
      print("Fetching product from API...");
      // Optionally make an API call to fetch a single product by its ID and return that.
    }

    print("Found product: ${product.ProductName}, ID: ${product.id}");
    return product;
  }
}

class AddProductDialog extends StatefulWidget {
  final String barcode;
  const AddProductDialog({required this.barcode});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog>
    with SingleTickerProviderStateMixin {
  // Animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _purPriceCtrl = TextEditingController();
  final _inventoryCtrl = TextEditingController();

  // Data
  List<Category> _categories = [];
  Category? _chosenCategory;
  int? _orgId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Setup animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    // Load async data
    _loadOrganizationId();
    _loadCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _inventoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationId() async {
    final id = await SessionManager.getOrganizationId();
    setState(() => _orgId = id);
  }

  Future<void> _loadCategories() async {
    if (_orgId != null) {
      final cats = await ApiHandler().getLeafCategoriesByOrg(_orgId!);
      setState(() => _categories = cats);
      print(
          '📂 Dialog loaded ${cats.length} categories for organization $_orgId');
    } else {
      print(
          '⚠️ Organization ID not available in dialog, skipping category load');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _chosenCategory == null) return;
    setState(() => _isSubmitting = true);

    final newProd = Product(
      id: 0,
      OrganizationId: _orgId ?? 0,
      ProductCategory: _chosenCategory!.id,
      ProductName: _nameCtrl.text.trim(),
      ProductDescription: _descCtrl.text.trim(),
      SellingPrice: double.parse(_priceCtrl.text),
      PurchasePrice: double.parse(_purPriceCtrl.text),
      ProductInventory: double.parse(_inventoryCtrl.text),
      Barcode: widget.barcode,
    );

    final resp = await ApiHandler().AddProducts(product: newProd);
    setState(() => _isSubmitting = false);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final created = Product.fromJson(json.decode(resp.body));
      Navigator.of(context).pop(created);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error creating product')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFB87333), // Dark orange focus
              ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB87333)),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add New Product',
            style: const TextStyle(
              color: Color(0xFF36454F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    // Barcode
                    TextFormField(
                      initialValue: widget.barcode,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                      readOnly: true,
                      style: const TextStyle(color: Color(0xFF36454F)),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Price & Inventory
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                double.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _inventoryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Inventory',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                double.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Category>(
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.categoryName),
                                  ),
                                )
                                .toList(),
                            onChanged: (c) =>
                                setState(() => _chosenCategory = c),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            validator: (v) => v == null ? 'Pick one' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFB87333),
                          ),
                          onPressed: () async {
                            final cat = await Navigator.push<Category>(
                              context,
                              MaterialPageRoute(builder: (_) => AddCategory()),
                            );
                            if (cat != null) {
                              setState(() {
                                _categories.add(cat);
                                _chosenCategory = cat;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8B5C42)),
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB87333),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 6,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
