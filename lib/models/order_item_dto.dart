class OrderItemDto {
  final int productId;
  final double quantity;
  final double discount;

  OrderItemDto({
    required this.productId,
    required this.quantity,
    this.discount = 0.0,
  });

  OrderItemDto updateQuantity(double newQuantity) {
    return OrderItemDto(
      productId: productId,
      quantity: newQuantity,
      discount: discount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'] ?? json['ProductId'] ?? 0,
      quantity: (json['quantity'] ?? json['Quantity'] ?? 0).toDouble(),
      discount: (json['discount'] ?? json['Discount'] ?? 0).toDouble(),
    );
  }
}
