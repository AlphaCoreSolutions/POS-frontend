import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/order_item_dto.dart';
import 'package:visionpos/models/product_model.dart';

/// Splits an order's items by category IDs into kitchen buckets.
class KitchenRouter {
  final Set<int> falafelCategoryIds;
  final Set<int> shawarmaSnacksCategoryIds;

  KitchenRouter({
    required this.falafelCategoryIds,
    required this.shawarmaSnacksCategoryIds,
  });

  /// Expects order map with 'items' as a List of items where each item has 'categoryId' and usual fields.
  Map<String, List<Map<String, dynamic>>> split(Map<String, dynamic> order) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final falafel = <Map<String, dynamic>>[];
    final shsn = <Map<String, dynamic>>[];
    for (final it in items) {
      final cat = (it['categoryId'] ?? 0) as int;
      if (falafelCategoryIds.contains(cat)) {
        falafel.add(it);
      } else if (shawarmaSnacksCategoryIds.contains(cat)) {
        shsn.add(it);
      }
    }
    return {'falafel': falafel, 'shawarmaSnacks': shsn};
  }

  Map<String, List<OrderItemDto>> splitOrder(
    OrderDto order,
    Map<int, Product> productsById,
  ) {
    final falafel = <OrderItemDto>[];
    final shawarma = <OrderItemDto>[];

    for (final it in order.orderItems) {
      final p = productsById[it.productId];
      if (p == null) continue;
      if (p.categoryId == 2) {
        falafel.add(it);
      } else if ({3, 6, 7, 8, 9}.contains(p.categoryId)) {
        shawarma.add(it);
      }
    }
    return {
      'falafel': falafel,
      'shawarmaSnacks': shawarma,
    };
  }
}
