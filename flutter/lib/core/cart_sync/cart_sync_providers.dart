import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/orders/presentation/controllers/orders_controller.dart';
import '../domain/entities/cart.dart';
import '../providers/datasource_providers.dart';
import 'cart_sync_manager.dart';
import 'cart_sync_store.dart';

part 'cart_sync_providers.g.dart';

@Riverpod(keepAlive: true)
CartSyncStore cartSyncStore(Ref ref) => CartSyncStore();

@Riverpod(keepAlive: true)
CartSyncManager cartSyncManager(Ref ref, String userId) {
  final api = ref.watch(apiClientProvider);
  final store = ref.watch(cartSyncStoreProvider);

  return CartSyncManager(
    store: store,
    addToCart: ({required productId, required quantity}) async {
      final json = await api.addToCart(userId: userId, productId: productId, quantity: quantity);
      return json['id'] as String;
    },
    setQuantity: ({required cartItemId, required quantity}) =>
        api.updateCartItemQuantity(cartItemId: cartItemId, quantity: quantity),
    removeItem: (cartItemId) => api.removeCartItem(cartItemId: cartItemId),
    placeOrder: () => api.placeOrder(userId: userId),
    refreshBaseline: () async {
      final json = await api.getCart(userId: userId);
      await store.writeBaseline(Cart.fromJson(json));
    },
    // ordersProvider is keyed by userId (see orders_controller.dart) —
    // invalidating it here means Order History refetches next time it's
    // viewed, whether the order was placed live or drained from the queue
    // later on.
    onOrderPlaced: () => ref.invalidate(ordersProvider(userId)),
  );
}

/// Live count of cart/order mutations not yet applied — what the cart sync
/// banner shows.
@Riverpod(keepAlive: true)
Stream<int> pendingCartMutationsCount(Ref ref) async* {
  final store = ref.watch(cartSyncStoreProvider);
  yield store.pendingCount();
  await for (final _ in store.watch()) {
    yield store.pendingCount();
  }
}

/// Live count of mutations that exhausted their retry budget.
@Riverpod(keepAlive: true)
Stream<int> failedCartMutationsCount(Ref ref) async* {
  final store = ref.watch(cartSyncStoreProvider);
  yield store.failedCount();
  await for (final _ in store.watch()) {
    yield store.failedCount();
  }
}
