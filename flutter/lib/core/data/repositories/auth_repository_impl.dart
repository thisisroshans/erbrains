import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/token_storage.dart';
import '../datasources/remote/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login({required String email, required String password, String? name}) async {
    final result = await _api.login(email: email, password: password, name: name);

    final token = result['token'] as String;
    final user = AppUser.fromJson(result['user'] as Map<String, dynamic>);

    await _tokenStorage.save(
      token: token,
      userId: user.id,
      email: user.email,
      name: user.name,
    );

    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    // The backend's middleware verifies the token is well-formed and
    // scopes every request to its userId, but the token itself is still
    // an opaque, unsigned blob (see api/middleware/auth.js) — this just
    // restores "we have a saved session," the first real request will
    // fail loudly if the server no longer accepts it.
    final userId = await _tokenStorage.readUserId();
    final email = await _tokenStorage.readEmail();
    if (userId == null || email == null) return null;

    final name = await _tokenStorage.readName();
    return AppUser(id: userId, email: email, name: name);
  }

  @override
  Future<void> logout() => _tokenStorage.clear();
}
