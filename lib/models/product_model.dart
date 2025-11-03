class Product {
  final int id;
  final int organizationId;
  final int ProductCategory;
  final String ProductName;
  final String ProductDescription;
  final double PurchasePrice;
  final double SellingPrice;
  double ProductInventory;
  final String Barcode;

  Product(
      {required this.id,
      required this.organizationId,
      required this.ProductCategory,
      required this.ProductName,
      required this.ProductDescription,
      required this.SellingPrice,
      required this.PurchasePrice,
      required this.ProductInventory,
      required this.Barcode});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: int.tryParse(json["productId"]?.toString() ?? '2') ?? 2,
        ProductCategory:
            int.tryParse(json["categoryId"]?.toString() ?? '0') ?? 0,
        ProductName: json["productName"] ?? 'the name',
        ProductDescription: json["productDescription"] ?? 'the description',
        SellingPrice:
            double.tryParse(json["sellingPrice"]?.toString() ?? '0') ?? 0.0,
        PurchasePrice:
            double.tryParse(json["purchasePrice"]?.toString() ?? '0') ?? 0.0,
        ProductInventory:
            double.tryParse(json["productInventory"]?.toString() ?? '0') ?? 0.0,
        organizationId: int.tryParse(json["organizationId"]?.toString() ??
                json["OrganizationId"]?.toString() ??
                '0') ??
            0,
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
        'organizationId': organizationId,
        'barcode': Barcode,
      };
}
