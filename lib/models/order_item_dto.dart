import 'order_item_addition_dto.dart';

class OrderItemDto {
  final int productId;
  final double quantity;
  final double discount;

  final String? notes;
  final List<OrderItemAdditionDto> additions;

  OrderItemDto({
    required this.productId,
    required this.quantity,
    this.discount = 0.0,
    this.notes,
    this.additions = const [],
  });

  OrderItemDto updateQuantity(double newQuantity) {
    return OrderItemDto(
      productId: productId,
      quantity: newQuantity,
      discount: discount,
      notes: notes,
      additions: additions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'discount': discount,
      'notes': notes,
      'additions': additions.map((a) => a.toJson()).toList(),
    };
  }

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'] ?? json['ProductId'] ?? 0,
      quantity: (json['quantity'] ?? json['Quantity'] ?? 0).toDouble(),
      discount: (json['discount'] ?? json['Discount'] ?? 0).toDouble(),
      notes: json['notes'] ?? json['Notes'],
      additions: ((json['additions'] ?? json['Additions']) as List<dynamic>?)
              ?.map((e) =>
                  OrderItemAdditionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
