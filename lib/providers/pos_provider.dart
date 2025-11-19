import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_item_dto.dart' as order_item_dto;
import '../models/order_dto.dart' as order_dto;
import '../models/promocodes_model.dart';
import '../models/taxes_model.dart';
import '../pages/essential_pages/api_handler.dart';
import '../utils/session_manager.dart';

class PosProvider with ChangeNotifier {
  // Data
  List<dynamic> _products = [];
  List<Category> _categories = [];
  List<Category> _rootCategories = [];
  List<Category> _activeSubs = [];
  List<Promocodes> _promoCodes = [];
  Taxes? _currentTaxes;

  // UI State
  bool _isLoading = false;
  String _errorMessage = '';

  // Order State
  final List<order_item_dto.OrderItemDto> _selectedItems = [];
  double _subtotal = 0.0;
  double _taxes = 0.0;
  double _total = 0.0;
  double _tips = 0.0;
  int _paymentMethod = 1; // 1 for Cash, 2 for Visa
  bool _isCash = true;
  double _discount = 0.0;
  final double _discountPercentage = 0.0;
  Promocodes? _selectedPromoCode;
  String _selectedTaxType = 'In-House';

  // Category State
  Category? _selectedCategory;
  int? _selectedSubId;

  // Organization
  int? _orgId;

  // Getters
  List<Product> get products {
    final all = _products.cast<Product>();

    if (_selectedSubId != null) {
      return all.where((p) => p.categoryId == _selectedSubId).toList();
    }

    if (_selectedCategory != null) {
      // Get all subcategories under this root
      final subIds = _categories
          .where((c) => c.mainCategoryId == _selectedCategory!.id)
          .map((c) => c.id)
          .toList();

      return all.where((p) => subIds.contains(p.categoryId)).toList();
    }

    return all;
  }

  List<Category> get categories => _categories;
  List<Category> get rootCategories => _rootCategories;
  List<Category> get activeSubs => _activeSubs;
  List<Promocodes> get promoCodes => _promoCodes;
  Taxes? get currentTaxes => _currentTaxes;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<order_item_dto.OrderItemDto> get selectedItems => _selectedItems;
  double get subtotal => _subtotal;
  double get taxes => _taxes;
  double get total => _total;
  double get tips => _tips;
  int get paymentMethod => _paymentMethod;
  bool get isCash => _isCash;
  double get discount => _discount;
  double get discountPercentage => _discountPercentage;
  Promocodes? get selectedPromoCode => _selectedPromoCode;
  String get selectedTaxType => _selectedTaxType;
  Category? get selectedCategory => _selectedCategory;
  int? get selectedSubId => _selectedSubId;
  int? get orgId => _orgId;

  // Computed getters
  int? get selectedRootId => _selectedCategory?.id;

  // Initialization
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadOrganizationId();
      await loadData();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrganizationId() async {
    _orgId = await SessionManager.getOrganizationId();
  }

  Future<void> loadData() async {
    if (_orgId == null) return;

    try {
      await Future.wait([
        _loadProducts(),
        _loadCategories(),
        _loadPromoCodes(),
        _loadTaxes(),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    }
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final apiHandler = ApiHandler();
    _products = await apiHandler.getProductData();
  }

  Future<void> _loadCategories() async {
    if (_orgId == null) return;

    final apiHandler = ApiHandler();
    final result = await apiHandler.getLeafCategoriesByOrg(_orgId!);
    _categories = result;
    _rootCategories = result.where((c) => c.mainCategoryId == null).toList();
    _updateActiveSubs();
  }

  Future<void> _loadPromoCodes() async {
    final apiHandler = ApiHandler();
    _promoCodes = await apiHandler.fetchPromoCodes();
  }

  Future<void> _loadTaxes() async {
    final apiHandler = ApiHandler();
    _currentTaxes = await apiHandler.getTaxes();
  }

  // Category Management
  void selectRootCategory(Category? category) {
    _selectedCategory = category;
    _selectedSubId = null;
    _updateActiveSubs();
    notifyListeners();
  }

  void selectSubCategory(Category sub) {
    _selectedSubId = sub.id;
    notifyListeners();
  }

  void _updateActiveSubs() {
    if (_selectedCategory == null) {
      _activeSubs = [];
    } else {
      _activeSubs = _categories
          .where((c) => c.mainCategoryId == _selectedCategory!.id)
          .toList();
    }
  }

  // Order Management
  void addToOrder(Product product) {
    final index = _selectedItems
        .indexWhere((item) => item.productId == product.productId);

    if (index != -1) {
      _selectedItems[index] = _selectedItems[index].updateQuantity(
        _selectedItems[index].quantity + 1,
      );
    } else {
      _selectedItems.add(order_item_dto.OrderItemDto(
          productId: product.productId, quantity: 1));
    }

    _calculateTotals();
    notifyListeners();
  }

  void removeFromOrder(int index) {
    if (index < 0 || index >= _selectedItems.length) return;

    if (_selectedItems[index].quantity > 1) {
      _selectedItems[index] = _selectedItems[index].updateQuantity(
        _selectedItems[index].quantity - 1,
      );
    } else {
      _selectedItems.removeAt(index);
    }

    _calculateTotals();
    notifyListeners();
  }

  void addQuantity(int index) {
    if (index < 0 || index >= _selectedItems.length) return;

    _selectedItems[index] = _selectedItems[index].updateQuantity(
      _selectedItems[index].quantity + 1,
    );

    _calculateTotals();
    notifyListeners();
  }

  void clearOrder() {
    _selectedItems.clear();
    _tips = 0.0;
    _discount = 0.0;
    _selectedPromoCode = null;
    _calculateTotals();
    notifyListeners();
  }

  // Payment and Promo
  void togglePaymentMethod() {
    _isCash = !_isCash;
    _paymentMethod = _isCash ? 1 : 2;
    notifyListeners();
  }

  void setTips(double tips) {
    _tips = tips;
    _calculateTotals();
    notifyListeners();
  }

  void applyPromoCode(Promocodes promoCode) {
    _selectedPromoCode = promoCode;
    _discount = promoCode.Percentage;
    _calculateTotals();
    notifyListeners();
  }

  void removePromoCode() {
    _selectedPromoCode = null;
    _discount = 0.0;
    _calculateTotals();
    notifyListeners();
  }

  void setTaxType(String taxType) {
    _selectedTaxType = taxType;
    _calculateTotals();
    notifyListeners();
  }

  // Calculations
  void _calculateTotals() {
    _subtotal = _calculateSubtotal();
    _taxes = _calculateTaxes();
    _total = _subtotal + _taxes + _tips;
  }

  double _calculateSubtotal() {
    double subtotal = _selectedItems.fold(0.0, (sum, item) {
      final product = _getProductById(item.productId);
      final price = product?.sellingPrice ?? 0.0;
      return sum + (price * item.quantity);
    });

    if (_discount > 0) {
      subtotal -= (subtotal * _discount / 100);
    }

    return subtotal;
  }

  double _calculateTaxes() {
    if (_currentTaxes == null) return 0.0;

    final taxRate = _selectedTaxType == 'In-House'
        ? _currentTaxes!.inHouse
        : _currentTaxes!.takeOut;

    return _subtotal * (taxRate / 100);
  }

  Product? _getProductById(int productId) {
    return _products.cast<Product>().firstWhere(
          (product) => product.productId == productId,
          orElse: () => Product(
            productId: 0,
            organizationId: _orgId ?? 0,
            categoryId: 0,
            productName: 'Unknown Product',
            productDescription: 'No description available',
            purchasePrice: 0.0,
            sellingPrice: 0.0,
            productInventory: 0.0,
            barcode: '',
          ),
        );
  }

  // Order Submission
  Future<bool> submitOrder() async {
    if (_selectedItems.isEmpty) return false;

    final order = order_dto.OrderDto(
      id: 0,
      organizationId: _orgId ?? 0,
      orderItems: _selectedItems,
      grandTotal: _total,
      paymentMethod: _paymentMethod,
      tips: _tips,
    );

    final apiHandler = ApiHandler();
    final success = await apiHandler.postOrder(order as dynamic);

    if (success) {
      clearOrder();
    }

    return success;
  }

  // Search
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return [];

    return _products
        .cast<Product>()
        .where((product) =>
            product.productName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Promocodes> searchPromoCodes(String query) {
    if (query.isEmpty) return [];

    return _promoCodes
        .where((promo) =>
            promo.PromoCode.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
