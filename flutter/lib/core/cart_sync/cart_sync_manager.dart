import '../data/datasources/remote/api_exception.dart';
import '../domain/entities/cart_mutation.dart';
import 'cart_sync_store.dart';

/// Drains [CartSyncStore]'s queued cart/order mutations to the backend in
/// write order, one at a time (unlike [SyncManager]'s reading batches —
/// each cart mutation is a different HTTP call with a different shape, so
/// there's no single endpoint to batch them into).
///
/// Two things this has to get right that the reading queue doesn't:
///
/// 1. **Local -> real id resolution.** An item added while offline has no
///    backend id yet — [CartMutation.localCartItemId] stands in for it. If
///    a later queued `setQuantity`/`remove` targets that same local id,
///    resolving it depends on the `add` mutation having synced first. FIFO
///    drain order + [CartSyncStore.rewriteCartItemId] (called the instant
///    an `add` succeeds) guarantees that: a dependent mutation is never
///    even enqueued before its `add`, and drain always processes strictly
///    oldest-first, stopping entirely on the first failure — so it can
///    never reach a dependent mutation whose `add` hasn't resolved.
/// 2. **Order placement must wait for everything ahead of it.** `POST
///    /orders` converts whatever the *server* thinks the cart is — placing
///    it before queued cart edits have synced would checkout the wrong
///    cart. [drain] always exhausts every non-order mutation before
///    attempting any queued `placeOrder`.
class CartSyncManager {
  CartSyncManager({
    required this.store,
    required this.addToCart,
    required this.setQuantity,
    required this.removeItem,
    required this.placeOrder,
    required this.refreshBaseline,
    this.onOrderPlaced,
    this.maxAttempts = 5,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CartSyncStore store;

  /// Returns the real backend `cart_item_id` for the newly-created line
  /// item — what [CartMutation.localCartItemId] gets rewritten to.
  final Future<String> Function({required String productId, required int quantity}) addToCart;
  final Future<void> Function({required String cartItemId, required int quantity}) setQuantity;
  final Future<void> Function(String cartItemId) removeItem;
  final Future<void> Function() placeOrder;

  /// Re-fetches `GET /cart` and writes the result as the new baseline —
  /// called once after a drain pass fully empties the queue, so the
  /// offline-created items' local placeholders get replaced by the
  /// server's real state promptly rather than waiting for whatever screen
  /// happens to call `refresh()` next.
  final Future<void> Function() refreshBaseline;

  /// Fired after a queued `placeOrder` mutation successfully applies —
  /// lets callers invalidate order-history state without this class
  /// needing to know anything about Riverpod/order providers.
  final void Function()? onOrderPlaced;

  final int maxAttempts;
  final DateTime Function() _now;

  static const _backoffSeconds = [2, 4, 8, 16, 30];

  bool _isDraining = false;
  DateTime? _nextAttemptAt;

  bool get isDraining => _isDraining;

  /// Attempts to drain everything currently queued, strictly oldest-first
  /// except that every non-order mutation is drained before any queued
  /// `placeOrder` is attempted (see class doc). Safe to call liberally —
  /// no-ops if already draining, backoff hasn't elapsed, or the queue is
  /// empty.
  Future<void> drain() async {
    if (_isDraining) return;
    if (_nextAttemptAt != null && _now().isBefore(_nextAttemptAt!)) return;

    _isDraining = true;
    var appliedAny = false;
    try {
      while (true) {
        final pending = store.pendingForSync();
        if (pending.isEmpty) {
          _nextAttemptAt = null;
          if (appliedAny) await refreshBaseline();
          return;
        }

        final nonOrder = pending.where((m) => m.type != CartMutationType.placeOrder);
        final mutation = nonOrder.isNotEmpty ? nonOrder.first : pending.first;

        try {
          await _apply(mutation);
          await store.markApplied(mutation.localId);
          appliedAny = true;
          _nextAttemptAt = null;
        } catch (e) {
          if (e is ApiException && !e.isRetryable) {
            // A business rejection (e.g. 409 insufficient stock) won't fix
            // itself on retry — surface it immediately via the failed
            // state instead of spending the attempt budget on it.
            await store.markFailedImmediately(mutation.localId);
            if (appliedAny) await refreshBaseline();
            _nextAttemptAt = null;
          } else {
            await store.recordFailedAttempt(mutation.localId, maxAttempts: maxAttempts);
            if (appliedAny) await refreshBaseline();
            _scheduleRetry(mutation.attempts + 1);
          }
          return;
        }
      }
    } finally {
      _isDraining = false;
    }
  }

  Future<void> _apply(CartMutation mutation) async {
    switch (mutation.type) {
      case CartMutationType.add:
        final realId = await addToCart(productId: mutation.productId!, quantity: mutation.quantity!);
        await store.rewriteCartItemId(mutation.localCartItemId, realId);
        break;
      case CartMutationType.setQuantity:
        await setQuantity(cartItemId: mutation.cartItemId!, quantity: mutation.quantity!);
        break;
      case CartMutationType.remove:
        await removeItem(mutation.cartItemId!);
        break;
      case CartMutationType.placeOrder:
        await placeOrder();
        onOrderPlaced?.call();
        break;
    }
  }

  void _scheduleRetry(int attempts) {
    final seconds = _backoffSeconds[(attempts - 1).clamp(0, _backoffSeconds.length - 1)];
    _nextAttemptAt = _now().add(Duration(seconds: seconds));
  }

  /// User-initiated retry from the cart sync banner's failed sheet — full
  /// attempt budget restored, backoff cleared, drains immediately.
  Future<void> retryFailed() async {
    await store.retryFailed();
    _nextAttemptAt = null;
    await drain();
  }
}
