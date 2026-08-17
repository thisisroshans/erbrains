import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/health_sync/health_sync_providers.dart';
import '../../core/models/health_reading.dart';
import '../../core/models/health_summary.dart';
import '../../core/providers/wearable_providers.dart';

part 'history_providers.g.dart';

/// Recent readings for the device, newest first — read straight from the
/// local store, not the network. History works fully offline this way,
/// and reflects readings that haven't synced yet (there's exactly one
/// device per app session, so no `userId` filter is needed here — that
/// scoping already happened when the reading was captured).
@riverpod
Stream<List<HealthReading>> recentHealthReadings(Ref ref) async* {
  final store = ref.watch(healthReadingLocalStoreProvider);
  final deviceId = ref.watch(wearableServiceProvider).deviceId;

  List<HealthReading> read() => store.recent(deviceId: deviceId);

  yield read();
  await for (final _ in store.watch()) {
    yield read();
  }
}

/// Client-side equivalent of `GET /health/summary`, computed from the
/// local store (see [HealthReadingLocalStore.summary]) for the same
/// offline-first reason.
@riverpod
Stream<List<HealthSummaryPoint>> healthSummary(Ref ref, String period) async* {
  final store = ref.watch(healthReadingLocalStoreProvider);
  final deviceId = ref.watch(wearableServiceProvider).deviceId;

  List<HealthSummaryPoint> compute() => store.summary(deviceId: deviceId, period: period);

  yield compute();
  await for (final _ in store.watch()) {
    yield compute();
  }
}
