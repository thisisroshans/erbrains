import 'dart:io';

import 'package:fitring/core/cart_sync/cart_sync_manager.dart';
import 'package:fitring/core/cart_sync/cart_sync_store.dart';
import 'package:fitring/core/data/datasources/remote/api_exception.dart';
import 'package:fitring/core/domain/entities/cart_mutation.dart';
import 'package:fitring/core/offline/hive_boxes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Drain/retry/id-remapping logic for [CartSyncManager], exercised with
/// fakes — no network, no real ApiClient. Mirrors
/// test/health_sync_manager_test.dart's approach for the reading queue.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitring_cart_sync_test');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.cartSync);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.cartSync);
    await tempDir.delete(recursive: true);
  });

  CartMutation addMutation(String id, {String productId = 'p1', int quantity = 1, DateTime? at}) {
    return CartMutation(
      localId: id,
      type: CartMutationType.add,
      createdAt: at ?? DateTime.utc(2026, 1, 1),
      productId: productId,
      productName: 'Widget',
      productPrice: 10.0,
      quantity: quantity,
    );
  }

  CartMutation setQuantityMutation(String id, {required String cartItemId, required int quantity, DateTime? at}) {
    return CartMutation(
      localId: id,
      type: CartMutationType.setQuantity,
      createdAt: at ?? DateTime.utc(2026, 1, 2),
      cartItemId: cartItemId,
      quantity: quantity,
    );
  }

  CartMutation placeOrderMutation(String id, {DateTime? at}) {
    return CartMutation(localId: id, type: CartMutationType.placeOrder, createdAt: at ?? DateTime.utc(2026, 1, 3));
  }

  CartSyncManager buildManager(
    CartSyncStore store, {
    Future<String> Function({required String productId, required int quantity})? addToCart,
    Future<void> Function({required String cartItemId, required int quantity})? setQuantity,
    Future<void> Function(String cartItemId)? removeItem,
    Future<void> Function()? placeOrder,
    Future<void> Function()? refreshBaseline,
    void Function()? onOrderPlaced,
    int maxAttempts = 5,
    DateTime Function()? now,
  }) {
    return CartSyncManager(
      store: store,
      addToCart: addToCart ?? ({required productId, required quantity}) async => 'server-generated-id',
      setQuantity: setQuantity ?? ({required cartItemId, required quantity}) async {},
      removeItem: removeItem ?? (cartItemId) async {},
      placeOrder: placeOrder ?? () async {},
      refreshBaseline: refreshBaseline ?? () async {},
      onOrderPlaced: onOrderPlaced,
      maxAttempts: maxAttempts,
      now: now,
    );
  }

  test('applies a pending add mutation and removes it from the queue', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('m1'));

    var addCalls = 0;
    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async {
        addCalls++;
        return 'server-1';
      },
    );

    await manager.drain();

    expect(addCalls, 1);
    expect(store.pendingCount(), 0);
    expect(store.contains('m1'), isFalse);
  });

  test('rewrites a dependent setQuantity mutation\'s local placeholder id once the add it '
      'targets syncs', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('add1'));
    await store.enqueue(setQuantityMutation('sq1', cartItemId: 'local:add1', quantity: 9));

    final setQuantityCalls = <String>[];
    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async => 'real-server-id-42',
      setQuantity: ({required cartItemId, required quantity}) async {
        setQuantityCalls.add(cartItemId);
      },
    );

    await manager.drain();

    expect(setQuantityCalls, ['real-server-id-42']);
    expect(store.pendingCount(), 0);
  });

  test('never attempts a queued placeOrder before every non-order mutation ahead of it has synced', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('add1', at: DateTime.utc(2026, 1, 1)));
    await store.enqueue(placeOrderMutation('order1', at: DateTime.utc(2026, 1, 2)));

    final callOrder = <String>[];
    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async {
        callOrder.add('add');
        return 'server-1';
      },
      placeOrder: () async => callOrder.add('placeOrder'),
    );

    await manager.drain();

    expect(callOrder, ['add', 'placeOrder']);
    expect(store.pendingCount(), 0);
  });

  test('placeOrder stays queued (not attempted) if an earlier mutation fails', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('add1', at: DateTime.utc(2026, 1, 1)));
    await store.enqueue(placeOrderMutation('order1', at: DateTime.utc(2026, 1, 2)));

    var placeOrderCalls = 0;
    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async => throw Exception('network error'),
      placeOrder: () async => placeOrderCalls++,
    );

    await manager.drain();

    expect(placeOrderCalls, 0);
    expect(store.pendingForSync().map((m) => m.localId), ['add1', 'order1']);
  });

  test('onOrderPlaced fires once a queued placeOrder mutation applies', () async {
    final store = CartSyncStore();
    await store.enqueue(placeOrderMutation('order1'));

    var fired = 0;
    final manager = buildManager(store, onOrderPlaced: () => fired++);

    await manager.drain();

    expect(fired, 1);
  });

  test('refreshBaseline runs once after a drain pass fully empties the queue', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('m1'));
    await store.enqueue(addMutation('m2', productId: 'p2', at: DateTime.utc(2026, 1, 2)));

    var refreshCalls = 0;
    final manager = buildManager(store, refreshBaseline: () async => refreshCalls++);

    await manager.drain();

    expect(refreshCalls, 1);
  });

  test('refreshBaseline does not run if nothing applied (empty queue)', () async {
    final store = CartSyncStore();

    var refreshCalls = 0;
    final manager = buildManager(store, refreshBaseline: () async => refreshCalls++);

    await manager.drain();

    expect(refreshCalls, 0);
  });

  test('a failed mutation stays pending (not failed) below maxAttempts', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('m1'));

    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async => throw Exception('network error'),
      maxAttempts: 5,
    );

    await manager.drain();

    expect(store.pendingCount(), 1);
    expect(store.failedCount(), 0);
  });

  test('moves a mutation to failed once it exhausts maxAttempts, and backoff blocks '
      'automatic retries before it elapses', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('m1'));

    var attemptCalls = 0;
    var now = DateTime.utc(2026, 1, 1);

    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async {
        attemptCalls++;
        throw Exception('network error');
      },
      maxAttempts: 3,
      now: () => now,
    );

    await manager.drain(); // attempt 1 (fails) -> backoff scheduled
    expect(attemptCalls, 1);

    await manager.drain(); // backoff not elapsed -> no retry
    expect(attemptCalls, 1);

    now = now.add(const Duration(seconds: 30));
    await manager.drain(); // attempt 2 (fails)
    expect(attemptCalls, 2);

    now = now.add(const Duration(seconds: 30));
    await manager.drain(); // attempt 3 (fails) -> exhausts maxAttempts
    expect(attemptCalls, 3);

    expect(store.pendingCount(), 0);
    expect(store.failedCount(), 1);

    now = now.add(const Duration(seconds: 30));
    await manager.drain();
    expect(attemptCalls, 3); // failed mutations aren't retried automatically
  });

  group('isRetryable classification', () {
    test('a 409 stock conflict on placeOrder fails immediately, skipping the attempt budget', () async {
      final store = CartSyncStore();
      await store.enqueue(placeOrderMutation('order1'));

      var placeOrderCalls = 0;
      final manager = buildManager(
        store,
        placeOrder: () async {
          placeOrderCalls++;
          throw const ApiException('Insufficient stock for: Widget', statusCode: 409);
        },
        maxAttempts: 5,
      );

      await manager.drain();

      expect(placeOrderCalls, 1);
      expect(store.pendingCount(), 0);
      expect(store.failedCount(), 1);
    });

    test('a 5xx failure on placeOrder still uses the normal backoff/retry path', () async {
      final store = CartSyncStore();
      await store.enqueue(placeOrderMutation('order1'));

      final manager = buildManager(
        store,
        placeOrder: () async => throw const ApiException('Server error', statusCode: 500),
        maxAttempts: 5,
      );

      await manager.drain();

      expect(store.pendingCount(), 1);
      expect(store.failedCount(), 0);
    });
  });

  test('retryFailed resets attempts and syncs on success', () async {
    final store = CartSyncStore();
    await store.enqueue(addMutation('m1'));

    var shouldFail = true;
    final manager = buildManager(
      store,
      addToCart: ({required productId, required quantity}) async {
        if (shouldFail) throw Exception('network error');
        return 'server-1';
      },
      maxAttempts: 1,
    );

    await manager.drain();
    expect(store.failedCount(), 1);

    shouldFail = false;
    await manager.retryFailed();

    expect(store.failedCount(), 0);
    expect(store.pendingCount(), 0);
  });
}
