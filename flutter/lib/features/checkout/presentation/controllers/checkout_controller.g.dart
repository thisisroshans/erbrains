// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$checkoutSubmissionHash() =>
    r'4d7d2730e76c74d14d365ea76ae22f0dfcb3fc66';

/// Owns the "Place order" submission's loading flag — the Controller layer
/// for Checkout. Screen-local, ephemeral UI state, but modeled as Riverpod
/// state (not `setState`) like everything else in the app.
///
/// Unlike the pre-offline-queue version of this controller, [submit] never
/// throws: placing an order always goes through the same queue as every
/// other cart write (see CartController), so there's nothing left to
/// surface synchronously except which of [CheckoutOutcome] happened.
///
/// Copied from [CheckoutSubmission].
@ProviderFor(CheckoutSubmission)
final checkoutSubmissionProvider =
    AutoDisposeNotifierProvider<CheckoutSubmission, bool>.internal(
      CheckoutSubmission.new,
      name: r'checkoutSubmissionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$checkoutSubmissionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CheckoutSubmission = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
