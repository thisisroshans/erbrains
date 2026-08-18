import '../domain/entities/cart.dart';
import '../domain/entities/cart_mutation.dart';

/// Folds queued, not-yet-synced [CartMutation]s onto the last-known server
/// [Cart] to produce what the user should actually see — a pure function,
/// no I/O, so it's trivially unit-testable on its own. Mirrors the
/// backend's own upsert semantics (`cart.model.js`'s `ON CONFLICT ...
/// DO UPDATE SET quantity = quantity + EXCLUDED.quantity`) so the offline
/// projection and the eventual synced state never disagree about what an
/// `add` on top of an existing line item should do.
Cart applyPendingCartMutations(Cart baseline, List<CartMutation> pendingMutations) {
  final items = [...baseline.items];

  for (final mutation in pendingMutations) {
    switch (mutation.type) {
      case CartMutationType.add:
        final existingIndex = items.indexWhere((i) => i.productId == mutation.productId);
        if (existingIndex >= 0) {
          final existing = items[existingIndex];
          final quantity = existing.quantity + mutation.quantity!;
          items[existingIndex] = existing.copyWith(
            quantity: quantity,
            subtotal: existing.price * quantity,
            pendingSync: true,
          );
        } else {
          items.add(CartItem(
            cartItemId: mutation.localCartItemId,
            productId: mutation.productId!,
            name: mutation.productName!,
            price: mutation.productPrice!,
            quantity: mutation.quantity!,
            subtotal: mutation.productPrice! * mutation.quantity!,
            imageUrl: mutation.productImageUrl,
            pendingSync: true,
          ));
        }
        break;

      case CartMutationType.setQuantity:
        final index = items.indexWhere((i) => i.cartItemId == mutation.cartItemId);
        if (index >= 0) {
          final existing = items[index];
          items[index] = existing.copyWith(
            quantity: mutation.quantity!,
            subtotal: existing.price * mutation.quantity!,
            pendingSync: true,
          );
        }
        break;

      case CartMutationType.remove:
        items.removeWhere((i) => i.cartItemId == mutation.cartItemId);
        break;

      case CartMutationType.placeOrder:
        // Doesn't change what the cart's contents look like — it changes
        // what happens to them once it drains.
        break;
    }
  }

  final totalAmount = items.fold(0.0, (sum, item) => sum + item.subtotal);
  return Cart(items: items, totalAmount: totalAmount);
}
