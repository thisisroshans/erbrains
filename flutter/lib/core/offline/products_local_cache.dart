import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import 'cached_value.dart';
import 'hive_boxes.dart';

/// Single-entry Hive cache of `GET /products` — see [CachePolicy.productsCatalog].
class ProductsLocalCache {
  static const _key = 'all';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.productsCache);

  CachedValue<List<Product>>? read() {
    final raw = _box.get(_key);
    if (raw == null) return null;

    final map = raw as Map<dynamic, dynamic>;
    final products = (map['products'] as List<dynamic>)
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();

    return CachedValue(
      value: products,
      cachedAt: DateTime.parse(map['cached_at'] as String),
    );
  }

  Future<void> write(List<Product> products) async {
    await _box.put(_key, {
      'cached_at': DateTime.now().toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    });
  }
}
