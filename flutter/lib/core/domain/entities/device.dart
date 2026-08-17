enum DeviceStatus { connected, disconnected }

DeviceStatus _statusFromString(String? value) {
  return value == 'connected'
      ? DeviceStatus.connected
      : DeviceStatus.disconnected;
}

class Device {
  const Device({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DeviceStatus status;
  final DateTime? createdAt;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      status: _statusFromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
