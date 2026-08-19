import '../entities/order.dart';

abstract class OrderRepository {
  /// Converts the user's current cart into an order. Throws
  /// [ApiException] if the cart is empty (400) or if any line item exceeds
  /// available stock (409, concurrency-safe on the backend — see
  /// docs/DATABASE.md).
  Future<void> placeOrder(String userId);

  Future<List<Order>> list(String userId);

  /// Cancels an order and restores the stock it reserved. Throws
  /// [ApiException] if it's already cancelled (409) or not found/not
  /// owned by the caller (404).
  Future<void> cancel(String orderId);
}
