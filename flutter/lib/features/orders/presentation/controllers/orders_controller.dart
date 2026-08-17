import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/entities/order.dart';
import '../../../../core/providers/repository_providers.dart';

part 'orders_controller.g.dart';

@riverpod
Future<List<Order>> orders(Ref ref, String userId) async {
  return ref.watch(orderRepositoryProvider).list(userId);
}
