import 'package:hive_flutter/hive_flutter.dart';

import '../domain/entities/health_reading.dart';
import '../domain/entities/health_summary.dart';
import '../offline/hive_boxes.dart';

/// The device's local health-data store — this IS the offline copy the
/// PDF's "Local Health Data" section asks for, not a cache of a server
/// response. Every reading the wearable ever produced lives here, synced
/// or not; the History screen reads straight from it (see
/// history_providers.dart) so it works with zero network dependency.
class HealthReadingLocalStore {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.healthReadings);

  Future<void> insert(HealthReading reading) async {
    await _box.put(reading.localId, reading.toHiveMap());
  }

  List<HealthReading> _all() => _box.values
      .map((v) => HealthReading.fromHiveMap(v as Map<dynamic, dynamic>))
      .toList();

  /// Most recent readings for a device, newest first, capped at [limit] —
  /// mirrors the PDF's "don't load unlimited raw records" requirement at
  /// the storage layer instead of just the widget layer.
  List<HealthReading> recent({required String deviceId, int limit = 20}) {
    final items = _all().where((r) => r.deviceId == deviceId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.length > limit ? items.sublist(0, limit) : items;
  }

  /// Readings not yet confirmed synced, oldest first (write order) —
  /// what [SyncManager] drains.
  List<HealthReading> pendingForSync({int limit = 50}) {
    final items = _all().where((r) => r.syncStatus == SyncStatus.pending).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items.length > limit ? items.sublist(0, limit) : items;
  }

  int pendingCount() => _all().where((r) => r.syncStatus == SyncStatus.pending).length;

  int failedCount() => _all().where((r) => r.syncStatus == SyncStatus.failed).length;

  Future<void> markSynced(Iterable<String> localIds) async {
    for (final id in localIds) {
      final reading = _get(id);
      if (reading == null) continue;
      await _box.put(
        id,
        reading.copyWith(syncStatus: SyncStatus.synced, attempts: 0).toHiveMap(),
      );
    }
  }

  /// Increments each reading's attempt counter; readings that hit
  /// [maxAttempts] move to [SyncStatus.failed] and drop out of future
  /// automatic batches until [retryFailed] resets them.
  Future<void> recordFailedAttempt(Iterable<String> localIds, {required int maxAttempts}) async {
    for (final id in localIds) {
      final reading = _get(id);
      if (reading == null) continue;
      final attempts = reading.attempts + 1;
      final status = attempts >= maxAttempts ? SyncStatus.failed : SyncStatus.pending;
      await _box.put(id, reading.copyWith(attempts: attempts, syncStatus: status).toHiveMap());
    }
  }

  /// User-initiated retry from the sync banner's failed sheet — resets
  /// every failed reading back to pending with a full attempt budget.
  Future<void> retryFailed() async {
    for (final reading in _all()) {
      if (reading.syncStatus != SyncStatus.failed) continue;
      await _box.put(
        reading.localId,
        reading.copyWith(syncStatus: SyncStatus.pending, attempts: 0).toHiveMap(),
      );
    }
  }

  /// User-initiated discard from the sync banner's failed sheet — deletes
  /// readings that exhausted their retry budget rather than retrying them
  /// forever. A real data loss, not a display filter: once discarded,
  /// that vital's history has a gap.
  Future<void> discardFailed() async {
    final failedIds = _all()
        .where((r) => r.syncStatus == SyncStatus.failed)
        .map((r) => r.localId)
        .toList();
    await _box.deleteAll(failedIds);
  }

  HealthReading? _get(String localId) {
    final raw = _box.get(localId);
    return raw == null ? null : HealthReading.fromHiveMap(raw as Map<dynamic, dynamic>);
  }

  /// Fires on every insert/update — sync status providers and the History
  /// screen both watch this to stay live without polling.
  Stream<void> watch() => _box.watch().map((_) {});

  /// Client-side equivalent of the backend's `GET /health/summary` query
  /// (see api/app.js), computed from local data so History works fully
  /// offline and includes readings that haven't synced yet. Groups the
  /// last 7 days by day or ISO week (UTC, matching Postgres's default
  /// session timezone for `DATE_TRUNC`).
  List<HealthSummaryPoint> summary({required String deviceId, required String period}) {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final readings = _all()
        .where((r) => r.deviceId == deviceId && r.timestamp.toUtc().isAfter(cutoff))
        .toList();

    final buckets = <DateTime, List<HealthReading>>{};
    for (final reading in readings) {
      final key = period == 'weekly'
          ? _startOfIsoWeek(reading.timestamp.toUtc())
          : _startOfDay(reading.timestamp.toUtc());
      buckets.putIfAbsent(key, () => []).add(reading);
    }

    final points = buckets.entries.map((entry) {
      final rs = entry.value;
      final heartRates = rs.map((r) => r.heartRate).toList();
      final spo2s = rs.map((r) => r.spo2).toList();
      final steps = rs.map((r) => r.steps).toList();

      return HealthSummaryPoint(
        periodDate: entry.key,
        avgHeartRate: (heartRates.reduce((a, b) => a + b) / heartRates.length).round(),
        minHeartRate: heartRates.reduce((a, b) => a < b ? a : b),
        maxHeartRate: heartRates.reduce((a, b) => a > b ? a : b),
        avgSpo2: (spo2s.reduce((a, b) => a + b) / spo2s.length).round(),
        minSpo2: spo2s.reduce((a, b) => a < b ? a : b),
        // Steps is a running counter per reading (matches the wearable's
        // emitted shape); the bucket total is its max, same as the
        // backend's MAX(steps) — see api/app.js's /health/summary.
        totalSteps: steps.reduce((a, b) => a > b ? a : b),
      );
    }).toList()
      ..sort((a, b) => a.periodDate.compareTo(b.periodDate));

    return points;
  }

  static DateTime _startOfDay(DateTime utc) => DateTime.utc(utc.year, utc.month, utc.day);

  static DateTime _startOfIsoWeek(DateTime utc) {
    final day = _startOfDay(utc);
    // DateTime.weekday: Monday=1..Sunday=7 — matches ISO week / Postgres's
    // DATE_TRUNC('week', ...), which also starts on Monday.
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
