import '../domain/entities/health_reading.dart';
import 'health_reading_local_store.dart';

/// Drains [HealthReadingLocalStore]'s pending readings to the backend in
/// write order, batched (the backend's `POST /health/readings` already
/// accepts an array — no reason to send one request per reading).
///
/// [registerDevice] and [sendBatch] are injected rather than calling
/// [ApiClient] directly so this class can be drain-tested with fakes (see
/// test/health_sync_manager_test.dart) with no Hive/network/Riverpod in
/// the loop.
class SyncManager {
  SyncManager({
    required this.store,
    required this.registerDevice,
    required this.sendBatch,
    this.maxAttempts = 5,
    this.batchSize = 50,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HealthReadingLocalStore store;

  /// Idempotent upsert (`POST /devices`) — must succeed at least once
  /// before readings can sync, since `health_readings.device_id` is a
  /// foreign key. Throws on failure.
  final Future<void> Function() registerDevice;

  /// Throws on failure (network error or non-2xx). A batch is all-or-
  /// nothing: the endpoint either accepts the whole array or it doesn't,
  /// there's no per-reading result to act on individually.
  final Future<void> Function(List<HealthReading> batch) sendBatch;

  final int maxAttempts;
  final int batchSize;
  final DateTime Function() _now;

  static const _backoffSeconds = [2, 4, 8, 16, 30];

  bool _deviceRegistered = false;
  bool _isDraining = false;
  DateTime? _nextAttemptAt;

  bool get isDraining => _isDraining;

  /// Attempts to flush everything currently pending. Safe to call
  /// liberally — triggered by connectivity transitions, app launch,
  /// foreground resume, and a periodic timer; no-ops if a drain is
  /// already running, backoff hasn't elapsed, or there's nothing pending.
  Future<void> drain() async {
    if (_isDraining) return;
    if (_nextAttemptAt != null && _now().isBefore(_nextAttemptAt!)) return;

    _isDraining = true;
    try {
      if (!_deviceRegistered) {
        try {
          await registerDevice();
          _deviceRegistered = true;
        } catch (_) {
          _scheduleRetry(1);
          return;
        }
      }

      while (true) {
        final batch = store.pendingForSync(limit: batchSize);
        if (batch.isEmpty) {
          _nextAttemptAt = null;
          return;
        }

        try {
          await sendBatch(batch);
          await store.markSynced(batch.map((r) => r.localId));
          _nextAttemptAt = null;
        } catch (_) {
          await store.recordFailedAttempt(
            batch.map((r) => r.localId),
            maxAttempts: maxAttempts,
          );
          final worstAttempts = batch
              .map((r) => r.attempts + 1)
              .reduce((a, b) => a > b ? a : b);
          _scheduleRetry(worstAttempts);
          return;
        }
      }
    } finally {
      _isDraining = false;
    }
  }

  void _scheduleRetry(int attempts) {
    final seconds = _backoffSeconds[(attempts - 1).clamp(0, _backoffSeconds.length - 1)];
    _nextAttemptAt = _now().add(Duration(seconds: seconds));
  }

  /// User-initiated retry from the sync banner's failed sheet — full
  /// attempt budget restored, backoff cleared, drains immediately.
  Future<void> retryFailed() async {
    await store.retryFailed();
    _nextAttemptAt = null;
    await drain();
  }
}
