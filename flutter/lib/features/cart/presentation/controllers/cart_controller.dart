import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/datasources/remote/api_exception.dart';
import '../../../../core/domain/repositories/cart_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import 'cart_state.dart';

part 'cart_controller.g.dart';

/// One controller per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
@riverpod
class Cart extends _$Cart {
  @override
  CartState build(String userId) {
    // Kick off an initial load; screens see isLoading:true until it lands.
    Future.microtask(refresh);
    return const CartState(isLoading: true);
  }

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cart = await _repository.get(userId);
      state = CartState(cart: cart, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Adds [quantity] more of [productId] (or creates the line item on
  /// first add) via the increment-only upsert `POST /cart`.
  Future<bool> addToCart({required String productId, required int quantity}) async {
    try {
      await _repository.add(userId: userId, productId: productId, quantity: quantity);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  /// Sets a line item to an exact quantity via `PATCH /cart/:id`.
  Future<bool> setQuantity({required String cartItemId, required int quantity}) async {
    try {
      await _repository.setQuantity(cartItemId: cartItemId, quantity: quantity);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  /// Removes a line item entirely via `DELETE /cart/:id`.
  Future<bool> removeItem(String cartItemId) async {
    try {
      await _repository.remove(cartItemId);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}
