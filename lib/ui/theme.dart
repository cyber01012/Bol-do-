import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BolDoTheme {
  static const Color background = Color(0xFF060608);
  static const Color surface = Color(0xFF0C0C0E);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EA3B0);

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF16161C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF232330), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      primaryColor: const Color(0xFF6366F1),
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF6366F1)),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1E2025),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(color: const Color(0xFF1E2025), fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: const Color(0xFF1E2025), fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: const Color(0xFF1E2025), fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 14),
      ),
      useMaterial3: true,
    );
  }
}
