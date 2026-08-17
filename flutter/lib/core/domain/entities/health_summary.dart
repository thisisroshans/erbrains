/// One bucket from `GET /health/summary` (grouped by day or week).
class HealthSummaryPoint {
  const HealthSummaryPoint({
    required this.periodDate,
    required this.avgHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.avgSpo2,
    required this.minSpo2,
    required this.totalSteps,
  });

  final DateTime periodDate;
  final int avgHeartRate;
  final int minHeartRate;
  final int maxHeartRate;
  final int avgSpo2;
  final int minSpo2;
  final int totalSteps;

  factory HealthSummaryPoint.fromJson(Map<String, dynamic> json) {
    return HealthSummaryPoint(
      periodDate: DateTime.parse(json['period_date'] as String),
      avgHeartRate: (json['avg_heart_rate'] as num).toInt(),
      minHeartRate: (json['min_heart_rate'] as num).toInt(),
      maxHeartRate: (json['max_heart_rate'] as num).toInt(),
      avgSpo2: (json['avg_spo2'] as num).toInt(),
      minSpo2: (json['min_spo2'] as num).toInt(),
      totalSteps: (json['total_steps'] as num).toInt(),
    );
  }
}
