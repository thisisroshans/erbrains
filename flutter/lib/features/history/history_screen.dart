import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/health_summary.dart';
import '../../design_system/nocturne.dart';
import 'history_providers.dart';
import 'widgets/mini_bar_chart.dart';
import 'widgets/mini_line_chart.dart';

enum _Period { daily, weekly }

/// Screen 04 · History.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Period _period = _Period.daily;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      healthSummaryProvider(widget.userId, _period.name),
    );
    final recentAsync = ref.watch(recentHealthReadingsProvider(widget.userId));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthSummaryProvider(widget.userId, _period.name));
          ref.invalidate(recentHealthReadingsProvider(widget.userId));
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('History', style: NocturneType.h4),
            const SizedBox(height: 14),
            NocturneSegmentedControl<_Period>(
              value: _period,
              options: const [
                NocturneSegmentOption(label: 'Daily', value: _Period.daily),
                NocturneSegmentOption(label: 'Weekly', value: _Period.weekly),
              ],
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (points) => _SummaryCharts(points: points),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => _ErrorNote(message: '$err'),
            ),
            const SizedBox(height: 16),
            const NocturneCardKicker('Recent readings'),
            const SizedBox(height: 4),
            recentAsync.when(
              data: (readings) => Column(
                children: [
                  for (final r in readings)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: NocturneColors.neutral800),
                        ),
                      ),
                      child: Text(
                        '${_timeLabel(r.timestamp)} · HR ${r.heartRate} · SpO₂ ${r.spo2}%',
                        style: NocturneType.bodySmall,
                      ),
                    ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => _ErrorNote(message: '$err'),
            ),
            const SizedBox(height: 8),
            Text(
              'Showing the latest 20 readings — older data loads in paged '
              'chunks, never all at once.',
              style: NocturneType.micro,
            ),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _SummaryCharts extends StatelessWidget {
  const _SummaryCharts({required this.points});

  final List<HealthSummaryPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return NocturneCard(
        child: Text('No readings yet for this period.', style: NocturneType.caption),
      );
    }

    final avgHr =
        (points.map((p) => p.avgHeartRate).reduce((a, b) => a + b) / points.length)
            .round();
    final peakHr = points.map((p) => p.maxHeartRate).reduce((a, b) => a > b ? a : b);
    final avgSpo2 =
        (points.map((p) => p.avgSpo2).reduce((a, b) => a + b) / points.length)
            .round();
    final minSpo2 = points.map((p) => p.minSpo2).reduce((a, b) => a < b ? a : b);

    return Column(
      spacing: 12,
      children: [
        NocturneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const NocturneCardKicker('Heart rate'),
              MiniLineChart(
                values: points.map((p) => p.avgHeartRate.toDouble()).toList(),
              ),
              Text('Avg $avgHr BPM · Peak $peakHr BPM', style: NocturneType.caption),
            ],
          ),
        ),
        NocturneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const NocturneCardKicker('SpO₂'),
              MiniLineChart(
                values: points.map((p) => p.avgSpo2.toDouble()).toList(),
                height: 40,
              ),
              Text('Avg $avgSpo2% · Min $minSpo2%', style: NocturneType.caption),
            ],
          ),
        ),
        NocturneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const NocturneCardKicker('Steps'),
              MiniBarChart(
                values: points.map((p) => p.totalSteps.toDouble()).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return NocturneCard(
      borderColor: NocturneColors.neutral600,
      child: Text('Could not load: $message', style: NocturneType.caption),
    );
  }
}
