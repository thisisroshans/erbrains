import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../offline/local_data_wiper.dart';
import '../storage/token_storage.dart';

part 'core_providers.g.dart';

/// App-wide singletons, composed functionally: [apiClient] depends on
/// [tokenStorage] purely by reading it, no constructor wiring in `main()`.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
}

@Riverpod(keepAlive: true)
LocalDataWiper localDataWiper(Ref ref) => LocalDataWiper();
