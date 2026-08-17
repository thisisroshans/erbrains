import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../offline/cache_policy.dart';
import '../datasources/local/products_local_cache.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/api_exception.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required ApiClient apiClient, required ProductsLocalCache cache})
      : _api = apiClient,
        _cache = cache;

  final ApiClient _api;
  final ProductsLocalCache _cache;

  @override
  Future<List<Product>> list() async {
    final cached = _cache.read();

    if (cached != null && cached.isUsable(CachePolicy.productsCatalog)) {
      return cached.value;
    }

    try {
      final rows = await _api.getProducts();
      final products = rows.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      await _cache.write(products);
      return products;
    } on ApiException {
      // Offline with an expired-but-still-existing cache beats an error
      // screen — fall back to it even past its grace window.
      if (cached != null) return cached.value;
      rethrow;
    }
  }

  @override
  Future<Product> getById(String id) async {
    try {
      final json = await _api.getProduct(id);
      return Product.fromJson(json);
    } on ApiException {
      // A product reached by tapping an offline-cached list tile should
      // still open even though this call is otherwise network-first.
      final cachedProducts = _cache.read()?.value ?? const [];
      for (final p in cachedProducts) {
        if (p.id == id) return p;
      }
      rethrow;
    }
  }
}
