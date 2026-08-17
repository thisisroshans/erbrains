// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_tab_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shellTabIndexHash() => r'3220c3cb84c12f8100c5187e3236860926d38519';

/// The selected bottom-tab index (Dashboard/History/Shop/Profile) —
/// Riverpod state instead of `setState`, so `IndexedStack`'s selection
/// lives alongside every other piece of app state rather than being
/// `RootShell`-local.
///
/// Copied from [ShellTabIndex].
@ProviderFor(ShellTabIndex)
final shellTabIndexProvider =
    AutoDisposeNotifierProvider<ShellTabIndex, int>.internal(
      ShellTabIndex.new,
      name: r'shellTabIndexProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shellTabIndexHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ShellTabIndex = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
