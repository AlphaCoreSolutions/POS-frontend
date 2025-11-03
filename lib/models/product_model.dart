class Product {
  final int productId;
  final int organizationId;
  final int categoryId;
  final String productName;
  final String? productDescription;
  final double purchasePrice;
  final double sellingPrice;
  double? productInventory;
  final String? barcode;

  Product({
    required this.productId,
    required this.organizationId,
    required this.categoryId,
    required this.productName,
    this.productDescription,
    required this.sellingPrice,
    required this.purchasePrice,
    this.productInventory,
    this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: json["productId"] ?? 0,
        categoryId: json["categoryId"] ?? 0,
        productName: json["productName"] ?? '',
        productDescription: json["productDescription"],
        sellingPrice: (json["sellingPrice"] as num?)?.toDouble() ?? 0.0,
        purchasePrice: (json["purchasePrice"] as num?)?.toDouble() ?? 0.0,
        productInventory: (json["productInventory"] as num?)?.toDouble(),
        organizationId: json["organizationId"] ?? 0,
        barcode: json["barcode"],
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'categoryId': categoryId,
        'productName': productName,
        'productDescription': productDescription,
        'sellingPrice': sellingPrice,
        'purchasePrice': purchasePrice,
        'productInventory': productInventory,
        'organizationId': organizationId,
        'barcode': barcode,
      };
}
