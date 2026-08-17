import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/health_sync/health_sync_providers.dart';
import '../../design_system/nocturne.dart';

/// Screen 05 · Offline sync.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? false;
    final pending = ref.watch(pendingReadingsCountProvider).valueOrNull ?? 0;
    final failed = ref.watch(failedReadingsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Sync Status', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            NocturneCard(
              borderColor: online ? NocturneColors.accent700 : NocturneColors.neutral600,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Icon(
                    online ? PhosphorIconsRegular.cloudCheck : PhosphorIconsRegular.cloudSlash,
                    color: online ? NocturneColors.accent300 : NocturneColors.neutral400,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          online ? 'Online' : 'No internet connection',
                          style: NocturneType.bodyMedium,
                        ),
                        Text(_statusSubtitle(pending, failed), style: NocturneType.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NocturneCardKicker('Sync queue'),
            const SizedBox(height: 8),
            if (pending == 0 && failed == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Nothing waiting to sync', style: NocturneType.caption),
                ),
              )
            else ...[
              if (pending > 0)
                _QueueRow(
                  label: '$pending reading${pending == 1 ? '' : 's'}',
                  tagLabel: 'Pending',
                  tagVariant: NocturneTagVariant.outline,
                ),
              if (failed > 0)
                _QueueRow(
                  label: '$failed reading${failed == 1 ? '' : 's'}',
                  tagLabel: 'Failed',
                  tagVariant: NocturneTagVariant.neutral,
                ),
            ],
            const SizedBox(height: 8),
            NocturneButton(
              label: 'Sync now',
              variant: NocturneButtonVariant.secondary,
              block: true,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              onPressed: pending == 0
                  ? null
                  : () => ref.read(syncManagerProvider(userId)).drain(),
            ),
            if (failed > 0) ...[
              const SizedBox(height: 8),
              NocturneButton(
                label: 'Retry failed',
                block: true,
                onPressed: () => ref.read(syncManagerProvider(userId)).retryFailed(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Readings sync in a batch to POST /health/readings. The backend '
              'dedupes on (deviceId, timestamp), so a retried batch can never '
              'create duplicates.',
              style: NocturneType.micro,
            ),
          ],
        ),
      ),
    );
  }

  // "Everything synced" is only true when both counts are zero — a
  // pending-only check here would claim success while readings sit
  // failed, which is exactly backwards for a screen whose whole job is
  // surfacing that.
  static String _statusSubtitle(int pending, int failed) {
    if (pending == 0 && failed == 0) return 'Everything synced';
    if (pending > 0 && failed > 0) {
      return '$pending pending · $failed failed';
    }
    if (failed > 0) {
      return '$failed reading${failed == 1 ? '' : 's'} failed to sync';
    }
    return '$pending reading${pending == 1 ? '' : 's'} queued locally';
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.label, required this.tagLabel, required this.tagVariant});

  final String label;
  final String tagLabel;
  final NocturneTagVariant tagVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NocturneColors.neutral800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NocturneType.bodySmall),
          NocturneTag(label: tagLabel, variant: tagVariant),
        ],
      ),
    );
  }
}
