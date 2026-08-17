// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartHash() => r'ea6948586f2365b8541c331517d5efd1ab936241';

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

abstract class _$Cart extends BuildlessAutoDisposeNotifier<CartState> {
  late final String userId;

  CartState build(String userId);
}

/// One notifier per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
///
/// Copied from [Cart].
@ProviderFor(Cart)
const cartProvider = CartFamily();

/// One notifier per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
///
/// Copied from [Cart].
class CartFamily extends Family<CartState> {
  /// One notifier per `userId` — the cart badge, Cart screen and product
  /// "Add to cart" buttons all watch the same instance for a given user.
  ///
  /// Copied from [Cart].
  const CartFamily();

  /// One notifier per `userId` — the cart badge, Cart screen and product
  /// "Add to cart" buttons all watch the same instance for a given user.
  ///
  /// Copied from [Cart].
  CartProvider call(String userId) {
    return CartProvider(userId);
  }

  @override
  CartProvider getProviderOverride(covariant CartProvider provider) {
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
  String? get name => r'cartProvider';
}

/// One notifier per `userId` — the cart badge, Cart screen and product
/// "Add to cart" buttons all watch the same instance for a given user.
///
/// Copied from [Cart].
class CartProvider extends AutoDisposeNotifierProviderImpl<Cart, CartState> {
  /// One notifier per `userId` — the cart badge, Cart screen and product
  /// "Add to cart" buttons all watch the same instance for a given user.
  ///
  /// Copied from [Cart].
  CartProvider(String userId)
    : this._internal(
        () => Cart()..userId = userId,
        from: cartProvider,
        name: r'cartProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cartHash,
        dependencies: CartFamily._dependencies,
        allTransitiveDependencies: CartFamily._allTransitiveDependencies,
        userId: userId,
      );

  CartProvider._internal(
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
  CartState runNotifierBuild(covariant Cart notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(Cart Function() create) {
    return ProviderOverride(
      origin: this,
      override: CartProvider._internal(
        () => create()..userId = userId,
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
  AutoDisposeNotifierProviderElement<Cart, CartState> createElement() {
    return _CartProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CartProvider && other.userId == userId;
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
mixin CartRef on AutoDisposeNotifierProviderRef<CartState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _CartProviderElement
    extends AutoDisposeNotifierProviderElement<Cart, CartState>
    with CartRef {
  _CartProviderElement(super.provider);

  @override
  String get userId => (origin as CartProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
