import 'package:hive_flutter/hive_flutter.dart';

import '../domain/entities/cart.dart';
import '../domain/entities/cart_mutation.dart';
import '../offline/hive_boxes.dart';

/// Backs both halves of the cart/order offline queue in a single Hive box:
/// the last-known server [Cart] (under [_baselineKey]) and the queue of
/// not-yet-applied [CartMutation]s (every other key, keyed by
/// [CartMutation.localId]). One box rather than two so a single
/// `box.watch()` stream reacts to either changing — the Cart screen needs
/// to redraw whenever the baseline refreshes *or* the queue drains, and
/// there's no meaningful ordering between those two kinds of change worth
/// tracking separately.
class CartSyncStore {
  static const _baselineKey = '__baseline__';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.cartSync);

  Cart? readBaseline() {
    final raw = _box.get(_baselineKey);
    if (raw == null) return null;
    return Cart.fromJson(Map<String, dynamic>.from(raw as Map<dynamic, dynamic>));
  }

  Future<void> writeBaseline(Cart cart) => _box.put(_baselineKey, cart.toJson());

  Future<void> enqueue(CartMutation mutation) => _box.put(mutation.localId, mutation.toHiveMap());

  /// Whether a mutation with this id is still queued (pending or failed)
  /// — false once it's been applied and removed. Used to tell "synced
  /// immediately" apart from "queued" without needing a separate status
  /// round-trip.
  bool contains(String localId) => _box.containsKey(localId);

  List<CartMutation> _allMutations() => _box.keys
      .where((k) => k != _baselineKey)
      .map((k) => CartMutation.fromHiveMap(_box.get(k) as Map<dynamic, dynamic>))
      .toList();

  /// Queued mutations not yet applied, oldest first (write order) — what
  /// [CartSyncManager] drains.
  List<CartMutation> pendingForSync() {
    final items = _allMutations().where((m) => m.status == CartMutationStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  int pendingCount() =>
      _allMutations().where((m) => m.status == CartMutationStatus.pending).length;

  int failedCount() => _allMutations().where((m) => m.status == CartMutationStatus.failed).length;

  /// A mutation successfully reached the backend — it's fully consumed,
  /// not kept around (unlike synced health readings, a queued mutation has
  /// no value once applied; the resulting state lives in the baseline).
  Future<void> markApplied(String localId) => _box.delete(localId);

  Future<void> recordFailedAttempt(String localId, {required int maxAttempts}) async {
    final raw = _box.get(localId);
    if (raw == null) return;
    final mutation = CartMutation.fromHiveMap(raw as Map<dynamic, dynamic>);
    final attempts = mutation.attempts + 1;
    final status = attempts >= maxAttempts ? CartMutationStatus.failed : CartMutationStatus.pending;
    await _box.put(localId, mutation.copyWith(attempts: attempts, status: status).toHiveMap());
  }

  /// Persists the real backend id onto every *other* pending mutation that
  /// still targets [oldId] (a `local:<mutation id>` placeholder) — called
  /// once an `add` mutation for that placeholder successfully syncs.
  /// Persisted rather than kept in memory so a dependent `setQuantity`/
  /// `remove` still resolves correctly even if the app is killed between
  /// the `add` syncing and the dependent mutation draining.
  Future<void> rewriteCartItemId(String oldId, String newId) async {
    for (final mutation in _allMutations()) {
      if (mutation.cartItemId != oldId) continue;
      await _box.put(mutation.localId, mutation.copyWith(cartItemId: newId).toHiveMap());
    }
  }

  Future<void> retryFailed() async {
    for (final mutation in _allMutations()) {
      if (mutation.status != CartMutationStatus.failed) continue;
      await _box.put(
        mutation.localId,
        mutation.copyWith(status: CartMutationStatus.pending, attempts: 0).toHiveMap(),
      );
    }
  }

  /// Permanent — a discarded mutation never applied and never will.
  Future<void> discardFailed() async {
    final failedIds = _allMutations()
        .where((m) => m.status == CartMutationStatus.failed)
        .map((m) => m.localId)
        .toList();
    await _box.deleteAll(failedIds);
  }

  /// Fires on any change to the baseline or the queue.
  Stream<void> watch() => _box.watch().map((_) {});
}
