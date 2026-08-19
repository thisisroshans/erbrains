import 'package:flutter/services.dart';

import 'reconnect_status.dart';
import 'wearable_connection_state.dart';
import 'wearable_service.dart';
import 'wearable_snapshot.dart';

/// A real-SDK `WearableService` implementation — deliberately a **stub**,
/// not a working one: there's no physical wearable or vendor SDK for this
/// assignment, so this can't actually be finished. What it's for is making
/// the "this architecture is ready for a real SDK" claim in
/// docs/WEARABLE_INTEGRATION.md a visible seam in the repo instead of only
/// a paragraph of prose — the platform channel names, method shapes, and
/// exactly where native Kotlin/Swift code would plug in are all real and
/// concrete here, even though the bodies throw.
///
/// Not wired into the app anywhere — `wearableServiceProvider`
/// (`core/providers/wearable_providers.dart`) still constructs
/// [MockWearableService]. Swapping this in for real would mean:
///
/// 1. Deleting the `UnimplementedError` throws below and actually
///    implementing the native side — Kotlin using the vendor's BLE SDK
///    (`android/app/src/main/kotlin/.../WearablePlugin.kt`, not written)
///    on Android, Swift + CoreBluetooth on iOS.
/// 2. Registering the runtime permissions a real BLE integration needs —
///    `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` on Android 12+ (API 31+),
///    `NSBluetoothAlwaysUsageDescription` in `ios/Runner/Info.plist` —
///    see docs/WEARABLE_INTEGRATION.md for why neither exists today (the
///    mock never touches real Bluetooth, so neither is needed yet).
/// 3. Swapping the single line in `wearableServiceProvider` that
///    constructs `MockWearableService()` for `BleWearableService()`.
///    Zero screen changes — every screen already depends on
///    [WearableService], never the mock directly.
class BleWearableService implements WearableService {
  BleWearableService({this.deviceId = 'FITRING-001'});

  @override
  final String deviceId;

  /// Commands (connect/disconnect/reconnect) — Dart calls out, native
  /// code replies. Matches the [WearableService] method shapes 1:1.
  static const _methodChannel = MethodChannel('com.erbrains.fitring/wearable');

  /// Live streams (connection state, readings, reconnect status) — native
  /// code pushes events, Dart listens. Three separate channels rather than
  /// one multiplexed stream, matching the three separate Dart streams
  /// [WearableService] already declares.
  static const _connectionChannel = EventChannel('com.erbrains.fitring/wearable/connection');
  static const _readingsChannel = EventChannel('com.erbrains.fitring/wearable/readings');
  static const _reconnectChannel = EventChannel('com.erbrains.fitring/wearable/reconnect');

  @override
  Stream<WearableConnectionState> get connectionState =>
      throw UnimplementedError(
        'Requires a real vendor BLE SDK bridged over $_connectionChannel — '
        'see docs/WEARABLE_INTEGRATION.md',
      );

  @override
  Stream<WearableSnapshot> get readings => throw UnimplementedError(
        'Requires a real vendor BLE SDK bridged over $_readingsChannel — '
        'see docs/WEARABLE_INTEGRATION.md',
      );

  @override
  Stream<ReconnectStatus?> get reconnectStatus => throw UnimplementedError(
        'Requires a real vendor BLE SDK bridged over $_reconnectChannel — '
        'see docs/WEARABLE_INTEGRATION.md',
      );

  @override
  Future<void> connect() => _invokeUnimplemented('connect');

  @override
  Future<void> disconnect() => _invokeUnimplemented('disconnect');

  @override
  Future<void> reconnect() => _invokeUnimplemented('reconnect');

  @override
  void dispose() {}

  Future<Never> _invokeUnimplemented(String method) {
    // The real version would be:
    //   await _methodChannel.invokeMethod<void>(method);
    // left uncalled since there's no native handler registered for it —
    // calling through would just throw a MissingPluginException instead
    // of this clearer error.
    throw UnimplementedError(
      "'$method' requires a real vendor BLE SDK bridged over $_methodChannel — "
      'see docs/WEARABLE_INTEGRATION.md',
    );
  }
}
