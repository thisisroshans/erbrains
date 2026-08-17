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

  /// Checks for a persisted session on app launch. The backend's
  /// middleware verifies the token is well-formed and scopes every request
  /// to its userId, but the token itself is still an opaque, unsigned
  /// blob (see api/middleware/auth.js) — this just restores "we have a
  /// saved session," the first real request will fail loudly if the
  /// server no longer accepts it.
  Future<void> restoreSession() async {
    final storage = ref.read(tokenStorageProvider);
    final userId = await storage.readUserId();
    final email = await storage.readEmail();
    final name = await storage.readName();

    state = (userId != null && email != null)
        ? state.copyWith(
            status: AuthStatus.authenticated,
            user: AppUser(id: userId, email: email, name: name),
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
            name: loggedInUser.name,
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
    // Full local wipe — every Hive box holds either this account's cached
    // data or its pending sync queue, neither of which should survive a
    // switch to a different account on the same device.
    await ref.read(localDataWiperProvider).wipeAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
