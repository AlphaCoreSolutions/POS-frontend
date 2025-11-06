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
}
