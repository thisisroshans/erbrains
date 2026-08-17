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
  @override
  AuthState build() => const AuthState();

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
}
