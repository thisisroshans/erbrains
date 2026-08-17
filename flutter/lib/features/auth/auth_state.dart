import '../../core/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Immutable session state. Every transition produces a new [AuthState]
/// via [copyWith] rather than mutating fields in place.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
