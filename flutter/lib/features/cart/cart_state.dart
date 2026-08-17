import '../../core/models/cart.dart' as models;

class CartState {
  const CartState({
    this.cart = models.Cart.empty,
    this.isLoading = false,
    this.error,
  });

  final models.Cart cart;
  final bool isLoading;
  final String? error;

  CartState copyWith({models.Cart? cart, bool? isLoading, String? error, bool clearError = false}) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
