import 'dart:io';

import 'package:fitring/core/domain/entities/health_reading.dart';
import 'package:fitring/core/health_sync/health_reading_local_store.dart';
import 'package:fitring/core/health_sync/sync_manager.dart';
import 'package:fitring/core/offline/hive_boxes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Drain/retry logic for [SyncManager], exercised with fakes — no
/// network, no real device/plugin bindings. Only `Hive.init` (not
/// `initFlutter`, which needs path_provider platform channels) is needed
/// since these are box read/writes, not app-directory lookups.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitring_hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.healthReadings);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.healthReadings);
    await tempDir.delete(recursive: true);
  });

  HealthReading reading(String id, {DateTime? timestamp}) => HealthReading(
        localId: id,
        deviceId: 'FITRING-001',
        heartRate: 72,
        spo2: 98,
        steps: 100,
        timestamp: timestamp ?? DateTime.utc(2026, 1, 1),
      );

  test('registers the device before attempting to sync readings', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));

    var registerCalls = 0;
    var sendCalls = 0;

    final manager = SyncManager(
      store: store,
      registerDevice: () async => registerCalls++,
      sendBatch: (batch) async {
        sendCalls++;
        return List.filled(batch.length, true);
      },
    );

    await manager.drain();

    expect(registerCalls, 1);
    expect(sendCalls, 1);
    expect(store.pendingCount(), 0);
  });

  test('does not attempt readings sync if device registration fails', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));

    var sendCalls = 0;

    final manager = SyncManager(
      store: store,
      registerDevice: () async => throw Exception('offline'),
      sendBatch: (batch) async {
        sendCalls++;
        return List.filled(batch.length, true);
      },
    );

    await manager.drain();

    expect(sendCalls, 0);
    expect(store.pendingCount(), 1);
  });

  test('only registers the device once across multiple successful drains', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));
    await store.insert(reading('r2'));

    var registerCalls = 0;

    final manager = SyncManager(
      store: store,
      registerDevice: () async => registerCalls++,
      sendBatch: (batch) async => List.filled(batch.length, true),
    );

    await manager.drain(); // syncs r1 + r2 in one batch
    await store.insert(reading('r3'));
    await manager.drain(); // syncs r3

    expect(registerCalls, 1);
    expect(store.pendingCount(), 0);
  });

  test('a failed batch leaves readings pending (not failed) below maxAttempts', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));

    final manager = SyncManager(
      store: store,
      registerDevice: () async {},
      sendBatch: (batch) async => throw Exception('network error'),
      maxAttempts: 5,
    );

    await manager.drain();

    expect(store.pendingCount(), 1);
    expect(store.failedCount(), 0);
  });

  test('moves a reading to failed once it exhausts maxAttempts, and backoff blocks '
      'automatic retries before it elapses', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));

    var sendCalls = 0;
    var now = DateTime.utc(2026, 1, 1);

    final manager = SyncManager(
      store: store,
      registerDevice: () async {},
      sendBatch: (batch) async {
        sendCalls++;
        throw Exception('network error');
      },
      maxAttempts: 3,
      now: () => now,
    );

    await manager.drain(); // attempt 1 (fails) -> backoff scheduled
    expect(sendCalls, 1);

    // Calling again immediately (backoff not elapsed) must not re-attempt.
    await manager.drain();
    expect(sendCalls, 1);

    now = now.add(const Duration(seconds: 30)); // past any backoff window
    await manager.drain(); // attempt 2 (fails)
    expect(sendCalls, 2);

    now = now.add(const Duration(seconds: 30));
    await manager.drain(); // attempt 3 (fails) -> exhausts maxAttempts
    expect(sendCalls, 3);

    expect(store.pendingCount(), 0);
    expect(store.failedCount(), 1);

    // Further drains don't touch a failed reading automatically.
    now = now.add(const Duration(seconds: 30));
    await manager.drain();
    expect(sendCalls, 3);
  });

  test('retryFailed resets attempts and syncs on success', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));

    var shouldFail = true;

    final manager = SyncManager(
      store: store,
      registerDevice: () async {},
      sendBatch: (batch) async {
        if (shouldFail) throw Exception('network error');
        return List.filled(batch.length, true);
      },
      maxAttempts: 1, // fails straight to `failed` on the first attempt
    );

    await manager.drain();
    expect(store.failedCount(), 1);

    shouldFail = false;
    await manager.retryFailed();

    expect(store.failedCount(), 0);
    expect(store.pendingCount(), 0);
  });

  test('a successful batch marks every reading in it synced', () async {
    final store = HealthReadingLocalStore();
    await store.insert(reading('r1'));
    await store.insert(reading('r2'));
    await store.insert(reading('r3'));

    final synced = <String>[];

    final manager = SyncManager(
      store: store,
      registerDevice: () async {},
      sendBatch: (batch) async {
        synced.addAll(batch.map((r) => r.localId));
        return List.filled(batch.length, true);
      },
    );

    await manager.drain();

    expect(synced, unorderedEquals(['r1', 'r2', 'r3']));
    expect(store.pendingCount(), 0);
  });

  group('per-reading duplicate reconciliation', () {
    test('marks accepted readings synced and duplicates as duplicate, not pending', () async {
      final store = HealthReadingLocalStore();
      await store.insert(reading('new1'));
      await store.insert(reading('dup1'));
      await store.insert(reading('new2'));

      final manager = SyncManager(
        store: store,
        registerDevice: () async {},
        // Mirrors the backend's `results` order: batch[1] ('dup1') is the
        // only duplicate.
        sendBatch: (batch) async => batch.map((r) => r.localId != 'dup1').toList(),
      );

      await manager.drain();

      expect(store.pendingCount(), 0);
      expect(store.failedCount(), 0);

      final all = store.recent(deviceId: 'FITRING-001', limit: 10);
      expect(all.firstWhere((r) => r.localId == 'new1').syncStatus, SyncStatus.synced);
      expect(all.firstWhere((r) => r.localId == 'new2').syncStatus, SyncStatus.synced);
      expect(all.firstWhere((r) => r.localId == 'dup1').syncStatus, SyncStatus.duplicate);
    });

    test('falls back to marking the whole batch synced if the response length is malformed', () async {
      final store = HealthReadingLocalStore();
      await store.insert(reading('r1'));
      await store.insert(reading('r2'));

      final manager = SyncManager(
        store: store,
        registerDevice: () async {},
        sendBatch: (batch) async => [true], // wrong length for a 2-item batch
      );

      await manager.drain();

      expect(store.pendingCount(), 0);
      final all = store.recent(deviceId: 'FITRING-001', limit: 10);
      expect(all.every((r) => r.syncStatus == SyncStatus.synced), isTrue);
    });
  });

  group('evictSyncedOlderThan', () {
    test('deletes only synced readings past the retention window', () async {
      final store = HealthReadingLocalStore();
      final now = DateTime.utc(2026, 2, 1);

      await store.insert(reading('old-synced', timestamp: now.subtract(const Duration(days: 40))));
      await store.insert(reading('recent-synced', timestamp: now.subtract(const Duration(days: 5))));
      await store.insert(reading('old-pending', timestamp: now.subtract(const Duration(days: 40))));

      final manager = SyncManager(
        store: store,
        registerDevice: () async {},
        sendBatch: (batch) async => List.filled(batch.length, true),
      );
      await manager.drain(); // marks all three synced
      await store.recordFailedAttempt(['old-pending'], maxAttempts: 999); // put it back to pending

      final evicted = await store.evictSyncedOlderThan(const Duration(days: 30), now: () => now);

      expect(evicted, 1);
      final remainingIds = store.recent(deviceId: 'FITRING-001', limit: 100).map((r) => r.localId);
      expect(remainingIds, containsAll(['recent-synced', 'old-pending']));
      expect(remainingIds, isNot(contains('old-synced')));
    });

    test('never evicts failed readings regardless of age', () async {
      final store = HealthReadingLocalStore();
      await store.insert(reading('r1', timestamp: DateTime.utc(2020, 1, 1)));

      final manager = SyncManager(
        store: store,
        registerDevice: () async {},
        sendBatch: (batch) async => throw Exception('network error'),
        maxAttempts: 1,
      );
      await manager.drain(); // -> failed immediately (maxAttempts: 1)
      expect(store.failedCount(), 1);

      final evicted = await store.evictSyncedOlderThan(const Duration(days: 1));

      expect(evicted, 0);
      expect(store.failedCount(), 1);
    });
  });
}
