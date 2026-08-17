// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthReadingLocalStoreHash() =>
    r'2563deeb8775ab156c3543d5a5bdade83df6423e';

/// See also [healthReadingLocalStore].
@ProviderFor(healthReadingLocalStore)
final healthReadingLocalStoreProvider =
    Provider<HealthReadingLocalStore>.internal(
      healthReadingLocalStore,
      name: r'healthReadingLocalStoreProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$healthReadingLocalStoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HealthReadingLocalStoreRef = ProviderRef<HealthReadingLocalStore>;
String _$connectivityMonitorHash() =>
    r'a05d4f83f282a84b6c240aa771775d914dd1542e';

/// See also [connectivityMonitor].
@ProviderFor(connectivityMonitor)
final connectivityMonitorProvider = Provider<ConnectivityMonitor>.internal(
  connectivityMonitor,
  name: r'connectivityMonitorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityMonitorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityMonitorRef = ProviderRef<ConnectivityMonitor>;
String _$syncManagerHash() => r'2be301eb2d8cfc3e59f9c9fc6293165d5c41b71e';

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

/// See also [syncManager].
@ProviderFor(syncManager)
const syncManagerProvider = SyncManagerFamily();

/// See also [syncManager].
class SyncManagerFamily extends Family<SyncManager> {
  /// See also [syncManager].
  const SyncManagerFamily();

  /// See also [syncManager].
  SyncManagerProvider call(String userId) {
    return SyncManagerProvider(userId);
  }

  @override
  SyncManagerProvider getProviderOverride(
    covariant SyncManagerProvider provider,
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
  String? get name => r'syncManagerProvider';
}

/// See also [syncManager].
class SyncManagerProvider extends Provider<SyncManager> {
  /// See also [syncManager].
  SyncManagerProvider(String userId)
    : this._internal(
        (ref) => syncManager(ref as SyncManagerRef, userId),
        from: syncManagerProvider,
        name: r'syncManagerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$syncManagerHash,
        dependencies: SyncManagerFamily._dependencies,
        allTransitiveDependencies: SyncManagerFamily._allTransitiveDependencies,
        userId: userId,
      );

  SyncManagerProvider._internal(
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
  Override overrideWith(SyncManager Function(SyncManagerRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SyncManagerProvider._internal(
        (ref) => create(ref as SyncManagerRef),
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
  ProviderElement<SyncManager> createElement() {
    return _SyncManagerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SyncManagerProvider && other.userId == userId;
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
mixin SyncManagerRef on ProviderRef<SyncManager> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _SyncManagerProviderElement extends ProviderElement<SyncManager>
    with SyncManagerRef {
  _SyncManagerProviderElement(super.provider);

  @override
  String get userId => (origin as SyncManagerProvider).userId;
}

String _$isOnlineHash() => r'b5d9a4a20a3c276a915fa611ec5e3d3d6b59ff59';

/// Current connectivity state, seeded with a real check (not just waiting
/// for the first transition) then updated on every transition after.
///
/// Copied from [isOnline].
@ProviderFor(isOnline)
final isOnlineProvider = StreamProvider<bool>.internal(
  isOnline,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineRef = StreamProviderRef<bool>;
String _$pendingReadingsCountHash() =>
    r'f352bda165b7ae11eebb2ec1bb93620ccb579ac6';

/// Live count of readings not yet confirmed synced — what the sync banner
/// shows. Re-emits on every local-store write, not polled.
///
/// Copied from [pendingReadingsCount].
@ProviderFor(pendingReadingsCount)
final pendingReadingsCountProvider = StreamProvider<int>.internal(
  pendingReadingsCount,
  name: r'pendingReadingsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingReadingsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingReadingsCountRef = StreamProviderRef<int>;
String _$failedReadingsCountHash() =>
    r'8af6028da328541e0125482b5528801db17a6643';

/// Live count of readings that exhausted their retry budget — what
/// switches the sync banner into its "failed" state.
///
/// Copied from [failedReadingsCount].
@ProviderFor(failedReadingsCount)
final failedReadingsCountProvider = StreamProvider<int>.internal(
  failedReadingsCount,
  name: r'failedReadingsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$failedReadingsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FailedReadingsCountRef = StreamProviderRef<int>;
String _$healthSyncEngineHash() => r'97dd82129458c5214c2043e719453c061d845d59';

/// Starts capturing readings + draining on connectivity change as soon as
/// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
/// once, right after login, so it runs for the whole authenticated
/// session regardless of which tab is active.
///
/// Copied from [healthSyncEngine].
@ProviderFor(healthSyncEngine)
const healthSyncEngineProvider = HealthSyncEngineFamily();

/// Starts capturing readings + draining on connectivity change as soon as
/// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
/// once, right after login, so it runs for the whole authenticated
/// session regardless of which tab is active.
///
/// Copied from [healthSyncEngine].
class HealthSyncEngineFamily extends Family<HealthSyncEngine> {
  /// Starts capturing readings + draining on connectivity change as soon as
  /// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
  /// once, right after login, so it runs for the whole authenticated
  /// session regardless of which tab is active.
  ///
  /// Copied from [healthSyncEngine].
  const HealthSyncEngineFamily();

  /// Starts capturing readings + draining on connectivity change as soon as
  /// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
  /// once, right after login, so it runs for the whole authenticated
  /// session regardless of which tab is active.
  ///
  /// Copied from [healthSyncEngine].
  HealthSyncEngineProvider call(String userId) {
    return HealthSyncEngineProvider(userId);
  }

  @override
  HealthSyncEngineProvider getProviderOverride(
    covariant HealthSyncEngineProvider provider,
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
  String? get name => r'healthSyncEngineProvider';
}

/// Starts capturing readings + draining on connectivity change as soon as
/// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
/// once, right after login, so it runs for the whole authenticated
/// session regardless of which tab is active.
///
/// Copied from [healthSyncEngine].
class HealthSyncEngineProvider extends Provider<HealthSyncEngine> {
  /// Starts capturing readings + draining on connectivity change as soon as
  /// anything watches this — see [HealthSyncEngine]. `RootShell` watches it
  /// once, right after login, so it runs for the whole authenticated
  /// session regardless of which tab is active.
  ///
  /// Copied from [healthSyncEngine].
  HealthSyncEngineProvider(String userId)
    : this._internal(
        (ref) => healthSyncEngine(ref as HealthSyncEngineRef, userId),
        from: healthSyncEngineProvider,
        name: r'healthSyncEngineProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$healthSyncEngineHash,
        dependencies: HealthSyncEngineFamily._dependencies,
        allTransitiveDependencies:
            HealthSyncEngineFamily._allTransitiveDependencies,
        userId: userId,
      );

  HealthSyncEngineProvider._internal(
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
    HealthSyncEngine Function(HealthSyncEngineRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HealthSyncEngineProvider._internal(
        (ref) => create(ref as HealthSyncEngineRef),
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
  ProviderElement<HealthSyncEngine> createElement() {
    return _HealthSyncEngineProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthSyncEngineProvider && other.userId == userId;
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
mixin HealthSyncEngineRef on ProviderRef<HealthSyncEngine> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _HealthSyncEngineProviderElement extends ProviderElement<HealthSyncEngine>
    with HealthSyncEngineRef {
  _HealthSyncEngineProviderElement(super.provider);

  @override
  String get userId => (origin as HealthSyncEngineProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
