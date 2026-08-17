import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/health_sync/health_sync_providers.dart';
import '../../../../design_system/nocturne.dart';
import 'sync_failed_sheet.dart';

/// A slim strip above every screen in [RootShell] — "N readings waiting
/// to sync" while pending, switching to a failed state (tappable, opens
/// [SyncFailedSheet]) once anything exhausts its retry budget. Renders
/// nothing when the queue is empty, which is the common case once online.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingReadingsCountProvider).valueOrNull ?? 0;
    final failed = ref.watch(failedReadingsCountProvider).valueOrNull ?? 0;

    if (pending == 0 && failed == 0) return const SizedBox.shrink();

    final isFailed = failed > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFailed
            ? () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SyncFailedSheet(userId: userId),
                )
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isFailed ? NocturneColors.neutral900 : NocturneColors.accent900,
          child: Row(
            children: [
              Icon(
                isFailed ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.cloudArrowUp,
                size: 14,
                color: isFailed ? NocturneColors.neutral300 : NocturneColors.accent300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFailed
                      ? '$failed reading${failed == 1 ? '' : 's'} failed to sync — tap to review'
                      : '$pending reading${pending == 1 ? '' : 's'} waiting to sync',
                  style: NocturneType.micro.copyWith(
                    color: isFailed ? NocturneColors.neutral300 : NocturneColors.accent300,
                  ),
                ),
              ),
              if (isFailed)
                const Icon(PhosphorIconsRegular.caretRight, size: 12, color: NocturneColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
