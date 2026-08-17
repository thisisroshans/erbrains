import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/datasources/local/products_local_cache.dart';
import '../data/datasources/local/token_storage.dart';
import '../data/datasources/remote/api_client.dart';
import '../offline/local_data_wiper.dart';

part 'datasource_providers.g.dart';

/// The data layer's low-level sources — these are consumed only by
/// `core/data/repositories/*` (see repository_providers.dart), never
/// directly by presentation code. Composed functionally: [apiClient]
/// depends on [tokenStorage] purely by reading it, no constructor wiring
/// in `main()`.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
}

@Riverpod(keepAlive: true)
ProductsLocalCache productsLocalCache(Ref ref) => ProductsLocalCache();

@Riverpod(keepAlive: true)
LocalDataWiper localDataWiper(Ref ref) => LocalDataWiper();
