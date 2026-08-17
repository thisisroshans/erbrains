import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../design_system/nocturne_colors.dart';

class NocturneTabItem {
  const NocturneTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const List<NocturneTabItem> kShellTabs = [
  NocturneTabItem(
    label: 'Dashboard',
    icon: PhosphorIconsRegular.house,
    activeIcon: PhosphorIconsFill.house,
  ),
  NocturneTabItem(
    label: 'History',
    icon: PhosphorIconsRegular.clockCounterClockwise,
    activeIcon: PhosphorIconsFill.clockCounterClockwise,
  ),
  NocturneTabItem(
    label: 'Shop',
    icon: PhosphorIconsRegular.bag,
    activeIcon: PhosphorIconsFill.bag,
  ),
  NocturneTabItem(
    label: 'Profile',
    icon: PhosphorIconsRegular.userCircle,
    activeIcon: PhosphorIconsFill.userCircle,
  ),
];

/// `.tabbar` / `.tabitem` — the bottom navigation chrome from screens
/// 02/06/11. Screen-specific rather than a design-system primitive: these
/// classes live in the screens file's own `<style>`, not `styles.css`.
class NocturneTabBar extends StatelessWidget {
  const NocturneTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NocturneColors.neutral900,
        border: Border(top: BorderSide(color: NocturneColors.neutral700)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < kShellTabs.length; i++)
                _TabButton(
                  item: kShellTabs[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NocturneTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? NocturneColors.accent300 : NocturneColors.neutral400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? item.activeIcon : item.icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(item.label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
