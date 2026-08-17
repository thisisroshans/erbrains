import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/order.dart';
import '../../design_system/nocturne.dart';
import 'orders_providers.dart';

/// Screen 10 · Order history.
///
/// There's no shipped/delivered lifecycle on the backend — every order is
/// created as `status: 'completed'` and never transitions (matches the
/// PDF's scope: no real fulfillment pipeline). The mock screens show
/// Shipped/Processing variants; this only renders what the backend
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
                    itemBuilder: (context, i) => _OrderCard(order: orders[i]),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(order.createdAt);
    final itemsLabel = '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ';

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
                variant: order.status == 'completed'
                    ? NocturneTagVariant.accent
                    : NocturneTagVariant.outline,
              ),
            ],
          ),
          Text(
            '$dateLabel · $itemsLabel\$${order.totalAmount.toStringAsFixed(2)}',
            style: NocturneType.caption,
          ),
        ],
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
