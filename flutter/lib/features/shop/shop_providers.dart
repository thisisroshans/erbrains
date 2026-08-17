import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/product.dart';
import '../../core/providers/core_providers.dart';

part 'shop_providers.g.dart';

@riverpod
Future<List<Product>> products(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final rows = await api.getProducts();
  return rows.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<Product> product(Ref ref, String id) async {
  final api = ref.watch(apiClientProvider);
  final json = await api.getProduct(id);
  return Product.fromJson(json);
}
