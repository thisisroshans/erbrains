import 'package:flutter/material.dart';

import '../nocturne_colors.dart';
import '../nocturne_spacing.dart';
import '../nocturne_typography.dart';

enum NocturneButtonVariant { primary, secondary, ghost }

/// `.btn` — outlined actions. The primary variant is an accent outline on
/// a transparent fill, never a solid fill; this system reserves flood
/// color for the deck section-divider ground only.
class NocturneButton extends StatelessWidget {
  const NocturneButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NocturneButtonVariant.primary,
    this.icon,
    this.block = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NocturneButtonVariant variant;
  final Widget? icon;
  final bool block;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    Color textColor;
    Color? borderColor;
    Color pressedTint;

    switch (variant) {
      case NocturneButtonVariant.primary:
        textColor = NocturneColors.accent;
        borderColor = NocturneColors.accent;
        pressedTint = NocturneColors.accent.withValues(alpha: 0.22);
        break;
      case NocturneButtonVariant.secondary:
        textColor = NocturneColors.text;
        borderColor = NocturneColors.divider;
        pressedTint = NocturneColors.text.withValues(alpha: 0.14);
        break;
      case NocturneButtonVariant.ghost:
        textColor = NocturneColors.accent;
        borderColor = null;
        pressedTint = NocturneColors.accent.withValues(alpha: 0.18);
        break;
    }

    final content = Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Row(
        mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: textColor, size: 14),
              child: icon!,
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: NocturneType.bodyMedium.copyWith(color: textColor)),
        ],
      ),
    );

    return SizedBox(
      width: block ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          highlightColor: pressedTint,
          splashColor: pressedTint,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NocturneSpacing.space3 * 1.2,
              vertical: NocturneSpacing.space2 + 4,
            ),
            decoration: BoxDecoration(
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// `.btn-icon` — a square icon-only button, same outline rules as [NocturneButton].
class NocturneIconButton extends StatelessWidget {
  const NocturneIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = NocturneButtonVariant.primary,
    this.size = 36,
    this.semanticLabel,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final NocturneButtonVariant variant;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == NocturneButtonVariant.primary;
    final color = isPrimary ? NocturneColors.accent : NocturneColors.text;
    final borderColor =
        isPrimary ? NocturneColors.accent : NocturneColors.divider;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          highlightColor: color.withValues(alpha: 0.2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconTheme(
              data: IconThemeData(color: color, size: size * 0.45),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
