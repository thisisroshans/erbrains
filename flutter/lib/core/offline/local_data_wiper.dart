import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Sign-out is a full local wipe — there's no per-box allowlist to
/// preserve: every box holds either this user's cached API data or their
/// pending sync queue, none of which should survive a switch to a
/// different account on the same device.
class LocalDataWiper {
  Future<void> wipeAll() async {
    for (final name in HiveBoxes.all) {
      final box = Hive.isBoxOpen(name)
          ? Hive.box<dynamic>(name)
          : await Hive.openBox<dynamic>(name);
      await box.clear();
    }
  }
}
