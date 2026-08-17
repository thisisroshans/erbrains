/// A live vitals snapshot from the wearable — what the Dashboard renders
/// in real time. Distinct from [HealthReading]: this also carries battery,
/// which is device telemetry that never gets synced to the backend (the
/// PDF's wearable-simulation spec scopes battery to the device layer, not
/// the health-data API — see docs/API_GAPS.md).
class WearableSnapshot {
  const WearableSnapshot({
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.batteryPercent,
    required this.timestamp,
  });

  final int heartRate;
  final int spo2;
  final int steps;
  final int batteryPercent;
  final DateTime timestamp;
}
