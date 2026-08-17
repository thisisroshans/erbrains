import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../offline/connectivity_monitor.dart';
import '../providers/core_providers.dart';
import '../providers/wearable_providers.dart';
import 'health_reading_local_store.dart';
import 'health_sync_engine.dart';
import 'sync_manager.dart';

part 'health_sync_providers.g.dart';

@Riverpod(keepAlive: true)
HealthReadingLocalStore healthReadingLocalStore(Ref ref) => HealthReadingLocalStore();

@Riverpod(keepAlive: true)
ConnectivityMonitor connectivityMonitor(Ref ref) {
  final monitor = ConnectivityMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
}

@Riverpod(keepAlive: true)
SyncManager syncManager(Ref ref, String userId) {
  final api = ref.watch(apiClientProvider);
  final store = ref.watch(healthReadingLocalStoreProvider);
  final wearable = ref.watch(wearableServiceProvider);

  return SyncManager(
    store: store,
    registerDevice: () => api.registerDevice(
      deviceId: wearable.deviceId,
      name: 'FitRing Wearable',
      userId: userId,
    ),
    sendBatch: (batch) => api.syncHealthReadings(userId: userId, readings: batch),
  );
}

/// Current connectivity state, seeded with a real check (not just waiting
/// for the first transition) then updated on every transition after.
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) async* {
  final monitor = ref.watch(connectivityMonitorProvider);
  yield await monitor.isOnlineNow();
  yield* monitor.onTransition;
}

/// Live count of readings not yet confirmed synced — what the sync banner
/// shows. Re-emits on every local-store write, not polled.
@Riverpod(keepAlive: true)
Stream<int> pendingReadingsCount(Ref ref) async* {
  final store = ref.watch(healthReadingLocalStoreProvider);
  yield store.pendingCount();
  await for (final _ in store.watch()) {
    yield store.pendingCount();
  }
}

/// Live count of readings that exhausted their retry budget — what
/// switches the sync banner into its "failed" state.
@Riverpod(keepAlive: true)
Stream<int> failedReadingsCount(Ref ref) async* {
  final store = ref.watch(healthReadingLocalStoreProvider);
  yield store.failedCount();
  await for (final _ in store.watch()) {
    yield store.failedCount();
  }
}

/// Starts capturing readings + draining on connectivity change as soon as
/// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
/// once, right after login, so it runs for the whole authenticated
/// session regardless of which tab is active.
@Riverpod(keepAlive: true)
HealthSyncEngine healthSyncEngine(Ref ref, String userId) {
  final engine = HealthSyncEngine(
    wearableService: ref.watch(wearableServiceProvider),
    store: ref.watch(healthReadingLocalStoreProvider),
    syncManager: ref.watch(syncManagerProvider(userId)),
    connectivityOnTransition: ref.watch(connectivityMonitorProvider).onTransition,
  );
  engine.start();
  ref.onDispose(engine.dispose);
  return engine;
}
