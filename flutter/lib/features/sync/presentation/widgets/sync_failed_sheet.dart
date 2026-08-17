import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health_sync/health_sync_providers.dart';
import '../../../../design_system/nocturne.dart';

/// `.dialog` at the top elevation, opened from [SyncBanner]. Aggregate,
/// not a per-mutation list — `POST /health/readings` is an all-or-nothing
/// batch with no per-reading result, so "failed" is a count, not a set of
/// individually inspectable rows.
class SyncFailedSheet extends ConsumerWidget {
  const SyncFailedSheet({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(failedReadingsCountProvider).valueOrNull ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: NocturneCard(
          elevation: NocturneElevation.lg,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('Sync failed', style: NocturneType.h5),
              Text(
                '$failed reading${failed == 1 ? '' : 's'} could not sync after repeated '
                'attempts. Retry now, or discard them — discarding is permanent and '
                'leaves a gap in that period\'s history.',
                style: NocturneType.bodySmall.copyWith(color: NocturneColors.neutral300),
              ),
              Row(
                children: [
                  Expanded(
                    child: NocturneButton(
                      label: 'Discard',
                      variant: NocturneButtonVariant.secondary,
                      block: true,
                      onPressed: () async {
                        await ref.read(healthReadingLocalStoreProvider).discardFailed();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NocturneButton(
                      label: 'Retry',
                      block: true,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await ref.read(syncManagerProvider(userId)).retryFailed();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
