// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'ab1e2aeea15dbad52ade7a9bfa4abf544580f5c3';

/// The composition root for the data layer: every provider here is typed
/// as the *abstract* domain contract, not the concrete `*Impl` — the
/// presentation layer (controllers) depends only on these interfaces, so
/// swapping an implementation later never touches a screen or controller.
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$deviceRepositoryHash() => r'8cbbb904a6132ae256721bfd46a8be0481f39b45';

/// See also [deviceRepository].
@ProviderFor(deviceRepository)
final deviceRepositoryProvider = Provider<DeviceRepository>.internal(
  deviceRepository,
  name: r'deviceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceRepositoryRef = ProviderRef<DeviceRepository>;
String _$productRepositoryHash() => r'0e3435d82ff22b5698dfc3e1523a64f9addbb37f';

/// See also [productRepository].
@ProviderFor(productRepository)
final productRepositoryProvider = Provider<ProductRepository>.internal(
  productRepository,
  name: r'productRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductRepositoryRef = ProviderRef<ProductRepository>;
String _$cartRepositoryHash() => r'ff6d0a4736a83363e5a70579afb843825fe307b4';

/// See also [cartRepository].
@ProviderFor(cartRepository)
final cartRepositoryProvider = Provider<CartRepository>.internal(
  cartRepository,
  name: r'cartRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartRepositoryRef = ProviderRef<CartRepository>;
String _$orderRepositoryHash() => r'4f2301caea0572454af780b422daafd5e18d3797';

/// See also [orderRepository].
@ProviderFor(orderRepository)
final orderRepositoryProvider = Provider<OrderRepository>.internal(
  orderRepository,
  name: r'orderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderRepositoryRef = ProviderRef<OrderRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
