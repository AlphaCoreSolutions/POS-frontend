class OrderItemDto {
  final int productId;
  final int quantity;

  OrderItemDto({
    required this.productId,
    required this.quantity,
  });

  OrderItemDto updateQuantity(int newQuantity) {
    return OrderItemDto(
      productId: productId,
      quantity: newQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'],
      quantity: json['quantity'],
    );
  }
}
