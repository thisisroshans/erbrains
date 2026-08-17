import '../entities/product.dart';

abstract class ProductRepository {
  /// Cache-first — see `CachePolicy.productsCatalog`. May return a stale
  /// cached list if the network is unavailable and nothing fresher exists.
  Future<List<Product>> list();

  /// Network-first, falling back to the cached catalog entry — see
  /// `ProductRepositoryImpl.getById`.
  Future<Product> getById(String id);
}
