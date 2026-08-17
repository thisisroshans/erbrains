import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/device.dart';
import '../../core/providers/core_providers.dart';

part 'devices_providers.g.dart';

@riverpod
Future<List<Device>> devices(Ref ref, String userId) async {
  final api = ref.watch(apiClientProvider);
  final rows = await api.getDevices(userId: userId);
  return rows.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
}
