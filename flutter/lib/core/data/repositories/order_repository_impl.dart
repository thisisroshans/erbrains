import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/remote/api_client.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<void> placeOrder(String userId) {
    return _api.placeOrder(userId: userId);
  }

  @override
  Future<List<Order>> list(String userId) async {
    final rows = await _api.getOrders(userId: userId);
    return rows.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}
