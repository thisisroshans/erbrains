/// A single wearable reading. Mirrors the PDF's example payload:
/// `{ deviceId, heartRate, spo2, steps, timestamp }`.
///
/// [localId] is a client-generated id (uuid v4) used as the local SQLite
/// primary key and sync-queue identity. The backend itself dedupes on the
/// `(device_id, reading_timestamp)` pair rather than a client id — see
/// docs/API_GAPS.md — so [localId] never leaves the device; it just lets
/// the local queue track retry/failure state per reading.
class HealthReading {
  const HealthReading({
    required this.localId,
    required this.deviceId,
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.timestamp,
    this.syncStatus = SyncStatus.pending,
  });

  final String localId;
  final String deviceId;
  final int heartRate;
  final int spo2;
  final int steps;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  HealthReading copyWith({SyncStatus? syncStatus}) {
    return HealthReading(
      localId: localId,
      deviceId: deviceId,
      heartRate: heartRate,
      spo2: spo2,
      steps: steps,
      timestamp: timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toSyncJson() => {
        'deviceId': deviceId,
        'heartRate': heartRate,
        'spo2': spo2,
        'steps': steps,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toDbRow() => {
        'local_id': localId,
        'device_id': deviceId,
        'heart_rate': heartRate,
        'spo2': spo2,
        'steps': steps,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'sync_status': syncStatus.name,
      };

  factory HealthReading.fromDbRow(Map<String, dynamic> row) => HealthReading(
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
      );

  factory HealthReading.fromApiJson(Map<String, dynamic> json, String localId) {
    return HealthReading(
      localId: localId,
      deviceId: json['device_id'] as String,
      heartRate: json['heart_rate'] as int,
      spo2: json['spo2'] as int,
      steps: json['steps'] as int,
      timestamp: DateTime.parse(json['reading_timestamp'] as String),
      syncStatus: SyncStatus.synced,
    );
  }
}

enum SyncStatus { pending, syncing, failed, synced }
