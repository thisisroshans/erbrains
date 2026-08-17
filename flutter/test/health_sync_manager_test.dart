import 'dart:io';

import 'package:fitring/core/health_sync/health_reading_local_store.dart';
import 'package:fitring/core/health_sync/sync_manager.dart';
import 'package:fitring/core/models/health_reading.dart';
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
      sendBatch: (batch) async => sendCalls++,
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
      sendBatch: (batch) async => sendCalls++,
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
      sendBatch: (batch) async {},
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
      },
    );

    await manager.drain();

    expect(synced, unorderedEquals(['r1', 'r2', 'r3']));
    expect(store.pendingCount(), 0);
  });
}
