class Product {
  final int id;
  final int OrganizationId;
  final int ProductCategory;
  final String ProductName;
  final String ProductDescription;
  final double PurchasePrice;
  final double SellingPrice;
  double ProductInventory;
  final String Barcode;

  Product(
      {required this.id,
      required this.OrganizationId,
      required this.ProductCategory,
      required this.ProductName,
      required this.ProductDescription,
      required this.SellingPrice,
      required this.PurchasePrice,
      required this.ProductInventory,
      required this.Barcode});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["productId"] ?? 2,
        ProductCategory: json["categoryId"] ?? 0,
        ProductName: json["productName"] ?? 'the name',
        ProductDescription: json["productDescription"] ?? 'the description',
        SellingPrice: json["sellingPrice"] ?? 0,
        PurchasePrice: json["purchasePrice"] ?? 0,
        ProductInventory: json["productInventory"] ?? '0.0',
        OrganizationId: json["OrganizationId"] ?? 0,
        Barcode: json["barcode"] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'productId': id,
        'categoryId': ProductCategory,
        'productName': ProductName,
        'productDescription': ProductDescription,
        'sellingPrice': SellingPrice,
        'purchasePrice': PurchasePrice,
        'productInventory': ProductInventory,
        'OrganizationId': OrganizationId,
        'barcode': Barcode,
      };
}
