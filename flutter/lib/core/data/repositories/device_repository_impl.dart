import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/remote/api_client.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<void> register({required String deviceId, required String name, required String userId}) {
    return _api.registerDevice(deviceId: deviceId, name: name, userId: userId);
  }

  @override
  Future<List<Device>> list(String userId) async {
    final rows = await _api.getDevices(userId: userId);
    return rows.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }
}
