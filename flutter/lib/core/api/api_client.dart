import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/health_reading.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around the `../api` Express backend. One method per
/// endpoint in its README — see [C:\erbrains\api\README.md] for the
/// authoritative contract.
///
/// NB: the backend does not currently verify the bearer token on any
/// route (no auth middleware) — see docs/API_GAPS.md. It's still attached
/// here so wiring real verification later is a backend-only change.
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
  }) {
    return _wrap(
      () => _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
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

  Future<Map<String, dynamic>> syncHealthReadings({
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
      (data) => data as Map<String, dynamic>,
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
