import 'package:flutter/material.dart';

import 'nocturne_colors.dart';

/// Nocturne design system — elevation tokens.
///
/// On this dark ground, elevation is an edge (a 1px ring in a neutral step)
/// plus ambient darkness — never a stacked, flood-lit shadow.
class NocturneShadows {
  NocturneShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(color: NocturneColors.neutral800, spreadRadius: 1),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(color: NocturneColors.neutral700, spreadRadius: 1),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          offset: const Offset(0, 6),
          blurRadius: 18,
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(color: NocturneColors.neutral500, spreadRadius: 1),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.65),
          offset: const Offset(0, 16),
          blurRadius: 40,
        ),
      ];
}
