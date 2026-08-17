import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/entities/health_reading.dart';
import '../wearable/wearable_service.dart';
import '../wearable/wearable_snapshot.dart';
import 'health_reading_local_store.dart';
import 'sync_manager.dart';

/// Ties the wearable's live reading stream to local storage and the sync
/// drain: every snapshot the mock device emits is written locally
/// immediately (this is what makes the app work offline at all — the
/// write never waits on the network), then a drain attempt follows. A
/// connectivity offline->online transition also triggers a drain.
class HealthSyncEngine {
  HealthSyncEngine({
    required this.wearableService,
    required this.store,
    required this.syncManager,
    required this.connectivityOnTransition,
  });

  final WearableService wearableService;
  final HealthReadingLocalStore store;
  final SyncManager syncManager;
  final Stream<bool> connectivityOnTransition;

  final _uuid = const Uuid();
  StreamSubscription<WearableSnapshot>? _readingsSub;
  StreamSubscription<bool>? _connectivitySub;

  void start() {
    _readingsSub = wearableService.readings.listen(_onSnapshot);
    _connectivitySub = connectivityOnTransition.listen((online) {
      if (online) syncManager.drain();
    });
    // Covers app launch: there may already be pending readings from a
    // previous session (e.g. the app was killed mid-drain).
    syncManager.drain();
  }

  void _onSnapshot(WearableSnapshot snapshot) {
    final reading = HealthReading(
      localId: _uuid.v4(),
      deviceId: wearableService.deviceId,
      heartRate: snapshot.heartRate,
      spo2: snapshot.spo2,
      steps: snapshot.steps,
      timestamp: snapshot.timestamp,
    );
    store.insert(reading).then((_) => syncManager.drain());
  }

  void dispose() {
    _readingsSub?.cancel();
    _connectivitySub?.cancel();
  }
}
