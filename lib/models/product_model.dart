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

class OrderItemDto {
  final int productId;
  double quantity;
  Product? product;

  OrderItemDto({required this.productId, required this.quantity, this.product});
  OrderItemDto updateQuantity(double newQuantity) {
    return OrderItemDto(productId: this.productId, quantity: newQuantity);
  }

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class OrderDto {
  final int id;
  double GrandTotal;
  final List<OrderItemDto> orderItems;
  final String PaymentMethod;
  //final String OrderStatus;
  final double tip;

  OrderDto(
      {required this.id,
      required this.orderItems,
      required this.GrandTotal,
      required this.PaymentMethod,
      //required this.OrderStatus,
      required this.tip});

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['orderId'],
      GrandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      orderItems: (json['orderItems'] as List)
          .map((item) => OrderItemDto.fromJson(item))
          .toList(),
      PaymentMethod: json['paymentMethod'],
      //OrderStatus: json['orderStatus'],
      tip: json['tips'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': id,
      'grandTotal': GrandTotal,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
      'paymentMethod': PaymentMethod,
      //'orderStatus': OrderStatus,
      'tips': tip,
    };
  }
}
