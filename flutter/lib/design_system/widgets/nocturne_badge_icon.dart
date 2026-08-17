import 'package:flutter/material.dart';

import '../nocturne_colors.dart';

/// `.badge` — a small accent count pill anchored to the top-right of an icon.
class NocturneBadgeIcon extends StatelessWidget {
  const NocturneBadgeIcon({
    super.key,
    required this.icon,
    this.count = 0,
    this.onTap,
  });

  final Widget icon;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          if (count > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: NocturneColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: NocturneColors.bg,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
