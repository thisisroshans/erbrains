import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../cart_sync/cart_sync_manager.dart';
import '../cart_sync/cart_sync_store.dart';
import '../data/datasources/local/token_storage.dart';
import '../data/datasources/remote/api_client.dart';
import '../data/repositories/device_repository_impl.dart';
import '../domain/entities/cart.dart';
import '../health_sync/health_reading_local_store.dart';
import '../health_sync/health_sync_engine.dart';
import '../health_sync/sync_manager.dart';
import '../offline/hive_boxes.dart';
import '../wearable/mock_wearable_service.dart';

/// True OS-level background sync: drains whatever's queued (health
/// readings, cart/order mutations) on a periodic schedule even while the
/// app is fully backgrounded or killed, not just while it's open. This is
/// distinct from every other sync trigger in the app (connectivity
/// transitions, the in-app periodic timer, foreground-resume — all wired
/// in RootShell) in that those only fire while the Dart VM/UI isolate the
/// app started is still alive; this one is scheduled and invoked by the
/// OS itself (Android's WorkManager; iOS's BGTaskScheduler under the hood
/// of the same `workmanager` package), in a separate background isolate
/// with no widget tree and no live Riverpod [ProviderScope].
///
/// **Platform reality, not a guarantee**: Android's WorkManager enforces a
/// 15-minute minimum periodic interval and can delay further under Doze/
/// battery-saver. iOS gives the OS even less certainty — `registerPeriodicTask`
/// there is a *hint*, not a schedule; iOS decides if/when to actually run it
/// based on the user's app-usage pattern, and may not run it at all for
/// apps used rarely. This is "best-effort, eventually" background sync, the
/// same ceiling every app hits on these platforms — not a shortcoming
/// specific to this implementation.
///
/// **Verification note — be honest about this with reviewers.** This was
/// verified at the level available in the environment it was built in:
/// `flutter analyze`/`flutter test` clean, and `flutter build apk --debug`
/// succeeds with `workmanager` linked in (confirms the native Android
/// Gradle/Kotlin side actually compiles). It was **not** verified against
/// a running Android emulator or device — none was available — so neither
/// "the periodic task registers without throwing on a real device" nor
/// "the OS actually invokes it in the background" has been directly
/// observed, only inferred from the package compiling and its documented
/// contract. iOS is entirely unverified — no iOS toolchain/device is
/// available here; the Info.plist config follows the plugin's setup docs
/// but has never been built or run. Before relying on this, run it on a
/// real Android device/emulator at minimum.
class BackgroundSync {
  BackgroundSync._();

  static const _taskName = 'fitring.background_sync';

  /// `workmanager` only registers a platform implementation for Android,
  /// iOS/macOS, Linux and Web (see its `_ensurePlatformImplementation`) —
  /// Windows desktop has none. Every `Workmanager()` call throws
  /// `UnimplementedError` there, and this app runs on Windows desktop as
  /// a dev target (see ../../../README.md's Setup section), so every
  /// method below is a guarded no-op off Android/iOS rather than risking
  /// main() throwing before the app even starts.
  static bool get _isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Call once at app startup (see main.dart), before anything else that
  /// might need the background task registered — cheap and idempotent.
  static Future<void> initialize() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().initialize(_callbackDispatcher);
  }

  /// Schedules the periodic drain. Safe to call every launch — `keep`
  /// leaves an already-registered task's schedule untouched rather than
  /// resetting its timing.
  static Future<void> registerPeriodic() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15), // Android's own enforced floor
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> cancel() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().cancelByUniqueName(_taskName);
  }
}

/// Runs in a separate background isolate with no widget tree — every
/// dependency is constructed directly here rather than through
/// [ProviderScope]/Riverpod, since there's no app-level provider container
/// alive to read from. Kept intentionally minimal: this drains the same
/// two sync managers the foreground app uses (see RootShell), it just
/// builds throwaway instances of them rather than sharing the live ones.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await HiveBoxes.init();

    final tokenStorage = TokenStorage();
    final userId = await tokenStorage.readUserId();
    if (userId == null) return true; // nobody logged in — nothing to sync

    final api = ApiClient(tokenStorage: tokenStorage);

    final readingStore = HealthReadingLocalStore();
    final deviceRepository = DeviceRepositoryImpl(apiClient: api);
    // Only its `deviceId` constant is used here — the mock's simulated
    // reading stream is a foreground/UI concern (see HealthSyncEngine),
    // irrelevant to draining what's already queued.
    final wearableDeviceId = MockWearableService().deviceId;
    final readingSyncManager = SyncManager(
      store: readingStore,
      registerDevice: () => deviceRepository.register(
        deviceId: wearableDeviceId,
        name: 'FitRing Wearable',
        userId: userId,
      ),
      sendBatch: (batch) => api.syncHealthReadings(userId: userId, readings: batch),
    );
    await readingSyncManager.drain();
    await readingStore.evictSyncedOlderThan(HealthSyncEngine.evictionRetention);

    final cartStore = CartSyncStore();
    final cartSyncManager = CartSyncManager(
      store: cartStore,
      addToCart: ({required productId, required quantity}) async {
        final json = await api.addToCart(userId: userId, productId: productId, quantity: quantity);
        return json['id'] as String;
      },
      setQuantity: ({required cartItemId, required quantity}) =>
          api.updateCartItemQuantity(cartItemId: cartItemId, quantity: quantity),
      removeItem: (cartItemId) => api.removeCartItem(cartItemId: cartItemId),
      placeOrder: () => api.placeOrder(userId: userId),
      refreshBaseline: () async {
        final json = await api.getCart(userId: userId);
        await cartStore.writeBaseline(Cart.fromJson(json));
      },
    );
    await cartSyncManager.drain();

    return true;
  });
}
