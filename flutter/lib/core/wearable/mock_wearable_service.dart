import 'dart:async';
import 'dart:math';

import 'reconnect_status.dart';
import 'wearable_connection_state.dart';
import 'wearable_service.dart';
import 'wearable_snapshot.dart';

/// Simulates a wearable per the PDF's section 2 & 4: connect / disconnect /
/// reconnect, battery, and periodic HR/SpO2/step readings — with an
/// exponential backoff retry (2s, 4s, 8s, 16s) that gives up to manual
/// reconnect after 4 automatic attempts, matching screen 03's copy.
class MockWearableService implements WearableService {
  MockWearableService({this.deviceId = 'FITRING-001'}) {
    _connectionController.add(WearableConnectionState.disconnected);
  }

  @override
  final String deviceId;

  static const List<int> _backoffSeconds = [2, 4, 8, 16];

  final _connectionController =
      StreamController<WearableConnectionState>.broadcast();
  final _readingsController = StreamController<WearableSnapshot>.broadcast();
  final _reconnectController = StreamController<ReconnectStatus?>.broadcast();

  final _rng = Random();

  Timer? _readingTimer;
  Timer? _retryTimer;
  int _attempt = 0;

  WearableConnectionState _state = WearableConnectionState.disconnected;

  int _heartRate = 76;
  int _spo2 = 98;
  int _steps = 6420;
  int _battery = 82;

  @override
  Stream<WearableConnectionState> get connectionState =>
      _connectionController.stream;

  @override
  Stream<WearableSnapshot> get readings => _readingsController.stream;

  @override
  Stream<ReconnectStatus?> get reconnectStatus => _reconnectController.stream;

  void _setState(WearableConnectionState state) {
    _state = state;
    _connectionController.add(state);
  }

  @override
  Future<void> connect() async {
    if (_state == WearableConnectionState.connected ||
        _state == WearableConnectionState.connecting) {
      return;
    }
    _cancelRetry();
    _setState(WearableConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 800));
    _attempt = 0;
    _setState(WearableConnectionState.connected);
    _startReadingsLoop();
  }

  @override
  Future<void> disconnect() async {
    _stopReadingsLoop();
    _cancelRetry();
    _reconnectController.add(null);
    _setState(WearableConnectionState.disconnected);
  }

  @override
  Future<void> reconnect() async {
    _cancelRetry();
    _attempt = 0;
    _reconnectController.add(null);
    _setState(WearableConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 600));
    _attempt = 0;
    _setState(WearableConnectionState.connected);
    _startReadingsLoop();
  }

  /// Not part of [WearableService] — a demo/test hook for exercising the
  /// disconnect → auto-reconnect → backoff flow without real hardware.
  void simulateDrop() {
    if (_state != WearableConnectionState.connected) return;
    _stopReadingsLoop();
    _attempt = 0;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_attempt >= _backoffSeconds.length) {
      _reconnectController.add(null);
      _setState(WearableConnectionState.connectionFailed);
      return;
    }

    _setState(WearableConnectionState.reconnecting);
    final delaySeconds = _backoffSeconds[_attempt];
    _attempt++;

    _reconnectController.add(
      ReconnectStatus(
        attempt: _attempt,
        maxAttempts: _backoffSeconds.length + 1,
        retryInSeconds: delaySeconds,
      ),
    );

    _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
      // ~70% chance the retry succeeds, so the UI has something to show
      // for both outcomes without needing real hardware.
      final succeeds = _rng.nextDouble() > 0.3;

      if (succeeds) {
        _setState(WearableConnectionState.connecting);
        await Future.delayed(const Duration(milliseconds: 500));
        _attempt = 0;
        _reconnectController.add(null);
        _setState(WearableConnectionState.connected);
        _startReadingsLoop();
      } else {
        _scheduleReconnect();
      }
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _startReadingsLoop() {
    _readingTimer?.cancel();
    _emitReading();
    _readingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _emitReading(),
    );
  }

  void _stopReadingsLoop() {
    _readingTimer?.cancel();
    _readingTimer = null;
  }

  void _emitReading() {
    _heartRate = (_heartRate + _rng.nextInt(5) - 2).clamp(55, 140);
    _spo2 = (_spo2 + _rng.nextInt(3) - 1).clamp(92, 100);
    _steps = _steps + _rng.nextInt(12);
    if (_rng.nextDouble() < 0.15) {
      _battery = (_battery - 1).clamp(0, 100);
    }

    _readingsController.add(
      WearableSnapshot(
        heartRate: _heartRate,
        spo2: _spo2,
        steps: _steps,
        batteryPercent: _battery,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _stopReadingsLoop();
    _cancelRetry();
    _connectionController.close();
    _readingsController.close();
    _reconnectController.close();
  }
}
