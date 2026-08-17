/// A single wearable reading, and the device's only local record of it.
/// Mirrors the PDF's example payload: `{ deviceId, heartRate, spo2, steps,
/// timestamp }`.
///
/// [localId] is a client-generated id (uuid v4) used only as the Hive key
/// and queue-bookkeeping identity. The backend dedupes on the
/// `(device_id, reading_timestamp)` pair, not a client id — see
/// docs/API_GAPS.md — so [localId] never leaves the device and never
/// appears in a request body.
class HealthReading {
  const HealthReading({
    required this.localId,
    required this.deviceId,
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.timestamp,
    this.syncStatus = SyncStatus.pending,
    this.attempts = 0,
  });

  final String localId;
  final String deviceId;
  final int heartRate;
  final int spo2;
  final int steps;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  /// Consecutive failed sync attempts for this specific reading. Resets
  /// to 0 on a successful batch; once it hits [SyncManager.maxAttempts]
  /// the reading moves to [SyncStatus.failed] and stops being included in
  /// automatic drain batches until a manual retry resets it.
  final int attempts;

  HealthReading copyWith({SyncStatus? syncStatus, int? attempts}) {
    return HealthReading(
      localId: localId,
      deviceId: deviceId,
      heartRate: heartRate,
      spo2: spo2,
      steps: steps,
      timestamp: timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toSyncJson() => {
        'deviceId': deviceId,
        'heartRate': heartRate,
        'spo2': spo2,
        'steps': steps,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toHiveMap() => {
        'local_id': localId,
        'device_id': deviceId,
        'heart_rate': heartRate,
        'spo2': spo2,
        'steps': steps,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'sync_status': syncStatus.name,
        'attempts': attempts,
      };

  factory HealthReading.fromHiveMap(Map<dynamic, dynamic> row) => HealthReading(
        localId: row['local_id'] as String,
        deviceId: row['device_id'] as String,
        heartRate: row['heart_rate'] as int,
        spo2: row['spo2'] as int,
        steps: row['steps'] as int,
        timestamp: DateTime.parse(row['timestamp'] as String),
        syncStatus: SyncStatus.values.firstWhere(
          (s) => s.name == row['sync_status'],
          orElse: () => SyncStatus.pending,
        ),
        attempts: (row['attempts'] as int?) ?? 0,
      );
}

enum SyncStatus { pending, syncing, failed, synced }
