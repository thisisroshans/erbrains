import 'package:hive_flutter/hive_flutter.dart';

/// Box name constants + init. Every box stores plain `Map<String, dynamic>`
/// (via each model's own `toHiveMap`/`fromHiveMap`) rather than generated
/// `TypeAdapter`s — one fewer codegen pipeline to run alongside
/// riverpod_generator, and Hive's `Box<dynamic>` handles nested maps/lists
/// natively.
class HiveBoxes {
  HiveBoxes._();

  /// Every reading the device has ever produced, synced or not — this
  /// box IS the offline health-data store, not just a cache of it.
  static const healthReadings = 'health_readings';

  /// `GET /products` response, cache-first with a 24h TTL.
  static const productsCache = 'products_cache';

  static const _all = [healthReadings, productsCache];

  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in _all) {
      await Hive.openBox<dynamic>(name);
    }
  }

  /// Every box, for [LocalDataWiper] — kept in one place so a new box
  /// can't be added to `_all` and forgotten here, or vice versa.
  static List<String> get all => _all;
}
