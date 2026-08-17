// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_activity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionActivityHash() =>
    r'f269976c03a1ecda9d098fa3108d0bd230e9757a';

/// The Controller for screen 03's "Recent activity" log — derives a
/// bounded (8-entry) history from [wearableConnectionProvider] transitions.
/// Lives as Riverpod state (not `StatefulWidget.setState`) so the log
/// persists across rebuilds the same way every other piece of app state
/// does, and so `ConnectionScreen` can be a plain `ConsumerWidget`.
///
/// Copied from [ConnectionActivity].
@ProviderFor(ConnectionActivity)
final connectionActivityProvider =
    AutoDisposeNotifierProvider<
      ConnectionActivity,
      List<ActivityEntry>
    >.internal(
      ConnectionActivity.new,
      name: r'connectionActivityProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionActivityHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectionActivity = AutoDisposeNotifier<List<ActivityEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
