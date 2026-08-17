import '../../../../core/domain/entities/cart.dart' as entities;

class CartState {
  const CartState({
    this.cart = entities.Cart.empty,
    this.isLoading = false,
    this.error,
  });

  final entities.Cart cart;
  final bool isLoading;
  final String? error;

  CartState copyWith({
    entities.Cart? cart,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
