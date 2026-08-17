import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/wearable_providers.dart';
import '../../../../core/wearable/wearable_connection_state.dart';
import '../../../../design_system/nocturne.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../connection/presentation/screens/connection_screen.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';

/// Screen 02 · Dashboard. Live vitals come straight from the wearable
/// stream (never the backend) — see docs/API_GAPS.md: battery and
/// connection status are device-layer telemetry per the PDF's
/// wearable-simulation spec, not part of the health-data API.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wearableServiceProvider).connect());
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final connection = ref.watch(wearableConnectionProvider);
    final latest = ref.watch(wearableReadingProvider);
    final deviceId = ref.watch(wearableServiceProvider).deviceId;

    final connected = connection.valueOrNull == WearableConnectionState.connected;
    final snapshot = latest.valueOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: NocturneType.caption),
                    Text(user?.displayName ?? '', style: NocturneType.h4),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                  ),
                  child: NocturneTag(
                    label: connected ? 'Connected' : 'Disconnected',
                    leading: '●',
                    variant: connected
                        ? NocturneTagVariant.accent
                        : NocturneTagVariant.neutral,
                  ),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricCard(
                  icon: PhosphorIconsFill.heartbeat,
                  value: snapshot != null ? '${snapshot.heartRate}' : '—',
                  unit: 'BPM',
                  label: 'Heart Rate',
                ),
                _MetricCard(
                  icon: PhosphorIconsFill.drop,
                  value: snapshot != null ? '${snapshot.spo2}%' : '—',
                  label: 'SpO₂',
                ),
                _MetricCard(
                  icon: PhosphorIconsFill.footprints,
                  value: snapshot != null ? _formatSteps(snapshot.steps) : '—',
                  label: 'Steps',
                ),
                _MetricCard(
                  icon: _batteryIcon(snapshot?.batteryPercent),
                  value: snapshot != null ? '${snapshot.batteryPercent}%' : '—',
                  label: 'Battery',
                ),
              ],
            ),
            NocturneCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SyncStatusScreen(userId: widget.userId)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NocturneCardKicker('Device'),
                      NocturneCardTitle(deviceId, fontSize: 14),
                    ],
                  ),
                  NocturneTag(
                    label: snapshot != null
                        ? _lastReadingLabel(snapshot.timestamp)
                        : 'No readings yet',
                    variant: NocturneTagVariant.outline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatSteps(int steps) {
    if (steps < 1000) return '$steps';
    final thousands = steps / 1000;
    return '${thousands.toStringAsFixed(steps % 1000 == 0 ? 0 : 1)}k';
  }

  static IconData _batteryIcon(int? percent) {
    if (percent == null) return PhosphorIconsRegular.batteryHigh;
    if (percent > 60) return PhosphorIconsRegular.batteryFull;
    if (percent > 20) return PhosphorIconsRegular.batteryMedium;
    return PhosphorIconsRegular.batteryLow;
  }

  // Deliberately "last reading," not "synced" — this reflects the local
  // wearable stream, not backend sync state (that's what SyncBanner /
  // SyncStatusScreen are for). Conflating the two here would say "Synced
  // 0s ago" while genuinely offline, which is actively wrong.
  static String _lastReadingLabel(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Last reading ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Last reading ${diff.inMinutes}m ago';
    return 'Last reading ${diff.inHours}h ago';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return NocturneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: NocturneColors.accent800,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: NocturneColors.accent300),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: NocturneColors.text,
                    fontFamily: 'Inter',
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: NocturneType.caption,
                  ),
              ],
            ),
          ),
          Text(label, style: NocturneType.caption),
        ],
      ),
    );
  }
}
