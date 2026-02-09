import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors - Dark Theme
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF121212);
  static const Color primaryDarker = Color(0xFF0A0A0A);
  static const Color secondaryDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF252525);

  // Primary colors - Light Theme
  static const Color primaryLight = Color(0xFFF8FAFC); // Very light gray-blue
  static const Color secondaryLight = Color(0xFFFFFFFF); // Pure white
  static const Color cardLight = Color(0xFFFFFFFF); // White cards
  static const Color surfaceLight = Color(0xFFF1F5F9); // Light surface

  // Accent colors
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentGreenDark = Color(0xFF059669); // Darker green for light theme
  static const Color disconnectedRed = Color(0xFFEF4444);
  static const Color connectingYellow = Color(0xFFF59E0B);

  // Text colors - Dark Theme
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFAAAAAA);

  // Text colors - Light Theme
  static const Color textDark = Color(0xFF1E293B); // Dark slate
  static const Color textMedium = Color(0xFF475569); // Medium slate
  static const Color textLightGrey = Color(0xFF94A3B8); // Light slate

  // Border colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF323232);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, accentGreen],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, secondaryDark],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, secondaryLight],
  );

  // Light Theme
  static ThemeData lightTheme([String languageCode = 'en']) {
    final isRtlLanguage = languageCode == 'fa' || languageCode == 'ar';

    final baseTextTheme = isRtlLanguage
        ? GoogleFonts.vazirmatnTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    final baseAppBarTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textDark,
          )
        : GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textDark,
          );

    final baseButtonTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w600)
        : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: primaryLight,
      primaryColor: accentGreenDark,
      colorScheme: const ColorScheme.light().copyWith(
        primary: accentGreenDark,
        secondary: accentGreen,
        surface: secondaryLight,
        error: disconnectedRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseAppBarTextStyle,
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreenDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: accentGreenDark.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: baseButtonTextStyle,
        ),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGreenDark, width: 2),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme([String languageCode = 'en']) {
    final isRtlLanguage = languageCode == 'fa' || languageCode == 'ar';

    final baseTextTheme = isRtlLanguage
        ? GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    final baseAppBarTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textLight,
          )
        : GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textLight,
          );

    final baseButtonTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w600)
        : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: primaryDark,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: primaryDark,
        error: disconnectedRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseAppBarTextStyle,
        iconTheme: const IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textLight,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: baseButtonTextStyle,
        ),
      ),
      textTheme: baseTextTheme,
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
    );
  }
}
