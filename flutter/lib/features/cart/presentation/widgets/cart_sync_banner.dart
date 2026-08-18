import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/cart_sync/cart_sync_providers.dart';
import '../../../../design_system/nocturne.dart';
import 'cart_sync_failed_sheet.dart';

/// The cart/order equivalent of [SyncBanner] — shown on the Cart and
/// Checkout screens specifically rather than globally, since cart writes
/// only happen while the user is actively shopping/checking out (unlike
/// health readings, which arrive continuously in the background). Renders
/// nothing once the queue is empty.
class CartSyncBanner extends ConsumerWidget {
  const CartSyncBanner({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCartMutationsCountProvider).valueOrNull ?? 0;
    final failed = ref.watch(failedCartMutationsCountProvider).valueOrNull ?? 0;

    if (pending == 0 && failed == 0) return const SizedBox.shrink();

    final isFailed = failed > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFailed
            ? () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CartSyncFailedSheet(userId: userId),
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
                      ? '$failed cart change${failed == 1 ? '' : 's'} failed to sync — tap to review'
                      : '$pending cart change${pending == 1 ? '' : 's'} waiting to sync',
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
