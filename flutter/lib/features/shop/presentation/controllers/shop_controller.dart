import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/providers/repository_providers.dart';

part 'shop_controller.g.dart';

@riverpod
Future<List<Product>> products(Ref ref) {
  return ref.watch(productRepositoryProvider).list();
}

@riverpod
Future<Product> product(Ref ref, String id) {
  return ref.watch(productRepositoryProvider).getById(id);
}

/// The quantity stepper on the product-details screen, before "Add to
/// cart" is tapped — family-keyed by product id (like [cartProvider] is by
/// user id) so it's Riverpod state rather than screen-local `setState`.
@riverpod
class ProductQuantity extends _$ProductQuantity {
  @override
  int build(String productId) => 1;

  void increment() => state++;

  void decrement() {
    if (state > 1) state--;
  }
}
