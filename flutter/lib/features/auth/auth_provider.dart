import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/core_providers.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState();

  /// Checks for a persisted session on app launch. Note: the backend's
  /// token is an opaque, unverified blob — see docs/API_GAPS.md — so
  /// "restoring a session" here just means "we have a saved user id",
  /// not a validated server-side session.
  Future<void> restoreSession() async {
    final storage = ref.read(tokenStorageProvider);
    final userId = await storage.readUserId();
    final email = await storage.readEmail();

    state = (userId != null && email != null)
        ? state.copyWith(
            status: AuthStatus.authenticated,
            user: AppUser(id: userId, email: email),
          )
        : state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final api = ref.read(apiClientProvider);
      final result = await api.login(email: email, password: password);

      final token = result['token'] as String;
      final loggedInUser =
          AppUser.fromJson(result['user'] as Map<String, dynamic>);

      await ref.read(tokenStorageProvider).save(
            token: token,
            userId: loggedInUser.id,
            email: loggedInUser.email,
          );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: loggedInUser,
        isSubmitting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
