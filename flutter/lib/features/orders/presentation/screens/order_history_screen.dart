import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/datasources/remote/api_exception.dart';
import '../../../../core/domain/entities/order.dart';
import '../../../../design_system/nocturne.dart';
import '../controllers/orders_controller.dart';

/// Screen 10 · Order history.
///
/// There's still no shipped/delivered fulfillment pipeline on the backend
/// (matches the PDF's scope) — every order is created as
/// `status: 'completed'`. It can transition once, to `cancelled`, via
/// [OrderCancellation]; the mock screens show Shipped/Processing variants
/// this doesn't have, but this only ever renders what the backend
/// actually reports.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(userId));

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Orders', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: ordersAsync.when(
          data: (orders) => orders.isEmpty
              ? Center(child: Text('No orders yet', style: NocturneType.caption))
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(ordersProvider(userId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _OrderCard(order: orders[i], userId: userId),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Could not load orders: $err', style: NocturneType.caption),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.userId});

  final Order order;
  final String userId;

  static const _tagVariants = {
    'completed': NocturneTagVariant.accent,
    'cancelled': NocturneTagVariant.neutral,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = DateFormat('MMM d').format(order.createdAt);
    final itemsLabel = '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ';
    final cancelling = ref.watch(orderCancellationProvider);
    final cancellable = order.status != 'cancelled';

    return NocturneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: NocturneColors.text),
              ),
              NocturneTag(
                label: _titleCase(order.status),
                variant: _tagVariants[order.status] ?? NocturneTagVariant.outline,
              ),
            ],
          ),
          Text(
            '$dateLabel · $itemsLabel\$${order.totalAmount.toStringAsFixed(2)}',
            style: NocturneType.caption,
          ),
          if (cancellable)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: cancelling ? null : () => _cancel(context, ref),
                child: Text(cancelling ? 'Cancelling…' : 'Cancel order', style: NocturneType.caption),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(orderCancellationProvider.notifier).cancel(orderId: order.id, userId: userId);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
