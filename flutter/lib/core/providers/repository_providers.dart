import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/cart_repository_impl.dart';
import '../data/repositories/device_repository_impl.dart';
import '../data/repositories/order_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/device_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/product_repository.dart';
import 'datasource_providers.dart';

part 'repository_providers.g.dart';

/// The composition root for the data layer: every provider here is typed
/// as the *abstract* domain contract, not the concrete `*Impl` — the
/// presentation layer (controllers) depends only on these interfaces, so
/// swapping an implementation later never touches a screen or controller.

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}

@Riverpod(keepAlive: true)
DeviceRepository deviceRepository(Ref ref) {
  return DeviceRepositoryImpl(apiClient: ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) {
  return ProductRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(productsLocalCacheProvider),
  );
}

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) {
  return CartRepositoryImpl(apiClient: ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(apiClient: ref.watch(apiClientProvider));
}
