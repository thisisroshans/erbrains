import '../entities/app_user.dart';

/// Domain contract for session management. The concrete implementation
/// (data/repositories/auth_repository_impl.dart) is the only place that
/// knows the session lives behind a REST call plus local persistence —
/// callers just see "log in," "restore," "log out."
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password, String? name});

  /// Returns the persisted user if a session exists, else null. Does not
  /// itself validate the session against the server — see the note in
  /// `AuthRepositoryImpl.restoreSession`.
  Future<AppUser?> restoreSession();

  Future<void> logout();
}
