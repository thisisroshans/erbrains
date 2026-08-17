// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthSummaryHash() => r'74c91d4729682eff2d8dc6d1c3b14b04e2f08b36';

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

/// See also [healthSummary].
@ProviderFor(healthSummary)
const healthSummaryProvider = HealthSummaryFamily();

/// See also [healthSummary].
class HealthSummaryFamily extends Family<AsyncValue<List<HealthSummaryPoint>>> {
  /// See also [healthSummary].
  const HealthSummaryFamily();

  /// See also [healthSummary].
  HealthSummaryProvider call(String userId, String period) {
    return HealthSummaryProvider(userId, period);
  }

  @override
  HealthSummaryProvider getProviderOverride(
    covariant HealthSummaryProvider provider,
  ) {
    return call(provider.userId, provider.period);
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

/// See also [healthSummary].
class HealthSummaryProvider
    extends AutoDisposeFutureProvider<List<HealthSummaryPoint>> {
  /// See also [healthSummary].
  HealthSummaryProvider(String userId, String period)
    : this._internal(
        (ref) => healthSummary(ref as HealthSummaryRef, userId, period),
        from: healthSummaryProvider,
        name: r'healthSummaryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$healthSummaryHash,
        dependencies: HealthSummaryFamily._dependencies,
        allTransitiveDependencies:
            HealthSummaryFamily._allTransitiveDependencies,
        userId: userId,
        period: period,
      );

  HealthSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.period,
  }) : super.internal();

  final String userId;
  final String period;

  @override
  Override overrideWith(
    FutureOr<List<HealthSummaryPoint>> Function(HealthSummaryRef provider)
    create,
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
        userId: userId,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<HealthSummaryPoint>> createElement() {
    return _HealthSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthSummaryProvider &&
        other.userId == userId &&
        other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HealthSummaryRef
    on AutoDisposeFutureProviderRef<List<HealthSummaryPoint>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `period` of this provider.
  String get period;
}

class _HealthSummaryProviderElement
    extends AutoDisposeFutureProviderElement<List<HealthSummaryPoint>>
    with HealthSummaryRef {
  _HealthSummaryProviderElement(super.provider);

  @override
  String get userId => (origin as HealthSummaryProvider).userId;
  @override
  String get period => (origin as HealthSummaryProvider).period;
}

String _$recentHealthReadingsHash() =>
    r'49ae863e8c3ffdf08254b2f8624a87ddb56f6982';

/// The most recent readings, paged server-side — matches screen 04's note
/// ("Showing latest 20 of 1,240 readings — older data loads in paged
/// chunks, never all at once").
///
/// Copied from [recentHealthReadings].
@ProviderFor(recentHealthReadings)
const recentHealthReadingsProvider = RecentHealthReadingsFamily();

/// The most recent readings, paged server-side — matches screen 04's note
/// ("Showing latest 20 of 1,240 readings — older data loads in paged
/// chunks, never all at once").
///
/// Copied from [recentHealthReadings].
class RecentHealthReadingsFamily
    extends Family<AsyncValue<List<HealthReading>>> {
  /// The most recent readings, paged server-side — matches screen 04's note
  /// ("Showing latest 20 of 1,240 readings — older data loads in paged
  /// chunks, never all at once").
  ///
  /// Copied from [recentHealthReadings].
  const RecentHealthReadingsFamily();

  /// The most recent readings, paged server-side — matches screen 04's note
  /// ("Showing latest 20 of 1,240 readings — older data loads in paged
  /// chunks, never all at once").
  ///
  /// Copied from [recentHealthReadings].
  RecentHealthReadingsProvider call(String userId) {
    return RecentHealthReadingsProvider(userId);
  }

  @override
  RecentHealthReadingsProvider getProviderOverride(
    covariant RecentHealthReadingsProvider provider,
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
  String? get name => r'recentHealthReadingsProvider';
}

/// The most recent readings, paged server-side — matches screen 04's note
/// ("Showing latest 20 of 1,240 readings — older data loads in paged
/// chunks, never all at once").
///
/// Copied from [recentHealthReadings].
class RecentHealthReadingsProvider
    extends AutoDisposeFutureProvider<List<HealthReading>> {
  /// The most recent readings, paged server-side — matches screen 04's note
  /// ("Showing latest 20 of 1,240 readings — older data loads in paged
  /// chunks, never all at once").
  ///
  /// Copied from [recentHealthReadings].
  RecentHealthReadingsProvider(String userId)
    : this._internal(
        (ref) => recentHealthReadings(ref as RecentHealthReadingsRef, userId),
        from: recentHealthReadingsProvider,
        name: r'recentHealthReadingsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recentHealthReadingsHash,
        dependencies: RecentHealthReadingsFamily._dependencies,
        allTransitiveDependencies:
            RecentHealthReadingsFamily._allTransitiveDependencies,
        userId: userId,
      );

  RecentHealthReadingsProvider._internal(
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
    FutureOr<List<HealthReading>> Function(RecentHealthReadingsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentHealthReadingsProvider._internal(
        (ref) => create(ref as RecentHealthReadingsRef),
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
  AutoDisposeFutureProviderElement<List<HealthReading>> createElement() {
    return _RecentHealthReadingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentHealthReadingsProvider && other.userId == userId;
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
mixin RecentHealthReadingsRef
    on AutoDisposeFutureProviderRef<List<HealthReading>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _RecentHealthReadingsProviderElement
    extends AutoDisposeFutureProviderElement<List<HealthReading>>
    with RecentHealthReadingsRef {
  _RecentHealthReadingsProviderElement(super.provider);

  @override
  String get userId => (origin as RecentHealthReadingsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
