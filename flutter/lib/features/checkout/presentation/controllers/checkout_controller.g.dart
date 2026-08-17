// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$checkoutSubmissionHash() =>
    r'bed0c72ea50b3b31eddee0925af4851ab36eec34';

/// Owns the "Place order" submission's loading flag — the Controller layer
/// for Checkout. Screen-local, ephemeral UI state, but modeled as Riverpod
/// state (not `setState`) like everything else in the app; `submit`
/// throws [ApiException] on failure, letting the screen decide how to
/// surface it (a `SnackBar`) while this controller only owns "is it
/// in flight."
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
