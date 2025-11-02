import 'package:flutter/material.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';

class ProductGrid extends StatelessWidget {
  final List<dynamic> products;
  final List<Category> allCategories;
  final int? selectedRootId;
  final int? selectedSubId;
  final Function(Product) onProductTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.allCategories,
    this.selectedRootId,
    this.selectedSubId,
    required this.onProductTap,
  });

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) {
      final int? pCatId = _toInt(p.ProductCategory);
      if (pCatId == null) return false;

      final bool matchesRoot = (selectedRootId == null) ||
          pCatId == _toInt(selectedRootId) ||
          _allCategories
              .where((c) => _toInt(c.id) == _toInt(selectedRootId))
              .map((c) => _toInt(c.mainCategoryId)!)
              .contains(pCatId);

      final bool matchesSub =
          (selectedSubId == null) || (pCatId == _toInt(selectedSubId));

      return matchesRoot && matchesSub;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 900
                ? 3
                : constraints.maxWidth < 1200
                    ? 4
                    : 5;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final categoryName = _getCategoryName(product.ProductCategory);

            return GestureDetector(
              onTap: () => onProductTap(product),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.ProductName,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.014,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.011,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${product.SellingPrice.toStringAsFixed(2)} JOD',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.012,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Uncategorized';
    final category = allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: 0,
        categoryName: 'Uncategorized',
        mainCategoryId: null,
        organizationId: 0,
      ),
    );
    return category.categoryName;
  }

  List<Category> get _allCategories => allCategories;
}
