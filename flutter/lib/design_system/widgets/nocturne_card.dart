import 'package:flutter/material.dart';

import '../nocturne_colors.dart';
import '../nocturne_shadows.dart';
import '../nocturne_spacing.dart';

enum NocturneElevation { none, sm, md, lg }

/// `.card` — a surface-filled content container. Compose with
/// [NocturneCardKicker] / [NocturneCardTitle] / [NocturneCardMeta] for the
/// labelled slots, or just pass any child for a plain surface block.
class NocturneCard extends StatelessWidget {
  const NocturneCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation = NocturneElevation.none,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final NocturneElevation elevation;
  final Color? borderColor;
  final VoidCallback? onTap;

  List<BoxShadow>? get _shadow {
    switch (elevation) {
      case NocturneElevation.none:
        return null;
      case NocturneElevation.sm:
        return NocturneShadows.sm;
      case NocturneElevation.md:
        return NocturneShadows.md;
      case NocturneElevation.lg:
        return NocturneShadows.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(NocturneSpacing.space3),
      decoration: BoxDecoration(
        color: NocturneColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: _shadow,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
    );
  }
}

class NocturneCardKicker extends StatelessWidget {
  const NocturneCardKicker(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1,
        fontWeight: FontWeight.w500,
        color: NocturneColors.accent,
      ),
    );
  }
}

class NocturneCardTitle extends StatelessWidget {
  const NocturneCardTitle(this.text, {super.key, this.fontSize = 17});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: NocturneColors.text,
      ),
    );
  }
}

class NocturneCardMeta extends StatelessWidget {
  const NocturneCardMeta(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: NocturneColors.text.withValues(alpha: 0.5),
      ),
    );
  }
}
