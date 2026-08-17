import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/remote/api_client.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Cart> get(String userId) async {
    final json = await _api.getCart(userId: userId);
    return Cart.fromJson(json);
  }

  @override
  Future<void> add({required String userId, required String productId, required int quantity}) {
    return _api.addToCart(userId: userId, productId: productId, quantity: quantity);
  }

  @override
  Future<void> setQuantity({required String cartItemId, required int quantity}) {
    return _api.updateCartItemQuantity(cartItemId: cartItemId, quantity: quantity);
  }

  @override
  Future<void> remove(String cartItemId) {
    return _api.removeCartItem(cartItemId: cartItemId);
  }
}
