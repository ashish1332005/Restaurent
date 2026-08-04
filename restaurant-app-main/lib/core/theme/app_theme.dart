import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF4D0A);
  static const Color primaryDark = Color(0xFFE23A00);
  static const Color accentGold = Color(0xFFFFB020);
  static const Color scaffoldBackgroundLight = Color(0xFFF7F8FB);
  static const Color cardColorLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color borderLight = Color(0xFFE6EAF0);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentGold,
      surface: cardColorLight,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundLight,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        headlineLarge: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
        headlineMedium: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.inter(color: textPrimaryLight, height: 1.45),
        bodyMedium: GoogleFonts.inter(color: textPrimaryLight, height: 1.45),
        bodySmall: GoogleFonts.inter(color: textSecondaryLight, height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: scaffoldBackgroundLight,
        foregroundColor: textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: cardColorLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0xFF101828).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF98A2B3),
              elevation: 0,
              shadowColor: primaryColor.withValues(alpha: 0.24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.1,
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.10),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: textPrimaryLight,
              side: const BorderSide(color: borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                primaryColor.withValues(alpha: 0.06),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryLight,
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderLight),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primaryColor : textSecondaryLight,
            size: selected ? 25 : 23,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF98A2B3)),
        labelStyle: GoogleFonts.inter(color: textSecondaryLight),
        prefixIconColor: textSecondaryLight,
        suffixIconColor: textSecondaryLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withValues(alpha: 0.12),
        disabledColor: const Color(0xFFF2F4F7),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(const Color(0xFFF8FAFC)),
        headingTextStyle: GoogleFonts.inter(
          color: textSecondaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        dataTextStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dividerThickness: 0.8,
        columnSpacing: 28,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
