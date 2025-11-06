import 'order_item_dto.dart';

class OrderDto {
  final int id;
  final int organizationId;
  final int customerId;
  final double tips;
  final List<OrderItemDto> orderItems;
  final double grandTotal;
  final int paymentMethod;
  final double tip;
  final String? orderPlaced;

  OrderDto({
    this.id = 0,
    required this.organizationId,
    this.customerId = 0,
    this.paymentMethod = 1,
    this.tips = 0.0,
    required this.orderItems,
    this.grandTotal = 0.0,
    this.tip = 0.0,
    this.orderPlaced,
  });

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'customerId': customerId,
      'paymentMethod': paymentMethod,
      'tips': tips,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
    };
  }

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] ?? json['Id'] ?? 0,
      organizationId: json['organizationId'] ?? json['OrganizationId'] ?? 0,
      customerId: json['customerId'] ?? json['CustomerId'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? json['PaymentMethod'] ?? 1,
      tips: (json['tips'] ?? json['Tips'] ?? 0).toDouble(),
      orderItems: (json['orderItems'] ?? json['OrderItems'] as List? ?? [])
          .map((item) => OrderItemDto.fromJson(item))
          .toList(),
      grandTotal: (json['GrandTotal'] ?? json['grandTotal'] ?? 0).toDouble(),
      tip: (json['tip'] ?? json['tips'] ?? 0).toDouble(),
      orderPlaced: json['orderPlaced'] ?? json['OrderPlaced'],
    );
  }
}
