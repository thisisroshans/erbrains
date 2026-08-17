import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/product.dart';
import '../../core/offline/cache_policy.dart';
import '../../core/offline/products_local_cache.dart';
import '../../core/providers/core_providers.dart';

part 'shop_providers.g.dart';

@Riverpod(keepAlive: true)
ProductsLocalCache productsLocalCache(Ref ref) => ProductsLocalCache();

/// Cache-first against [CachePolicy.productsCatalog]: a fresh-enough cache
/// is returned with no network call at all; an expired one still wins
/// over an error if the network fetch that would replace it fails (e.g.
/// offline) — the catalog should still browse, just possibly stale.
@riverpod
Future<List<Product>> products(Ref ref) async {
  final cache = ref.watch(productsLocalCacheProvider);
  final cached = cache.read();

  if (cached != null && cached.isUsable(CachePolicy.productsCatalog)) {
    return cached.value;
  }

  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getProducts();
    final products = rows.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    await cache.write(products);
    return products;
  } on ApiException {
    if (cached != null) return cached.value;
    rethrow;
  }
}

/// Network-first (product details can legitimately be fresher than the
/// list — stock, price), but falls back to the cached catalog entry so a
/// product reached by tapping an offline-cached list tile still opens.
@riverpod
Future<Product> product(Ref ref, String id) async {
  final api = ref.watch(apiClientProvider);
  try {
    final json = await api.getProduct(id);
    return Product.fromJson(json);
  } on ApiException {
    final cachedProducts = ref.read(productsLocalCacheProvider).read()?.value ?? const [];
    for (final p in cachedProducts) {
      if (p.id == id) return p;
    }
    rethrow;
  }
}
