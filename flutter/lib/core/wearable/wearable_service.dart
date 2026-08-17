import 'reconnect_status.dart';
import 'wearable_connection_state.dart';
import 'wearable_snapshot.dart';

/// The seam the PDF's architecture requirement asks for:
///
///   Flutter Application
///        |
///   Wearable Service / Interface   <- this contract
///        |
///   Mock Wearable Implementation   <- [MockWearableService]
///
/// Screens depend only on this interface. Swapping the mock for a real
/// device later means writing a `BleWearableService implements
/// WearableService` that talks to platform channels / a native plugin
/// (Android: Kotlin BLE APIs, iOS: CoreBluetooth via Swift) — no screen
/// code changes. See the Flutter README's "Wearable integration approach"
/// section for the platform-channel vs. native-plugin tradeoff.
abstract class WearableService {
  String get deviceId;

  /// Connection lifecycle: disconnected → connecting → connected, or the
  /// reconnecting/connectionFailed branch after a drop.
  Stream<WearableConnectionState> get connectionState;

  /// Live vitals, emitted periodically while connected.
  Stream<WearableSnapshot> get readings;

  /// Non-null only while [connectionState] is reconnecting.
  Stream<ReconnectStatus?> get reconnectStatus;

  Future<void> connect();
  Future<void> disconnect();

  /// User-initiated reconnect — always allowed, even after auto-retry has
  /// given up (the "Reconnect now" button on screen 03).
  Future<void> reconnect();

  void dispose();
}
