import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/background/background_sync.dart';
import 'core/offline/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await BackgroundSync.initialize();
  // Safe to call on every launch regardless of login state — the task
  // itself no-ops if nobody's logged in, and `keep` leaves an
  // already-registered schedule untouched. See BackgroundSync's doc.
  await BackgroundSync.registerPeriodic();
  runApp(const ProviderScope(child: FitRingApp()));
}
