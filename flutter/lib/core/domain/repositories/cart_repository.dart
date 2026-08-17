import '../entities/cart.dart';

abstract class CartRepository {
  Future<Cart> get(String userId);

  /// Adds [quantity] more of [productId] (or creates the line item).
  Future<void> add({required String userId, required String productId, required int quantity});

  /// Sets a line item to an exact quantity.
  Future<void> setQuantity({required String cartItemId, required int quantity});

  Future<void> remove(String cartItemId);
}
