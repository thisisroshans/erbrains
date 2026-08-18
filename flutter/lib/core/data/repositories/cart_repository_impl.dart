import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/remote/api_client.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Cart> get(String userId) async {
    final json = await _api.getCart(userId: userId);
    return Cart.fromJson(json);
  }
}
