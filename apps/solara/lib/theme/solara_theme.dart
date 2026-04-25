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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        // HTML: active = var(--gold) #F9D976, inactive = rgba(255,255,255,0.35)
        selectedItemColor: const Color(0xFFF9D976),
        unselectedItemColor: Colors.white.withAlpha(89), // 0.35*255=89
        selectedLabelStyle: const TextStyle(fontSize: 9, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 9, letterSpacing: 0.5),
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
    // HTML: heading = Cormorant Garamond, body = DM Sans
    // Latin は DM Sans、それ以外（日本語）は Noto Sans JP にフォールバック。
    // Flutter は TextStyle.fontFamilyFallback を TextStyle merge でも引き継ぐので、
    // 個別の Text / RichText が明示的に fontFamily を指定していても、
    // 指定外の文字（＝日本語）は自動で Noto Sans JP にフォールバックする。
    final japaneseFallback = GoogleFonts.notoSansJp().fontFamily!;
    return GoogleFonts.dmSansTextTheme(
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
    ).apply(fontFamilyFallback: [japaneseFallback]);
  }
}
