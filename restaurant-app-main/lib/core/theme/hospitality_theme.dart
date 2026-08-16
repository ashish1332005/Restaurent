import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HospitalityColors {
  static const saffron = Color(0xFFC99232);
  static const saffronDark = Color(0xFF9B6D1C);
  static const turmeric = Color(0xFFE6B84E);
  static const leaf = Color(0xFF237A59);
  static const ink = Color(0xFF071A31);
  static const mutedInk = Color(0xFF667085);
  static const canvas = Color(0xFFFFFCF7);
  static const surface = Colors.white;
  static const softSaffron = Color(0xFFFFF1D6);
  static const softLeaf = Color(0xFFE5F4EB);
  static const outline = Color(0xFFE6DED2);
  static const danger = Color(0xFFB42318);
}

abstract final class HospitalitySpace {
  static const xxs = 4.0, xs = 8.0, sm = 12.0, md = 16.0;
  static const lg = 24.0, xl = 32.0, xxl = 48.0;
}

abstract final class HospitalityRadius {
  static const small = 10.0, medium = 16.0, large = 24.0, pill = 999.0;
}

abstract final class HospitalityTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: HospitalityColors.saffron,
      primary: HospitalityColors.saffron,
      secondary: HospitalityColors.leaf,
      surface: HospitalityColors.surface,
      error: HospitalityColors.danger,
      outline: HospitalityColors.outline,
    );
    final base = GoogleFonts.dmSansTextTheme();
    final text = base.copyWith(
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: HospitalityColors.ink,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: HospitalityColors.ink,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: HospitalityColors.ink,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: HospitalityColors.ink,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: HospitalityColors.ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        height: 1.45,
        color: HospitalityColors.ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.45,
        color: HospitalityColors.ink,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        height: 1.4,
        color: HospitalityColors.mutedInk,
      ),
      labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HospitalityRadius.medium),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(HospitalityRadius.small),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: HospitalityColors.canvas,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: HospitalityColors.canvas,
        foregroundColor: HospitalityColors.ink,
        titleTextStyle: text.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: HospitalityColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded.copyWith(
          side: const BorderSide(color: HospitalityColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HospitalityColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: HospitalityColors.mutedInk),
        hintStyle: const TextStyle(color: Color(0xFF9B8D87)),
        prefixIconColor: HospitalityColors.mutedInk,
        suffixIconColor: HospitalityColors.mutedInk,
        border: inputBorder(HospitalityColors.outline),
        enabledBorder: inputBorder(HospitalityColors.outline),
        focusedBorder: inputBorder(HospitalityColors.saffron, 1.5),
        errorBorder: inputBorder(HospitalityColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: HospitalityColors.saffron,
          disabledBackgroundColor: HospitalityColors.outline,
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: HospitalityColors.ink,
          side: const BorderSide(color: HospitalityColors.outline),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HospitalityColors.saffronDark,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HospitalityRadius.small),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HospitalityColors.surface,
        selectedColor: HospitalityColors.softSaffron,
        side: const BorderSide(color: HospitalityColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HospitalityRadius.pill),
        ),
        labelStyle: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: HospitalityColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HospitalityRadius.large),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HospitalityColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: HospitalityColors.softSaffron,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: HospitalityColors.ink),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: HospitalityColors.ink, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: HospitalityColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(
        color: HospitalityColors.outline,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HospitalityColors.saffron,
      ),
    );
  }
}
