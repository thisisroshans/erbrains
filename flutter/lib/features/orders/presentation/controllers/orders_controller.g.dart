// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ordersHash() => r'e63e22c9be3950cec53aa80f57d03ec4be88c7cb';

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

/// See also [orders].
@ProviderFor(orders)
const ordersProvider = OrdersFamily();

/// See also [orders].
class OrdersFamily extends Family<AsyncValue<List<Order>>> {
  /// See also [orders].
  const OrdersFamily();

  /// See also [orders].
  OrdersProvider call(String userId) {
    return OrdersProvider(userId);
  }

  @override
  OrdersProvider getProviderOverride(covariant OrdersProvider provider) {
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
  String? get name => r'ordersProvider';
}

/// See also [orders].
class OrdersProvider extends AutoDisposeFutureProvider<List<Order>> {
  /// See also [orders].
  OrdersProvider(String userId)
    : this._internal(
        (ref) => orders(ref as OrdersRef, userId),
        from: ordersProvider,
        name: r'ordersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$ordersHash,
        dependencies: OrdersFamily._dependencies,
        allTransitiveDependencies: OrdersFamily._allTransitiveDependencies,
        userId: userId,
      );

  OrdersProvider._internal(
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
    FutureOr<List<Order>> Function(OrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OrdersProvider._internal(
        (ref) => create(ref as OrdersRef),
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
  AutoDisposeFutureProviderElement<List<Order>> createElement() {
    return _OrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersProvider && other.userId == userId;
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
mixin OrdersRef on AutoDisposeFutureProviderRef<List<Order>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _OrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<Order>>
    with OrdersRef {
  _OrdersProviderElement(super.provider);

  @override
  String get userId => (origin as OrdersProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
