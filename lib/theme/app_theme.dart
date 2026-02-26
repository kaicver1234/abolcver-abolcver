import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors - Pure Black Theme
  static const Color primaryCyan = Color(0xFF00D9FF);
  static const Color primaryGreen = Color(0xFF00FFA3); // Alias for compatibility
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryDarker = Color(0xFF000000);
  static const Color secondaryDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF121212);

  // Accent colors
  static const Color accentCyan = Color(0xFF00FFA3);
  static const Color disconnectedRed = Color(0xFFEF4444);
  static const Color connectingYellow = Color(0xFFF59E0B);

  // Text colors - High Contrast
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFE0E0E0);

  // Border colors
  static const Color borderDark = Color(0xFF2A2A2A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCyan, accentCyan],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, secondaryDark],
  );

  static TextTheme _removeDecorations(TextTheme textTheme) {
    const style = TextStyle(decoration: TextDecoration.none);
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.merge(style),
      displayMedium: textTheme.displayMedium?.merge(style),
      displaySmall: textTheme.displaySmall?.merge(style),
      headlineLarge: textTheme.headlineLarge?.merge(style),
      headlineMedium: textTheme.headlineMedium?.merge(style),
      headlineSmall: textTheme.headlineSmall?.merge(style),
      titleLarge: textTheme.titleLarge?.merge(style),
      titleMedium: textTheme.titleMedium?.merge(style),
      titleSmall: textTheme.titleSmall?.merge(style),
      bodyLarge: textTheme.bodyLarge?.merge(style),
      bodyMedium: textTheme.bodyMedium?.merge(style),
      bodySmall: textTheme.bodySmall?.merge(style),
      labelLarge: textTheme.labelLarge?.merge(style),
      labelMedium: textTheme.labelMedium?.merge(style),
      labelSmall: textTheme.labelSmall?.merge(style),
    );
  }

  // Dark Theme
  static ThemeData darkTheme([String languageCode = 'en']) {
    final isRtlLanguage = languageCode == 'fa' || languageCode == 'ar';

    // For RTL languages, use system default fonts which support Persian better
    final baseTextTheme = isRtlLanguage
        ? ThemeData.dark().textTheme
        : GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    final baseAppBarTextStyle = isRtlLanguage
        ? const TextStyle(
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
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          )
        : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: primaryDark,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryCyan,
        secondary: accentCyan,
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: baseButtonTextStyle,
        ),
      ),
      textTheme: _removeDecorations(baseTextTheme.apply(
        bodyColor: textLight,
        displayColor: textLight,
      )),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
    );
  }
}
