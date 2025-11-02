import '../models/order_item_dto.dart' as order_item_dto;
import '../models/order_dto.dart' as order_dto;

class OrderService {
  static double calculateSubtotal(
      List<order_item_dto.OrderItemDto> items, List<dynamic> products) {
    return items.fold(0.0, (sum, item) {
      final product = _getProductById(products, item.productId);
      final price = product?.sellingPrice ?? 0.0;
      return sum + (price * item.quantity);
    });
  }

  static double calculateTaxes(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }

  static double calculateTotal(double subtotal, double taxes, double tips) {
    return subtotal + taxes + tips;
  }

  static double applyDiscount(double subtotal, double discountPercentage) {
    if (discountPercentage > 0) {
      return subtotal - (subtotal * discountPercentage / 100);
    }
    return subtotal;
  }

  static order_dto.OrderDto createOrder({
    required List<order_item_dto.OrderItemDto> items,
    required double grandTotal,
    required String paymentMethod,
    required double tip,
  }) {
    return order_dto.OrderDto(
      id: 0,
      orderItems: items,
      GrandTotal: grandTotal,
      PaymentMethod: paymentMethod,
      tip: tip,
    );
  }

  static dynamic _getProductById(List<dynamic> products, int productId) {
    return products.cast<dynamic>().firstWhere(
          (product) => product.id == productId,
          orElse: () => null,
        );
  }
}
