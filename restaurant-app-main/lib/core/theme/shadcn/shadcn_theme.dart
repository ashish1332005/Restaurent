import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class ShadcnColors {
  // Light Zinc Palette
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF09090B);

  static const card = Color(0xFFFFFFFF);
  static const cardForeground = Color(0xFF09090B);

  static const popover = Color(0xFFFFFFFF);
  static const popoverForeground = Color(0xFF09090B);

  static const primary = Color(0xFF18181B); // Zinc 900
  static const primaryForeground = Color(0xFFFAFAFA);

  static const secondary = Color(0xFFF4F4F5); // Zinc 100
  static const secondaryForeground = Color(0xFF18181B);

  static const muted = Color(0xFFF4F4F5);
  static const mutedForeground = Color(0xFF71717A); // Zinc 500

  static const accent = Color(0xFFF4F4F5);
  static const accentForeground = Color(0xFF18181B);

  static const destructive = Color(0xFFEF4444); // Red 500
  static const destructiveForeground = Color(0xFFFAFAFA);

  static const border = Color(0xFFE4E4E7); // Zinc 200
  static const input = Color(0xFFE4E4E7);
  static const ring = Color(0xFF18181B);

  // Success / Emerald
  static const success = Color(0xFF10B981);
  static const successForeground = Color(0xFFFFFFFF);
  static const successMuted = Color(0xFFECFDF5);

  // Warning / Amber
  static const warning = Color(0xFFF59E0B);
  static const warningForeground = Color(0xFFFFFFFF);
  static const warningMuted = Color(0xFFFFFBEB);
}

abstract final class ShadcnRadius {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const full = 999.0;
}

abstract final class ShadcnTypography {
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: ShadcnColors.foreground,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ShadcnColors.foreground,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: ShadcnColors.foreground,
      );

  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: ShadcnColors.foreground,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ShadcnColors.foreground,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ShadcnColors.foreground,
      );

  static TextStyle get muted => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: ShadcnColors.mutedForeground,
      );

  static TextStyle get small => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ShadcnColors.mutedForeground,
      );
}
