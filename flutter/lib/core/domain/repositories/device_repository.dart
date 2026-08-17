import '../entities/device.dart';

abstract class DeviceRepository {
  /// Idempotent upsert — safe to call every session.
  Future<void> register({required String deviceId, required String name, required String userId});

  Future<List<Device>> list(String userId);
}
