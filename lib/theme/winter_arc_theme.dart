import 'package:flutter/material.dart';

class WinterArcTheme {
  // Soft Neubrutalism Palette
  // Vibrant, tactile, punchy pastel accents with high-contrast borders and solid offset shadows
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF171A23);
  static const Color surfaceCard = Color(0xFF1E222E);
  static const Color surfaceElevated = Color(0xFF262B3A);

  // Soft Neo Colors
  static const Color neoYellow = Color(0xFFFFDE59);
  static const Color neoMint = Color(0xFF5CE5B4);
  static const Color neoCoral = Color(0xFFFF6B8B);
  static const Color neoLavender = Color(0xFFB8A4F8);
  static const Color neoCyan = Color(0xFF45C0FF);
  static const Color neoOrange = Color(0xFFFF8E3C);

  static const Color borderBlack = Color(0xFF000000);
  static const Color borderSubtle = Color(0xFF2E3446);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA6ADBB);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color dangerRed = Color(0xFFFF5252);
  static const Color successGreen = neoMint;

  /// Soft Neubrutalist Box Decoration with signature solid offset shadow & rounded border
  static BoxDecoration neoBoxDecoration({
    double radius = 18,
    Color? fillColor,
    Color? borderColor,
    Color? shadowColor,
    double borderWidth = 2.2,
    Offset shadowOffset = const Offset(4, 4),
  }) {
    return BoxDecoration(
      color: fillColor ?? surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? borderBlack,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? borderBlack,
          offset: shadowOffset,
          blurRadius: 0, // Zero blur is the defining hallmark of neubrutalism
        ),
      ],
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neoYellow,
      colorScheme: const ColorScheme.dark(
        primary: neoYellow,
        secondary: neoMint,
        surface: surface,
        error: dangerRed,
        onPrimary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderBlack, width: 2.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderBlack, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neoYellow, width: 2.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerRed, width: 2.0),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neoYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderBlack, width: 2.2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: borderBlack, width: 2.4),
        ),
      ),
    );
  }
}
