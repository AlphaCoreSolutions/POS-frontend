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
    required int organizationId,
    required List<order_item_dto.OrderItemDto> items,
    int customerId = 0,
    int paymentMethod = 1,
    double tips = 0.0,
  }) {
    return order_dto.OrderDto(
      organizationId: organizationId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      tips: tips,
      orderItems: items,
    );
  }

  static dynamic _getProductById(List<dynamic> products, int productId) {
    return products.cast<dynamic>().firstWhere(
          (product) => product.id == productId,
          orElse: () => null,
        );
  }
}
