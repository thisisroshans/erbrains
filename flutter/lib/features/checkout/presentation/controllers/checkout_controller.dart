import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/cart_sync/cart_sync_providers.dart';
import '../../../../core/domain/entities/cart_mutation.dart';

part 'checkout_controller.g.dart';

/// What happened when "Place order" was tapped.
enum CheckoutOutcome {
  /// The order reached the backend before this call returned — the common,
  /// online case.
  placed,

  /// Queued instead — either genuinely offline, or the backend rejected it
  /// (e.g. a race that emptied the cart) and it's now sitting in the
  /// retry/backoff cycle like any other queued mutation. Either way, it's
  /// not lost: the cart sync banner surfaces it, with a Retry/Discard
  /// choice once it exhausts its attempts. See docs/OFFLINE_SYNC.md.
  queued,
}

/// Owns the "Place order" submission's loading flag — the Controller layer
/// for Checkout. Screen-local, ephemeral UI state, but modeled as Riverpod
/// state (not `setState`) like everything else in the app.
///
/// Unlike the pre-offline-queue version of this controller, [submit] never
/// throws: placing an order always goes through the same queue as every
/// other cart write (see CartController), so there's nothing left to
/// surface synchronously except which of [CheckoutOutcome] happened.
@riverpod
class CheckoutSubmission extends _$CheckoutSubmission {
  @override
  bool build() => false;

  Future<CheckoutOutcome> submit(String userId) async {
    final store = ref.read(cartSyncStoreProvider);

    // A previous tap already queued a placeOrder mutation that hasn't
    // resolved yet — don't queue a second one (it would just fail against
    // an already-emptied cart once the first one drains).
    final alreadyQueued = store.pendingForSync().any((m) => m.type == CartMutationType.placeOrder);
    if (alreadyQueued) return CheckoutOutcome.queued;

    state = true;
    try {
      final mutationId = const Uuid().v4();
      await store.enqueue(CartMutation(
        localId: mutationId,
        type: CartMutationType.placeOrder,
        createdAt: DateTime.now(),
      ));

      await ref.read(cartSyncManagerProvider(userId)).drain();

      return store.contains(mutationId) ? CheckoutOutcome.queued : CheckoutOutcome.placed;
    } finally {
      state = false;
    }
  }
}
