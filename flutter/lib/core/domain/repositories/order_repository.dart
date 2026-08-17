import '../entities/order.dart';

abstract class OrderRepository {
  /// Converts the user's current cart into an order. Throws
  /// [ApiException] if the cart is empty (surfaced by the backend as a 400).
  Future<void> placeOrder(String userId);

  Future<List<Order>> list(String userId);
}
