import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/components/category_selector.dart';
import 'package:visionpos/components/order_summary.dart';
import 'package:visionpos/components/payment_section.dart';
import 'package:visionpos/components/printer_section.dart';
import 'package:visionpos/components/product_grid.dart';
import 'package:visionpos/components/promo_code_section.dart';
import 'package:visionpos/components/quick_api_switcher.dart';
import 'package:visionpos/components/side_menu.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/models/promocodes_model.dart';
import 'package:visionpos/providers/pos_provider.dart';

class NewMainPage extends StatefulWidget {
  const NewMainPage({super.key});

  @override
  State<NewMainPage> createState() => _NewMainPageState();
}

class _NewMainPageState extends State<NewMainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _promoCodeController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onProductTap(Product product) {
    context.read<PosProvider>().addToOrder(product);
  }

  void _onFindPromoCode(String query) {
    final provider = context.read<PosProvider>();
    final matchingCodes = provider.searchPromoCodes(query);
    _showPromoCodeOverlay(matchingCodes);
  }

  void _onValidatePromoCode() {
    final provider = context.read<PosProvider>();
    final promoCode = _promoCodeController.text.trim();
    final matchingPromo = provider.promoCodes.firstWhere(
      (p) => p.PromoCode.toLowerCase() == promoCode.toLowerCase(),
      orElse: () => Promocodes(
        id: 0,
        PromoCode: '',
        Percentage: 0.0,
        OrganizationId: 0,
      ),
    );

    if (matchingPromo.id != 0) {
      provider.applyPromoCode(matchingPromo);
      _promoCodeController.clear();
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code')),
      );
    }
  }

  void _showPromoCodeOverlay(List<Promocodes> promoCodes) {
    _overlayEntry?.remove();

    if (promoCodes.isEmpty) {
      _overlayEntry = null;
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: promoCodes.length,
                itemBuilder: (context, index) {
                  final promo = promoCodes[index];
                  return ListTile(
                    title: Text(promo.PromoCode),
                    subtitle: Text('${promo.Percentage}% off'),
                    onTap: () {
                      _promoCodeController.text = promo.PromoCode;
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onShowPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Status'),
        content: const Text('Printer functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PosProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          QuickApiSwitcher(
            onEnvironmentChanged: () => provider.loadData(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadData(),
          ),
        ],
      ),
      drawer: const DrawerPage(),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return Stack(
                    children: [
                      // Main content
                      Column(
                        children: [
                          // Category selector
                          Container(
                            height: screenHeight * 0.25,
                            padding: const EdgeInsets.all(8),
                            child: CategorySelector(
                              rootCategories: provider.rootCategories,
                              activeSubs: provider.activeSubs,
                              selectedCategory: provider.selectedCategory,
                              selectedSubId: provider.selectedSubId,
                              onRootTap: provider.selectRootCategory,
                              onSubTap: provider.selectSubCategory,
                            ),
                          ),
                          // Product grid
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: ProductGrid(
                                products: provider.products,
                                allCategories: provider.categories,
                                selectedRootId: provider.selectedRootId,
                                selectedSubId: provider.selectedSubId,
                                onProductTap: _onProductTap,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Mobile order summary overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: screenHeight * 0.4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            children: [
                              // Handle
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Order summary content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.orders,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: OrderSummary(
                                          selectedItems: provider.selectedItems,
                                          products: provider.products,
                                          onRemoveProduct:
                                              provider.removeFromOrder,
                                          onAddQuantity: provider.addQuantity,
                                        ),
                                      ),
                                      // Promo code section
                                      PromoCodeSection(
                                        promoCodeController:
                                            _promoCodeController,
                                        layerLink: _layerLink,
                                        onFindPromoCode: _onFindPromoCode,
                                        onValidatePromoCode:
                                            _onValidatePromoCode,
                                        selectedPromoCode:
                                            provider.selectedPromoCode,
                                        onRemovePromoCode:
                                            provider.removePromoCode,
                                      ),
                                      // Payment section
                                      PaymentSection(
                                        paymentMethod:
                                            provider.paymentMethod == 1
                                                ? 'Cash'
                                                : 'Visa',
                                        isCash: provider.isCash,
                                        onTogglePaymentMethod: (_) =>
                                            provider.togglePaymentMethod(),
                                      ),
                                      // Printer and submit
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          PrinterSection(
                                            connected: true,
                                            onShowPrinterDialog:
                                                _onShowPrinterDialog,
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                provider.selectedItems.isEmpty
                                                    ? null
                                                    : () async {
                                                        final success =
                                                            await provider
                                                                .submitOrder();
                                                        if (success) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Order submitted successfully')),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Failed to submit order')),
                                                          );
                                                        }
                                                      },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFB87333),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                      vertical: 16),
                                            ),
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .submit),
                                          ),
                                        ],
                                      ),
                                      // Total
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          border: Border(
                                              top: BorderSide(
                                                  color: Colors.grey.shade300)),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('Subtotal:'),
                                                Text(
                                                    '${provider.subtotal.toStringAsFixed(2)} JOD'),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('Taxes:'),
                                                Text(
                                                    '${provider.taxes.toStringAsFixed(2)} JOD'),
                                              ],
                                            ),
                                            if (provider.tips > 0)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('Tips:'),
                                                  Text(
                                                      '${provider.tips.toStringAsFixed(2)} JOD'),
                                                ],
                                              ),
                                            const Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  '${provider.total.toStringAsFixed(2)} JOD',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet layout
                  return Row(
                    children: [
                      // Main content area
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Category selector
                            Container(
                              height: screenHeight * 0.2,
                              padding: const EdgeInsets.all(8),
                              child: CategorySelector(
                                rootCategories: provider.rootCategories,
                                activeSubs: provider.activeSubs,
                                selectedCategory: provider.selectedCategory,
                                selectedSubId: provider.selectedSubId,
                                onRootTap: provider.selectRootCategory,
                                onSubTap: provider.selectSubCategory,
                              ),
                            ),
                            // Product grid
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: ProductGrid(
                                  products: provider.products,
                                  allCategories: provider.categories,
                                  selectedRootId: provider.selectedRootId,
                                  selectedSubId: provider.selectedSubId,
                                  onProductTap: _onProductTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right panel
                      Container(
                        width: constraints.maxWidth < 1200 ? 350 : 400,
                        decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Column(
                          children: [
                            // Order summary
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: OrderSummary(
                                  selectedItems: provider.selectedItems,
                                  products: provider.products,
                                  onRemoveProduct: provider.removeFromOrder,
                                  onAddQuantity: provider.addQuantity,
                                ),
                              ),
                            ),
                            // Promo code section
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: PromoCodeSection(
                                promoCodeController: _promoCodeController,
                                layerLink: _layerLink,
                                onFindPromoCode: _onFindPromoCode,
                                onValidatePromoCode: _onValidatePromoCode,
                                selectedPromoCode: provider.selectedPromoCode,
                                onRemovePromoCode: provider.removePromoCode,
                              ),
                            ),
                            // Payment section
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: PaymentSection(
                                paymentMethod: provider.paymentMethod == 1
                                    ? 'Cash'
                                    : 'Visa',
                                isCash: provider.isCash,
                                onTogglePaymentMethod: (_) =>
                                    provider.togglePaymentMethod(),
                              ),
                            ),
                            // Printer and submit
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  PrinterSection(
                                    connected: true,
                                    onShowPrinterDialog: _onShowPrinterDialog,
                                  ),
                                  ElevatedButton(
                                    onPressed: provider.selectedItems.isEmpty
                                        ? null
                                        : () async {
                                            final success =
                                                await provider.submitOrder();
                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Order submitted successfully')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Failed to submit order')),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB87333),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                    child: Text(
                                        AppLocalizations.of(context)!.submit),
                                  ),
                                ],
                              ),
                            ),
                            // Total display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Subtotal:'),
                                      Text(
                                          '${provider.subtotal.toStringAsFixed(2)} JOD'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Taxes:'),
                                      Text(
                                          '${provider.taxes.toStringAsFixed(2)} JOD'),
                                    ],
                                  ),
                                  if (provider.tips > 0)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Tips:'),
                                        Text(
                                            '${provider.tips.toStringAsFixed(2)} JOD'),
                                      ],
                                    ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${provider.total.toStringAsFixed(2)} JOD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }
}
