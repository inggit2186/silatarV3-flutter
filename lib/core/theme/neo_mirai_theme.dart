import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NEO MIRAI Theme - Matching SILATAR V2 Web Theme
/// Based on CSS variables from app.css and neo-mirai-home.css

class NeoMiraiColors {
  // Primary Colors - Gold (matching web gold variable)
  static const Color gold = Color(0xFFB08D57);
  static const Color goldBright = Color(0xFFC9A96E);
  static const Color goldLight = Color(0xFFD4BC8E);

  // Background Colors (matching web paper variables)
  static const Color paper = Color(0xFFF5F3EF);
  static const Color paperSoft = Color(0xFFEBE8E2);
  static const Color paperDeep = Color(0xFFD6D2C8);

  // Text Colors (matching web ink variables)
  static const Color ink = Color(0xFF2A2825);
  static const Color inkSoft = Color(0xFF524B44);
  static const Color ash = Color(0xFF8C857A);

  // Accent Colors
  static const Color sun = Color(0xFFE8A84C);
  static const Color sunDeep = Color(0xFFD08A35);
  static const Color night = Color(0xFF2D4859);
  static const Color nightSoft = Color(0xFF3D6B82);

  // Utility Colors
  static const Color line = Color(0xFFBAB4AB);
  static const Color rice = Color(0xFFF7F5F0);
  static const Color focus = Color(0xFF9EB3D1);

  // Status Colors (matching web)
  static const Color success = Color(0xFF5D9E5F);
  static const Color warning = Color(0xFFE8A84C);
  static const Color error = Color(0xFFD45D5D);
  static const Color info = Color(0xFF4A8DB5);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldBright],
  );

  static const LinearGradient paperGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [paper, paperSoft],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, nightSoft],
  );
}

class NeoMiraiTheme {
  // Expose gradients from NeoMiraiColors
  static LinearGradient get goldGradient => NeoMiraiColors.goldGradient;
  static LinearGradient get paperGradient => NeoMiraiColors.paperGradient;
  static LinearGradient get nightGradient => NeoMiraiColors.nightGradient;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: NeoMiraiColors.gold,
      scaffoldBackgroundColor: NeoMiraiColors.paper,

      // Color Scheme - Matching Web Variables
      colorScheme: const ColorScheme.light(
        primary: NeoMiraiColors.gold,
        primaryContainer: NeoMiraiColors.goldLight,
        secondary: NeoMiraiColors.night,
        secondaryContainer: NeoMiraiColors.nightSoft,
        tertiary: NeoMiraiColors.sun,
        surface: NeoMiraiColors.rice,
        surfaceContainerHighest: NeoMiraiColors.paperSoft,
        error: NeoMiraiColors.error,
        onPrimary: NeoMiraiColors.rice,
        onSecondary: NeoMiraiColors.rice,
        onSurface: NeoMiraiColors.ink,
        onError: NeoMiraiColors.rice,
        outline: NeoMiraiColors.line,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: NeoMiraiColors.paper.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.chakraPetch(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        iconTheme: const IconThemeData(color: NeoMiraiColors.ink),
        surfaceTintColor: Colors.transparent,
      ),

      // Text Theme - Using Chakra Petch (matching web font)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.chakraPetch(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: NeoMiraiColors.ink,
          letterSpacing: 0.5,
        ),
        displayMedium: GoogleFonts.chakraPetch(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: NeoMiraiColors.ink,
          letterSpacing: 0.3,
        ),
        displaySmall: GoogleFonts.chakraPetch(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        headlineLarge: GoogleFonts.chakraPetch(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        headlineMedium: GoogleFonts.chakraPetch(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        headlineSmall: GoogleFonts.chakraPetch(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        titleLarge: GoogleFonts.chakraPetch(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        titleMedium: GoogleFonts.chakraPetch(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.ink,
        ),
        titleSmall: GoogleFonts.chakraPetch(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.inkSoft,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: NeoMiraiColors.ink,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: NeoMiraiColors.ink,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: NeoMiraiColors.inkSoft,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.ink,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.inkSoft,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.ash,
        ),
      ),

      // Input Decoration Theme - Matching Web Style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoMiraiColors.rice,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NeoMiraiColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NeoMiraiColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NeoMiraiColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NeoMiraiColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NeoMiraiColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: NeoMiraiColors.inkSoft,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: NeoMiraiColors.ash,
        ),
        prefixIconColor: NeoMiraiColors.inkSoft,
        suffixIconColor: NeoMiraiColors.inkSoft,
      ),

      // Elevated Button Theme - Matching Web Ticket Pill Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoMiraiColors.gold,
          foregroundColor: NeoMiraiColors.rice,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.chakraPetch(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NeoMiraiColors.gold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.chakraPetch(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeoMiraiColors.gold,
          side: const BorderSide(color: NeoMiraiColors.gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.chakraPetch(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: NeoMiraiColors.rice,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NeoMiraiColors.line, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: NeoMiraiColors.rice,
        selectedItemColor: NeoMiraiColors.gold,
        unselectedItemColor: NeoMiraiColors.ash,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.chakraPetch(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.chakraPetch(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: NeoMiraiColors.line,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: NeoMiraiColors.paperSoft,
        selectedColor: NeoMiraiColors.goldLight,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: NeoMiraiColors.ink,
        ),
        side: const BorderSide(color: NeoMiraiColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NeoMiraiColors.gold,
        foregroundColor: NeoMiraiColors.rice,
        elevation: 4,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeoMiraiColors.ink,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: NeoMiraiColors.rice,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: NeoMiraiColors.rice,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.chakraPetch(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NeoMiraiColors.ink,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: NeoMiraiColors.inkSoft,
        ),
      ),

      // BottomSheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NeoMiraiColors.rice,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
