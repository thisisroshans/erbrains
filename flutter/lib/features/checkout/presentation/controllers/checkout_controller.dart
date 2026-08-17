import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

part 'checkout_controller.g.dart';

/// Owns the "Place order" submission's loading flag — the Controller layer
/// for Checkout. Screen-local, ephemeral UI state, but modeled as Riverpod
/// state (not `setState`) like everything else in the app; `submit`
/// throws [ApiException] on failure, letting the screen decide how to
/// surface it (a `SnackBar`) while this controller only owns "is it
/// in flight."
@riverpod
class CheckoutSubmission extends _$CheckoutSubmission {
  @override
  bool build() => false;

  Future<void> submit(String userId) async {
    state = true;
    try {
      await ref.read(orderRepositoryProvider).placeOrder(userId);
      ref.invalidate(ordersProvider(userId));
      await ref.read(cartProvider(userId).notifier).refresh();
    } finally {
      state = false;
    }
  }
}
