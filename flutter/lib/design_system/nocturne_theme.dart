import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nocturne_colors.dart';
import 'nocturne_spacing.dart';

/// Builds the app's [ThemeData] from the Nocturne tokens. Screens should
/// still prefer the design-system widgets/text styles directly — this
/// mainly wires sane defaults (scaffold background, input decoration,
/// text selection color) so unstyled widgets fall back to the right look.
class NocturneTheme {
  NocturneTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: NocturneColors.bg,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: NocturneColors.bg,
        primary: NocturneColors.accent,
        secondary: NocturneColors.accent2,
        error: NocturneColors.neutral300,
        onSurface: NocturneColors.text,
        onPrimary: NocturneColors.bg,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: NocturneColors.accent,
        selectionColor: NocturneColors.accent.withValues(alpha: 0.3),
        selectionHandleColor: NocturneColors.accent,
      ),
      dividerColor: NocturneColors.divider,
      splashFactory: NoSplash.splashFactory,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: NocturneColors.text,
        displayColor: NocturneColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NocturneColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NocturneRadii.md),
          borderSide: BorderSide(color: NocturneColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NocturneRadii.md),
          borderSide: BorderSide(color: NocturneColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NocturneRadii.md),
          borderSide: const BorderSide(color: NocturneColors.accent),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NocturneColors.surface,
        contentTextStyle: GoogleFonts.inter(color: NocturneColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NocturneRadii.md),
        ),
      ),
    );
  }
}
