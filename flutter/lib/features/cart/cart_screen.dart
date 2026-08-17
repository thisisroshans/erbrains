import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/cart.dart';
import '../../design_system/nocturne.dart';
import '../checkout/checkout_screen.dart';
import '../shop/widgets/product_image_placeholder.dart';
import 'cart_provider.dart';

/// Flat display-only shipping estimate. The backend's order total is the
/// cart subtotal only (no shipping column on `orders`) — see
/// docs/API_GAPS.md. Shown here to match the design, but never sent to
/// the API; Checkout's "Place order" charges the subtotal, not this total.
const double _kDisplayShipping = 5.00;

/// Screen 08 · Cart.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartProvider(userId));

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Cart', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: state.isLoading && state.cart.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.cart.items.isEmpty
                ? Center(
                    child: Text('Your cart is empty', style: NocturneType.caption),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      for (final item in state.cart.items) ...[
                        _CartLine(item: item, userId: userId),
                        const Divider(height: 24, color: NocturneColors.neutral800),
                      ],
                      _SummaryRow(label: 'Subtotal', value: state.cart.totalAmount),
                      _SummaryRow(label: 'Shipping', value: _kDisplayShipping),
                      const SizedBox(height: 4),
                      _SummaryRow(
                        label: 'Total',
                        value: state.cart.totalAmount + _kDisplayShipping,
                        emphasize: true,
                      ),
                      const SizedBox(height: 16),
                      NocturneButton(
                        label: 'Checkout',
                        block: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(userId: userId),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item, required this.userId});

  final CartItem item;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        ProductImagePlaceholder(label: item.name, height: 60, borderRadius: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: NocturneType.bodySmall.copyWith(fontWeight: FontWeight.w500)),
              Text('\$${item.price.toStringAsFixed(2)}', style: NocturneType.caption),
              const SizedBox(height: 6),
              NocturneStepper(
                value: item.quantity,
                size: 22,
                onIncrement: () => ref
                    .read(cartProvider(userId).notifier)
                    .addToCart(productId: item.productId, quantity: 1),
                // The backend has no decrement/remove endpoint yet (only an
                // upsert-and-increment POST /cart) — see docs/API_GAPS.md.
                onDecrement: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Decreasing quantity isn't supported by the backend yet"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: NocturneColors.text)
        : NocturneType.bodySmall.copyWith(color: NocturneColors.neutral300);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
