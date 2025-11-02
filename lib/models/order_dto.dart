import 'order_item_dto.dart';

class OrderDto {
  final int id;
  final List<OrderItemDto> orderItems;
  final double GrandTotal;
  final String PaymentMethod;
  final double tip;

  OrderDto({
    required this.id,
    required this.orderItems,
    required this.GrandTotal,
    required this.PaymentMethod,
    required this.tip,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
      'GrandTotal': GrandTotal,
      'PaymentMethod': PaymentMethod,
      'tip': tip,
    };
  }

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'],
      orderItems: (json['orderItems'] as List)
          .map((item) => OrderItemDto.fromJson(item))
          .toList(),
      GrandTotal: json['GrandTotal'],
      PaymentMethod: json['PaymentMethod'],
      tip: json['tip'],
    );
  }
}
