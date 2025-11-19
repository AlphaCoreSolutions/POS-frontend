import 'domain_detail_model.dart';

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

  // 🔥 NEW
  final int? domainId;
  final String? domainName;
  final List<DomainDetail> additions;

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
    this.domainId,
    this.domainName,
    this.additions = const [],
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

        // 🔥 NEW: handle domain + additions if backend sends them
        domainId: json['domainId'] ?? json['DomainId'],
        domainName: json['domainName'] ?? json['DomainName'],
        additions: ((json['additions'] ?? json['Additions']) as List<dynamic>?)
                ?.map((e) => DomainDetail.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
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

        // You usually don’t POST products from POS,
        // but it’s safe to include:
        'domainId': domainId,
        'domainName': domainName,
        'additions': additions.map((e) => e.toJson()).toList(),
      };
}
