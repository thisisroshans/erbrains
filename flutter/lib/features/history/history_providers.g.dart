// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentHealthReadingsHash() =>
    r'e644432007c63bfcb82ec5246f698df8d96c9eda';

/// Recent readings for the device, newest first — read straight from the
/// local store, not the network. History works fully offline this way,
/// and reflects readings that haven't synced yet (there's exactly one
/// device per app session, so no `userId` filter is needed here — that
/// scoping already happened when the reading was captured).
///
/// Copied from [recentHealthReadings].
@ProviderFor(recentHealthReadings)
final recentHealthReadingsProvider =
    AutoDisposeStreamProvider<List<HealthReading>>.internal(
      recentHealthReadings,
      name: r'recentHealthReadingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentHealthReadingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentHealthReadingsRef =
    AutoDisposeStreamProviderRef<List<HealthReading>>;
String _$healthSummaryHash() => r'43a1439915711424ebffa2f11dad4f27964e81de';

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

/// Client-side equivalent of `GET /health/summary`, computed from the
/// local store (see [HealthReadingLocalStore.summary]) for the same
/// offline-first reason.
///
/// Copied from [healthSummary].
@ProviderFor(healthSummary)
const healthSummaryProvider = HealthSummaryFamily();

/// Client-side equivalent of `GET /health/summary`, computed from the
/// local store (see [HealthReadingLocalStore.summary]) for the same
/// offline-first reason.
///
/// Copied from [healthSummary].
class HealthSummaryFamily extends Family<AsyncValue<List<HealthSummaryPoint>>> {
  /// Client-side equivalent of `GET /health/summary`, computed from the
  /// local store (see [HealthReadingLocalStore.summary]) for the same
  /// offline-first reason.
  ///
  /// Copied from [healthSummary].
  const HealthSummaryFamily();

  /// Client-side equivalent of `GET /health/summary`, computed from the
  /// local store (see [HealthReadingLocalStore.summary]) for the same
  /// offline-first reason.
  ///
  /// Copied from [healthSummary].
  HealthSummaryProvider call(String period) {
    return HealthSummaryProvider(period);
  }

  @override
  HealthSummaryProvider getProviderOverride(
    covariant HealthSummaryProvider provider,
  ) {
    return call(provider.period);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'healthSummaryProvider';
}

/// Client-side equivalent of `GET /health/summary`, computed from the
/// local store (see [HealthReadingLocalStore.summary]) for the same
/// offline-first reason.
///
/// Copied from [healthSummary].
class HealthSummaryProvider
    extends AutoDisposeStreamProvider<List<HealthSummaryPoint>> {
  /// Client-side equivalent of `GET /health/summary`, computed from the
  /// local store (see [HealthReadingLocalStore.summary]) for the same
  /// offline-first reason.
  ///
  /// Copied from [healthSummary].
  HealthSummaryProvider(String period)
    : this._internal(
        (ref) => healthSummary(ref as HealthSummaryRef, period),
        from: healthSummaryProvider,
        name: r'healthSummaryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$healthSummaryHash,
        dependencies: HealthSummaryFamily._dependencies,
        allTransitiveDependencies:
            HealthSummaryFamily._allTransitiveDependencies,
        period: period,
      );

  HealthSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final String period;

  @override
  Override overrideWith(
    Stream<List<HealthSummaryPoint>> Function(HealthSummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HealthSummaryProvider._internal(
        (ref) => create(ref as HealthSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<HealthSummaryPoint>> createElement() {
    return _HealthSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthSummaryProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HealthSummaryRef
    on AutoDisposeStreamProviderRef<List<HealthSummaryPoint>> {
  /// The parameter `period` of this provider.
  String get period;
}

class _HealthSummaryProviderElement
    extends AutoDisposeStreamProviderElement<List<HealthSummaryPoint>>
    with HealthSummaryRef {
  _HealthSummaryProviderElement(super.provider);

  @override
  String get period => (origin as HealthSummaryProvider).period;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
