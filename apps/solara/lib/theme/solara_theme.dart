import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'solara_colors.dart';

class SolaraTheme {
  SolaraTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SolaraColors.celestialBlueDark,
      textTheme: _textTheme,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: SolaraColors.solaraGold,
        unselectedItemColor: SolaraColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: SolaraColors.solaraGold,
        surface: SolaraColors.celestialBlueDark,
        onSurface: SolaraColors.textPrimary,
      ),
    );
  }

  static TextTheme get _textTheme {
    return GoogleFonts.latoTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: SolaraColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: SolaraColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: SolaraColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: SolaraColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: SolaraColors.textSecondary,
        ),
      ),
    );
  }
}
