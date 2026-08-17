import 'package:flutter/material.dart';

/// Nocturne design system — color tokens.
///
/// Mirrors the CSS custom properties in the handoff's `styles.css` 1:1 so the
/// Flutter app matches the static screens. Mono accent scheme: `accent2` is
/// a machine-derived stand-in kept only so both token sets resolve — treat
/// it as the same role as [accent], never a second accent.
class NocturneColors {
  NocturneColors._();

  static const Color bg = Color(0xFF161826);
  static const Color surface = Color(0xFF232532);
  static const Color text = Color(0xFFE9E9ED);
  static const Color accent = Color(0xFF9184D9);
  static const Color accent2 = Color(0xFFA7A1DB);

  /// color-mix(in srgb, #e9e9ed 16%, transparent)
  static Color get divider => text.withValues(alpha: 0.16);

  // Neutral ramp — 100 (lightest) to 900 (darkest against this dark ground).
  static const Color neutral100 = Color(0xFFF3F5FE);
  static const Color neutral200 = Color(0xFFE4E7F5);
  static const Color neutral300 = Color(0xFFCFD3E5);
  static const Color neutral400 = Color(0xFFB2B6CA);
  static const Color neutral500 = Color(0xFF9397AB);
  static const Color neutral600 = Color(0xFF75798C);
  static const Color neutral700 = Color(0xFF595D6C);
  static const Color neutral800 = Color(0xFF3F424D);
  static const Color neutral900 = Color(0xFF292B31);

  // Accent ramp.
  static const Color accent100 = Color(0xFFF5F4FF);
  static const Color accent200 = Color(0xFFE7E5FE);
  static const Color accent300 = Color(0xFFD2CEFD);
  static const Color accent400 = Color(0xFFB5ABFC);
  static const Color accent500 = Color(0xFF968AE0);
  static const Color accent600 = Color(0xFF796CBF);
  static const Color accent700 = Color(0xFF5D5294);
  static const Color accent800 = Color(0xFF423A6A);
  static const Color accent900 = Color(0xFF2B2741);

  // Section ground — deck dividers / stat-band presence. Not used in-app
  // screens today; kept for parity with the token sheet.
  static const Color section = Color(0xFF262A60);
  static const Color sectionGlow = Color(0xFF353B80);
  static const Color sectionGhost = Color(0xFF4C5397);

  // Semantic mappings used across screens (sync/order status tags etc).
  static const Color success = accent300;
  static const Color danger = neutral300;
}
