import 'package:dio/dio.dart';

import '../../../config/app_config.dart';
import '../../../domain/entities/health_reading.dart';
import '../local/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around the `../api` Express backend. One method per
/// endpoint in its README — see [C:\erbrains\api\README.md] for the
/// authoritative contract.
///
/// Every route except `login` and the two product GETs requires the
/// bearer token attached below (see api/middleware/auth.js) — the server
/// verifies it's well-formed and that its userId matches whatever userId
/// the request acts on.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<T> _wrap<T>(Future<Response<dynamic>> Function() call, T Function(dynamic data) onSuccess) async {
    try {
      final response = await call();
      return onSuccess(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['error'] is String)
          ? data['error'] as String
          : e.message ?? 'Network error';
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? name,
  }) {
    return _wrap(
      () => _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Devices
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String name,
    required String userId,
  }) {
    return _wrap(
      () => _dio.post(
        '/devices',
        data: {'deviceId': deviceId, 'name': name, 'userId': userId},
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<List<dynamic>> getDevices({required String userId}) {
    return _wrap(
      () => _dio.get('/devices', queryParameters: {'userId': userId}),
      (data) => data as List<dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------

  /// Returns one bool per reading, in the same order as [readings]: `true`
  /// if the backend newly inserted it, `false` if it was already there
  /// from an earlier sync (duplicate per `(device_id, reading_timestamp)`
  /// — see api/models/healthReading.model.js). Falls back to "everything
  /// synced" if the response is missing the per-reading `results` field,
  /// for compatibility with a backend that hasn't been upgraded.
  Future<List<bool>> syncHealthReadings({
    required String userId,
    required List<HealthReading> readings,
  }) {
    return _wrap(
      () => _dio.post(
        '/health/readings',
        data: {
          'userId': userId,
          'readings': readings.map((r) => r.toSyncJson()).toList(),
        },
      ),
      (data) {
        final map = data as Map<String, dynamic>;
        final results = map['results'] as List<dynamic>?;
        if (results == null) return List<bool>.filled(readings.length, true);
        return results
            .map((r) => (r as Map<String, dynamic>)['status'] == 'synced')
            .toList();
      },
    );
  }

  Future<Map<String, dynamic>> getHealthReadings({
    required String userId,
    int page = 1,
    int limit = 50,
  }) {
    return _wrap(
      () => _dio.get(
        '/health/readings',
        queryParameters: {'userId': userId, 'page': page, 'limit': limit},
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<List<dynamic>> getHealthSummary({
    required String userId,
    String period = 'daily',
  }) {
    return _wrap(
      () => _dio.get(
        '/health/summary',
        queryParameters: {'userId': userId, 'period': period},
      ),
      (data) => data as List<dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Shopping
  // ---------------------------------------------------------------------

  Future<List<dynamic>> getProducts() {
    return _wrap(() => _dio.get('/products'), (data) => data as List<dynamic>);
  }

  Future<Map<String, dynamic>> getProduct(String id) {
    return _wrap(
      () => _dio.get('/products/$id'),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    required int quantity,
  }) {
    return _wrap(
      () => _dio.post(
        '/cart',
        data: {'userId': userId, 'productId': productId, 'quantity': quantity},
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getCart({required String userId}) {
    return _wrap(
      () => _dio.get('/cart', queryParameters: {'userId': userId}),
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Sets a line item to an exact quantity — the decrement counterpart to
  /// [addToCart]'s increment-only upsert.
  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) {
    return _wrap(
      () => _dio.patch('/cart/$cartItemId', data: {'quantity': quantity}),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<void> removeCartItem({required String cartItemId}) {
    return _wrap<void>(
      () => _dio.delete('/cart/$cartItemId'),
      (data) {},
    );
  }

  Future<Map<String, dynamic>> placeOrder({required String userId}) {
    return _wrap(
      () => _dio.post('/orders', data: {'userId': userId}),
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<List<dynamic>> getOrders({required String userId}) {
    return _wrap(
      () => _dio.get('/orders', queryParameters: {'userId': userId}),
      (data) => data as List<dynamic>,
    );
  }
}
