import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_sync/health_sync_providers.dart';
import '../../design_system/nocturne_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/product_list_screen.dart';
import '../sync/sync_banner.dart';
import 'nocturne_tab_bar.dart';

/// The bottom-tab shell wrapping screens 02 (Dashboard), 04 (History),
/// 06 (Shop) and 11 (Profile). Cart/Checkout/Order-history/Product-details
/// push on top of this via [Navigator], matching the static screens'
/// implied flow (Shop -> Product details -> Cart -> Checkout).
///
/// Also where the offline engine actually runs for the whole authenticated
/// session: watching [healthSyncEngineProvider] here (rather than from
/// Dashboard) means reading capture and sync keep running no matter which
/// tab is active, plus a periodic drain trigger and an app-foreground-resume
/// trigger live here since both are widget-lifecycle concerns.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _periodicDrain;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Belt-and-suspenders trigger: connectivity transitions and app-resume
    // cover the common cases, but a short periodic drain means readings
    // sync promptly even while the app just sits open and online with no
    // transition event to react to.
    _periodicDrain = Timer.periodic(const Duration(seconds: 10), (_) => _drain());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicDrain?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _drain();
  }

  void _drain() {
    ref.read(syncManagerProvider(widget.userId)).drain();
  }

  @override
  Widget build(BuildContext context) {
    // Side-effect watch: starts HealthSyncEngine (reading capture +
    // connectivity-triggered drain) once per session and keeps it alive
    // for as long as RootShell is mounted.
    ref.watch(healthSyncEngineProvider(widget.userId));

    final screens = [
      DashboardScreen(userId: widget.userId),
      HistoryScreen(userId: widget.userId),
      ProductListScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      body: Column(
        children: [
          SyncBanner(userId: widget.userId),
          Expanded(child: IndexedStack(index: _index, children: screens)),
        ],
      ),
      bottomNavigationBar: NocturneTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
