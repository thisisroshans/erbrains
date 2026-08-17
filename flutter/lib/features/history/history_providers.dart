import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/health_reading.dart';
import '../../core/models/health_summary.dart';
import '../../core/providers/core_providers.dart';

part 'history_providers.g.dart';

@riverpod
Future<List<HealthSummaryPoint>> healthSummary(
  Ref ref,
  String userId,
  String period,
) async {
  final api = ref.watch(apiClientProvider);
  final rows = await api.getHealthSummary(userId: userId, period: period);
  return rows
      .map((e) => HealthSummaryPoint.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// The most recent readings, paged server-side — matches screen 04's note
/// ("Showing latest 20 of 1,240 readings — older data loads in paged
/// chunks, never all at once").
@riverpod
Future<List<HealthReading>> recentHealthReadings(Ref ref, String userId) async {
  final api = ref.watch(apiClientProvider);
  final json = await api.getHealthReadings(userId: userId, page: 1, limit: 20);
  final rows = json['data'] as List<dynamic>;
  return rows.map((e) {
    final row = e as Map<String, dynamic>;
    return HealthReading.fromApiJson(row, row['id'] as String);
  }).toList();
}
