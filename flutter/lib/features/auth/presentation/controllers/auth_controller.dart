import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/datasources/remote/api_exception.dart';
import '../../../../core/domain/repositories/auth_repository.dart';
import '../../../../core/providers/datasource_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import 'auth_state.dart';

part 'auth_controller.g.dart';

/// The Controller/ViewModel for the auth feature — orchestrates
/// [AuthRepository] calls into [AuthState] transitions. All session
/// persistence detail lives in the repository; this class only knows
/// "log in," "restore," "log out."
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  StreamSubscription<void>? _sessionExpiredSub;

  @override
  AuthState build() {
    // Reacts to ApiClient's 401-on-an-authenticated-request signal (the
    // JWT expired, or the server's signing secret rotated) — see
    // ApiClient.onSessionExpired.
    _sessionExpiredSub = ref.read(apiClientProvider).onSessionExpired.listen((_) => _handleSessionExpired());
    ref.onDispose(() => _sessionExpiredSub?.cancel());
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    final user = await _repository.restoreSession();

    state = user != null
        ? state.copyWith(status: AuthStatus.authenticated, user: user)
        : state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = await _repository.login(email: email, password: password);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    // Full local wipe — every Hive box holds either this account's cached
    // data or its pending sync queue, neither of which should survive a
    // switch to a different account on the same device.
    await ref.read(localDataWiperProvider).wipeAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// The server rejected the stored token — TokenStorage is already
  /// cleared by ApiClient's interceptor by the time this fires. No network
  /// call needed (the token that would authorize `POST /auth/logout` is
  /// already gone); just wipe local state and drop back to the login
  /// screen, same end state as [logout] minus the now-pointless request.
  Future<void> _handleSessionExpired() async {
    if (state.status != AuthStatus.authenticated) return;
    await ref.read(localDataWiperProvider).wipeAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
