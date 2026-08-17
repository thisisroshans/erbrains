// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productsHash() => r'c00c62c7eec55b125d3fb41c5add7b445e08e1fa';

/// See also [products].
@ProviderFor(products)
final productsProvider = AutoDisposeFutureProvider<List<Product>>.internal(
  products,
  name: r'productsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductsRef = AutoDisposeFutureProviderRef<List<Product>>;
String _$productHash() => r'a65992d84add0b7952d81c8fc38364e8f13443b1';

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

/// See also [product].
@ProviderFor(product)
const productProvider = ProductFamily();

/// See also [product].
class ProductFamily extends Family<AsyncValue<Product>> {
  /// See also [product].
  const ProductFamily();

  /// See also [product].
  ProductProvider call(String id) {
    return ProductProvider(id);
  }

  @override
  ProductProvider getProviderOverride(covariant ProductProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productProvider';
}

/// See also [product].
class ProductProvider extends AutoDisposeFutureProvider<Product> {
  /// See also [product].
  ProductProvider(String id)
    : this._internal(
        (ref) => product(ref as ProductRef, id),
        from: productProvider,
        name: r'productProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productHash,
        dependencies: ProductFamily._dependencies,
        allTransitiveDependencies: ProductFamily._allTransitiveDependencies,
        id: id,
      );

  ProductProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Product> Function(ProductRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductProvider._internal(
        (ref) => create(ref as ProductRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Product> createElement() {
    return _ProductProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductRef on AutoDisposeFutureProviderRef<Product> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ProductProviderElement extends AutoDisposeFutureProviderElement<Product>
    with ProductRef {
  _ProductProviderElement(super.provider);

  @override
  String get id => (origin as ProductProvider).id;
}

String _$productQuantityHash() => r'0f49859e19fbb9d6fa86000d5dfb1320450adc50';

abstract class _$ProductQuantity extends BuildlessAutoDisposeNotifier<int> {
  late final String productId;

  int build(String productId);
}

/// The quantity stepper on the product-details screen, before "Add to
/// cart" is tapped — family-keyed by product id (like [cartProvider] is by
/// user id) so it's Riverpod state rather than screen-local `setState`.
///
/// Copied from [ProductQuantity].
@ProviderFor(ProductQuantity)
const productQuantityProvider = ProductQuantityFamily();

/// The quantity stepper on the product-details screen, before "Add to
/// cart" is tapped — family-keyed by product id (like [cartProvider] is by
/// user id) so it's Riverpod state rather than screen-local `setState`.
///
/// Copied from [ProductQuantity].
class ProductQuantityFamily extends Family<int> {
  /// The quantity stepper on the product-details screen, before "Add to
  /// cart" is tapped — family-keyed by product id (like [cartProvider] is by
  /// user id) so it's Riverpod state rather than screen-local `setState`.
  ///
  /// Copied from [ProductQuantity].
  const ProductQuantityFamily();

  /// The quantity stepper on the product-details screen, before "Add to
  /// cart" is tapped — family-keyed by product id (like [cartProvider] is by
  /// user id) so it's Riverpod state rather than screen-local `setState`.
  ///
  /// Copied from [ProductQuantity].
  ProductQuantityProvider call(String productId) {
    return ProductQuantityProvider(productId);
  }

  @override
  ProductQuantityProvider getProviderOverride(
    covariant ProductQuantityProvider provider,
  ) {
    return call(provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productQuantityProvider';
}

/// The quantity stepper on the product-details screen, before "Add to
/// cart" is tapped — family-keyed by product id (like [cartProvider] is by
/// user id) so it's Riverpod state rather than screen-local `setState`.
///
/// Copied from [ProductQuantity].
class ProductQuantityProvider
    extends AutoDisposeNotifierProviderImpl<ProductQuantity, int> {
  /// The quantity stepper on the product-details screen, before "Add to
  /// cart" is tapped — family-keyed by product id (like [cartProvider] is by
  /// user id) so it's Riverpod state rather than screen-local `setState`.
  ///
  /// Copied from [ProductQuantity].
  ProductQuantityProvider(String productId)
    : this._internal(
        () => ProductQuantity()..productId = productId,
        from: productQuantityProvider,
        name: r'productQuantityProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productQuantityHash,
        dependencies: ProductQuantityFamily._dependencies,
        allTransitiveDependencies:
            ProductQuantityFamily._allTransitiveDependencies,
        productId: productId,
      );

  ProductQuantityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  int runNotifierBuild(covariant ProductQuantity notifier) {
    return notifier.build(productId);
  }

  @override
  Override overrideWith(ProductQuantity Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProductQuantityProvider._internal(
        () => create()..productId = productId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ProductQuantity, int> createElement() {
    return _ProductQuantityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductQuantityProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductQuantityRef on AutoDisposeNotifierProviderRef<int> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductQuantityProviderElement
    extends AutoDisposeNotifierProviderElement<ProductQuantity, int>
    with ProductQuantityRef {
  _ProductQuantityProviderElement(super.provider);

  @override
  String get productId => (origin as ProductQuantityProvider).productId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
