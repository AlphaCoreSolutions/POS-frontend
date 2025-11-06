import 'package:flutter/material.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/models/order_item_dto.dart' as order_item;
import 'package:visionpos/models/product_model.dart';

class OrderSummary extends StatelessWidget {
  final List<order_item.OrderItemDto> selectedItems;
  final List<dynamic> products;
  final Function(int) onRemoveProduct;
  final Function(int) onAddQuantity;

  const OrderSummary({
    super.key,
    required this.selectedItems,
    required this.products,
    required this.onRemoveProduct,
    required this.onAddQuantity,
  });

  Product _getProductById(int productId) {
    return (products as List<Product>).firstWhere(
      (product) => product.productId == productId,
      orElse: () => Product(
        productId: 0,
        organizationId: 0,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.orders,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.022,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(197, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedItems.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final selected = selectedItems[index];
                final product = _getProductById(selected.productId);
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.02,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.0008,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  product.productName,
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.013,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Quantity: ${selected.quantity}',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.013,
                                  ),
                                ),
                                trailing: Text(
                                  '${product.sellingPrice.toStringAsFixed(2)} JOD',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.015,
                                    fontWeight: FontWeight.bold,
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
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => onRemoveProduct(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => onAddQuantity(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: MediaQuery.of(context).size.width * 0.1,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome! Start by adding products to your order.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.02,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
