import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/cart.dart' as models;
import '../../core/providers/core_providers.dart';
import 'cart_state.dart';

part 'cart_provider.g.dart';

/// One notifier per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
@riverpod
class Cart extends _$Cart {
  @override
  CartState build(String userId) {
    // Kick off an initial load; screens see isLoading:true until it lands.
    Future.microtask(refresh);
    return const CartState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.getCart(userId: userId);
      state = CartState(cart: models.Cart.fromJson(json), isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Adds [quantity] more of [productId]. The backend upserts via
  /// `ON CONFLICT` — there's no "set exact quantity" or "remove item"
  /// endpoint yet, so per-line +/- steppers on the Cart screen itself are
  /// UI-only until that lands. See docs/API_GAPS.md.
  Future<bool> addToCart({required String productId, required int quantity}) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.addToCart(userId: userId, productId: productId, quantity: quantity);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}
