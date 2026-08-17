// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wearable_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$wearableServiceHash() => r'2fc4405310c1fc2b281e019e2658cd43a4a3afc1';

/// The one [WearableService] instance for the app's lifetime — swap
/// [MockWearableService] for a real BLE implementation here and every
/// screen below keeps working unchanged (see [WearableService]'s doc).
///
/// Copied from [wearableService].
@ProviderFor(wearableService)
final wearableServiceProvider = Provider<WearableService>.internal(
  wearableService,
  name: r'wearableServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$wearableServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WearableServiceRef = ProviderRef<WearableService>;
String _$wearableConnectionHash() =>
    r'6fc92a4ae32900129895c69e4a4f3356491202a8';

/// See also [wearableConnection].
@ProviderFor(wearableConnection)
final wearableConnectionProvider =
    StreamProvider<WearableConnectionState>.internal(
      wearableConnection,
      name: r'wearableConnectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$wearableConnectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WearableConnectionRef = StreamProviderRef<WearableConnectionState>;
String _$wearableReadingHash() => r'180e281881fd56622e7211a10b24ede4ba0a1ddc';

/// See also [wearableReading].
@ProviderFor(wearableReading)
final wearableReadingProvider = StreamProvider<WearableSnapshot>.internal(
  wearableReading,
  name: r'wearableReadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$wearableReadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WearableReadingRef = StreamProviderRef<WearableSnapshot>;
String _$wearableReconnectStatusHash() =>
    r'c9df3549e0bea9b26dd682c6c254f5dd7a5710d7';

/// See also [wearableReconnectStatus].
@ProviderFor(wearableReconnectStatus)
final wearableReconnectStatusProvider =
    StreamProvider<ReconnectStatus?>.internal(
      wearableReconnectStatus,
      name: r'wearableReconnectStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$wearableReconnectStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WearableReconnectStatusRef = StreamProviderRef<ReconnectStatus?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
