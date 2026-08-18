// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartSyncStoreHash() => r'016ca7a2e76da51ff3f0f40aa8fd161a88b685cf';

/// See also [cartSyncStore].
@ProviderFor(cartSyncStore)
final cartSyncStoreProvider = Provider<CartSyncStore>.internal(
  cartSyncStore,
  name: r'cartSyncStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartSyncStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartSyncStoreRef = ProviderRef<CartSyncStore>;
String _$cartSyncManagerHash() => r'4d65f096a89f24e33ab176475799f3940aadd939';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [cartSyncManager].
@ProviderFor(cartSyncManager)
const cartSyncManagerProvider = CartSyncManagerFamily();

/// See also [cartSyncManager].
class CartSyncManagerFamily extends Family<CartSyncManager> {
  /// See also [cartSyncManager].
  const CartSyncManagerFamily();

  /// See also [cartSyncManager].
  CartSyncManagerProvider call(String userId) {
    return CartSyncManagerProvider(userId);
  }

  @override
  CartSyncManagerProvider getProviderOverride(
    covariant CartSyncManagerProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cartSyncManagerProvider';
}

/// See also [cartSyncManager].
class CartSyncManagerProvider extends Provider<CartSyncManager> {
  /// See also [cartSyncManager].
  CartSyncManagerProvider(String userId)
    : this._internal(
        (ref) => cartSyncManager(ref as CartSyncManagerRef, userId),
        from: cartSyncManagerProvider,
        name: r'cartSyncManagerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cartSyncManagerHash,
        dependencies: CartSyncManagerFamily._dependencies,
        allTransitiveDependencies:
            CartSyncManagerFamily._allTransitiveDependencies,
        userId: userId,
      );

  CartSyncManagerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    CartSyncManager Function(CartSyncManagerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CartSyncManagerProvider._internal(
        (ref) => create(ref as CartSyncManagerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  ProviderElement<CartSyncManager> createElement() {
    return _CartSyncManagerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CartSyncManagerProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CartSyncManagerRef on ProviderRef<CartSyncManager> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _CartSyncManagerProviderElement extends ProviderElement<CartSyncManager>
    with CartSyncManagerRef {
  _CartSyncManagerProviderElement(super.provider);

  @override
  String get userId => (origin as CartSyncManagerProvider).userId;
}

String _$pendingCartMutationsCountHash() =>
    r'9b3efa264a1593bc41a31af97d0d5dce6bc36404';

/// Live count of cart/order mutations not yet applied — what the cart sync
/// banner shows.
///
/// Copied from [pendingCartMutationsCount].
@ProviderFor(pendingCartMutationsCount)
final pendingCartMutationsCountProvider = StreamProvider<int>.internal(
  pendingCartMutationsCount,
  name: r'pendingCartMutationsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingCartMutationsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingCartMutationsCountRef = StreamProviderRef<int>;
String _$failedCartMutationsCountHash() =>
    r'5192abc15757a2eea2f9c2654c9546e61a1a0059';

/// Live count of mutations that exhausted their retry budget.
///
/// Copied from [failedCartMutationsCount].
@ProviderFor(failedCartMutationsCount)
final failedCartMutationsCountProvider = StreamProvider<int>.internal(
  failedCartMutationsCount,
  name: r'failedCartMutationsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$failedCartMutationsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FailedCartMutationsCountRef = StreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
