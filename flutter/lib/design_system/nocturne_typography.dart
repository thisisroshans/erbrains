import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nocturne_colors.dart';

/// Nocturne design system — type tokens.
///
/// Inter for both heading and body, per the handoff. Headings sit at 500
/// weight and never bolder — hierarchy here comes from size and space, not
/// weight. The fixed scale (h1..h6) mirrors `styles.css`; screens are free
/// to use one-off sizes for chrome (e.g. the 20px screen title) the same
/// way the static HTML does.
class NocturneType {
  NocturneType._();

  static TextStyle _heading(double size, {double? letterSpacing}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.12,
        letterSpacing: letterSpacing ?? size * -0.015,
        color: NocturneColors.text,
      );

  static TextStyle _body(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: 1.55,
        color: NocturneColors.text,
      );

  static TextStyle get h1 => _heading(42);
  static TextStyle get h2 => _heading(32);
  static TextStyle get h3 => _heading(25);
  static TextStyle get h4 => _heading(20);
  static TextStyle get h5 => _heading(16);
  static TextStyle get h6 => _heading(13, letterSpacing: 13 * 0.08).copyWith(
        // h6 is the uppercase eyebrow variant of the heading scale.
      );

  static TextStyle get body => _body(15);
  static TextStyle get bodyMedium => _body(15, weight: FontWeight.w500);
  static TextStyle get bodySmall => _body(13);
  static TextStyle get caption =>
      _body(12).copyWith(color: NocturneColors.neutral300);
  static TextStyle get micro =>
      _body(11).copyWith(color: NocturneColors.neutral400);

  static TextStyle get cardKicker => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 10 * 0.1,
        color: NocturneColors.accent,
      );

  static TextStyle get cardTitle => _heading(17, letterSpacing: 0);

  static TextStyle get eyebrow => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 12 * 0.06,
        color: NocturneColors.neutral300,
      );
}
