import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/order.dart';
import '../../core/providers/core_providers.dart';

part 'orders_providers.g.dart';

@riverpod
Future<List<Order>> orders(Ref ref, String userId) async {
  final api = ref.watch(apiClientProvider);
  final rows = await api.getOrders(userId: userId);
  return rows.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
}
