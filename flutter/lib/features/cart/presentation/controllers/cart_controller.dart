import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/cart_sync/cart_sync_manager.dart';
import '../../../../core/cart_sync/cart_sync_providers.dart';
import '../../../../core/cart_sync/cart_sync_store.dart';
import '../../../../core/cart_sync/effective_cart.dart';
import '../../../../core/data/datasources/remote/api_exception.dart';
import '../../../../core/domain/entities/cart.dart' as entities;
import '../../../../core/domain/entities/cart_mutation.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/repositories/cart_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import 'cart_state.dart';

part 'cart_controller.g.dart';

/// One controller per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
///
/// Every mutation (add/setQuantity/remove) is queued through
/// [CartSyncStore] rather than calling the backend directly — see
/// docs/OFFLINE_SYNC.md. That queue, folded onto the last-known server
/// cart via [applyPendingCartMutations], is this controller's actual
/// source of truth for [CartState.cart]; [refresh] only refetches and
/// updates the *baseline* half of that.
@riverpod
class Cart extends _$Cart {
  final _uuid = const Uuid();
  StreamSubscription<void>? _storeSub;

  @override
  CartState build(String userId) {
    Future.microtask(refresh);
    _storeSub = _store.watch().listen((_) => _recompute());
    ref.onDispose(() => _storeSub?.cancel());
    return CartState(cart: _effective(), isLoading: true);
  }

  CartRepository get _repository => ref.read(cartRepositoryProvider);
  CartSyncStore get _store => ref.read(cartSyncStoreProvider);
  CartSyncManager get _syncManager => ref.read(cartSyncManagerProvider(userId));

  entities.Cart _effective() =>
      applyPendingCartMutations(_store.readBaseline() ?? entities.Cart.empty, _store.pendingForSync());

  void _recompute() {
    state = state.copyWith(cart: _effective());
  }

  /// Refetches `GET /cart` and stores it as the new baseline. On failure
  /// (most commonly: offline) leaves the existing cached baseline and any
  /// queued mutations exactly as they were — the screen keeps showing the
  /// last known state instead of an error where perfectly good cached data
  /// already exists.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cart = await _repository.get(userId);
      await _store.writeBaseline(cart);
      state = state.copyWith(cart: _effective(), isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(cart: _effective(), isLoading: false, error: e.message);
    }
  }

  /// Queues adding [quantity] of [product] and applies it to the displayed
  /// cart immediately; syncs in the background via [CartSyncManager].
  /// Always reports success to the caller — a queued write can't fail
  /// synchronously, only its eventual sync can, which surfaces later via
  /// the cart sync banner, not here.
  Future<bool> addToCart({required Product product, required int quantity}) async {
    await _store.enqueue(CartMutation(
      localId: _uuid.v4(),
      type: CartMutationType.add,
      createdAt: DateTime.now(),
      productId: product.id,
      productName: product.name,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      quantity: quantity,
    ));
    unawaited(_syncManager.drain());
    return true;
  }

  /// Queues setting a line item to an exact quantity.
  Future<bool> setQuantity({required String cartItemId, required int quantity}) async {
    await _store.enqueue(CartMutation(
      localId: _uuid.v4(),
      type: CartMutationType.setQuantity,
      createdAt: DateTime.now(),
      cartItemId: cartItemId,
      quantity: quantity,
    ));
    unawaited(_syncManager.drain());
    return true;
  }

  /// Queues removing a line item entirely.
  Future<bool> removeItem(String cartItemId) async {
    await _store.enqueue(CartMutation(
      localId: _uuid.v4(),
      type: CartMutationType.remove,
      createdAt: DateTime.now(),
      cartItemId: cartItemId,
    ));
    unawaited(_syncManager.drain());
    return true;
  }
}
