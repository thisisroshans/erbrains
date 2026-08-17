import 'package:flutter/material.dart';

import '../nocturne_colors.dart';

enum NocturneTagVariant { accent, neutral, outline }

/// `.tag` — a small status/label pill tinted from the ramps.
class NocturneTag extends StatelessWidget {
  const NocturneTag({
    super.key,
    required this.label,
    this.variant = NocturneTagVariant.neutral,
    this.leading,
  });

  final String label;
  final NocturneTagVariant variant;
  final String? leading;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;
    BoxBorder? border;

    switch (variant) {
      case NocturneTagVariant.accent:
        background = NocturneColors.accent800;
        foreground = NocturneColors.accent100;
        break;
      case NocturneTagVariant.neutral:
        background = NocturneColors.neutral800;
        foreground = NocturneColors.neutral100;
        break;
      case NocturneTagVariant.outline:
        background = Colors.transparent;
        foreground = NocturneColors.accent;
        border = Border.all(color: NocturneColors.accent, width: 1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        leading != null ? '$leading $label' : label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 11 * 0.02,
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
