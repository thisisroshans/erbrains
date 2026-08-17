import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../wearable/mock_wearable_service.dart';
import '../wearable/reconnect_status.dart';
import '../wearable/wearable_connection_state.dart';
import '../wearable/wearable_service.dart';
import '../wearable/wearable_snapshot.dart';

part 'wearable_providers.g.dart';

/// The one [WearableService] instance for the app's lifetime — swap
/// [MockWearableService] for a real BLE implementation here and every
/// screen below keeps working unchanged (see [WearableService]'s doc).
@Riverpod(keepAlive: true)
WearableService wearableService(Ref ref) {
  final service = MockWearableService();
  ref.onDispose(service.dispose);
  return service;
}

@Riverpod(keepAlive: true)
Stream<WearableConnectionState> wearableConnection(Ref ref) {
  return ref.watch(wearableServiceProvider).connectionState;
}

@Riverpod(keepAlive: true)
Stream<WearableSnapshot> wearableReading(Ref ref) {
  return ref.watch(wearableServiceProvider).readings;
}

@Riverpod(keepAlive: true)
Stream<ReconnectStatus?> wearableReconnectStatus(Ref ref) {
  return ref.watch(wearableServiceProvider).reconnectStatus;
}
