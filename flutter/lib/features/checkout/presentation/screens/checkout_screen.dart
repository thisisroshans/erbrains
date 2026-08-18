import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/nocturne.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/widgets/cart_sync_banner.dart';
import '../../../orders/presentation/screens/order_history_screen.dart';
import '../controllers/checkout_controller.dart';

/// Screen 09 · Checkout.
///
/// The shipping-address and payment fields are UI-only: `orders` has no
/// shipping_address/payment columns on the backend (matches the PDF's "no
/// real payment gateway" scope) — see docs/DECISIONS.md. `POST /orders`
/// only takes `userId`; nothing typed here is actually sent.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // TextEditingControllers are widget-lifecycle objects, not app state —
  // they stay as plain fields even in a strictly-Riverpod app; only their
  // *values* would become provider state if anything actually read them.
  final _nameController = TextEditingController(text: '');
  final _addressController = TextEditingController(text: '');

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final outcome = await ref.read(checkoutSubmissionProvider.notifier).submit(widget.userId);
    if (!mounted) return;

    if (outcome == CheckoutOutcome.placed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderHistoryScreen(userId: widget.userId)),
      );
      return;
    }

    // Offline, or the backend rejected it and it's now in the retry cycle
    // — either way it's queued, not lost. The cart sync banner (visible
    // from the Cart screen this pops back to) surfaces its progress.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order queued — it'll go through once you're back online.")),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider(widget.userId)).cart;
    final submitting = ref.watch(checkoutSubmissionProvider);

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Checkout', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: Column(
          children: [
            CartSyncBanner(userId: widget.userId),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const NocturneCardKicker('Shipping address'),
                  const SizedBox(height: 8),
                  NocturneTextField(label: 'Full name', controller: _nameController),
                  const SizedBox(height: 12),
                  NocturneTextField(label: 'Address', controller: _addressController),
                  const SizedBox(height: 16),
                  const NocturneCardKicker('Payment'),
                  const SizedBox(height: 8),
                  NocturneCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Card ending 4242', style: NocturneType.bodySmall),
                        const NocturneTag(label: 'Mock', variant: NocturneTagVariant.neutral),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const NocturneCardKicker('Order summary'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${cart.itemCount} items', style: NocturneType.bodySmall.copyWith(color: NocturneColors.neutral300)),
                      Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: NocturneType.bodySmall.copyWith(color: NocturneColors.neutral300)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: NocturneColors.text)),
                      Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: NocturneColors.text)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NocturneButton(
                    label: 'Place order',
                    block: true,
                    loading: submitting,
                    onPressed: (submitting || cart.items.isEmpty) ? null : _placeOrder,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No real payment gateway — order is simulated.',
                    style: NocturneType.micro,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
