import 'package:flutter/material.dart';

import '../../design_system/nocturne_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/product_list_screen.dart';
import 'nocturne_tab_bar.dart';

/// The bottom-tab shell wrapping screens 02 (Dashboard), 04 (History),
/// 06 (Shop) and 11 (Profile). Cart/Checkout/Order-history/Product-details
/// push on top of this via [Navigator], matching the static screens'
/// implied flow (Shop -> Product details -> Cart -> Checkout).
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.userId});

  final String userId;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(userId: widget.userId),
      HistoryScreen(userId: widget.userId),
      ProductListScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NocturneTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
