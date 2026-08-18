import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cart_sync/cart_sync_providers.dart';
import '../../../../design_system/nocturne.dart';

/// Opened from [CartSyncBanner]. Aggregate, not a per-mutation list — same
/// reasoning as [SyncFailedSheet] for readings, just for cart/order writes.
class CartSyncFailedSheet extends ConsumerWidget {
  const CartSyncFailedSheet({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(failedCartMutationsCountProvider).valueOrNull ?? 0;

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
              Text('Cart sync failed', style: NocturneType.h5),
              Text(
                '$failed cart/order change${failed == 1 ? '' : 's'} could not sync after '
                'repeated attempts. Retry now, or discard — discarding is permanent and '
                'may leave your cart out of sync with what was actually ordered.',
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
                        await ref.read(cartSyncStoreProvider).discardFailed();
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
                        await ref.read(cartSyncManagerProvider(userId)).retryFailed();
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
