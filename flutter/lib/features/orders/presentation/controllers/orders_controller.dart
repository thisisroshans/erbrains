import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/entities/order.dart';
import '../../../../core/providers/repository_providers.dart';

part 'orders_controller.g.dart';

@riverpod
Future<List<Order>> orders(Ref ref, String userId) async {
  return ref.watch(orderRepositoryProvider).list(userId);
}

/// Owns the "Cancel order" action's loading flag, same shape as
/// CheckoutSubmission — screen-local, ephemeral UI state modeled as
/// Riverpod state rather than `setState`. Throws [ApiException] on failure
/// (already-cancelled, not found) and lets the screen decide how to
/// surface it.
@riverpod
class OrderCancellation extends _$OrderCancellation {
  @override
  bool build() => false;

  Future<void> cancel({required String orderId, required String userId}) async {
    state = true;
    try {
      await ref.read(orderRepositoryProvider).cancel(orderId);
      ref.invalidate(ordersProvider(userId));
    } finally {
      state = false;
    }
  }
}
