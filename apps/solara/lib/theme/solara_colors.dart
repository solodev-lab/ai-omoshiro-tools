import 'dart:ui';

class SolaraColors {
  SolaraColors._();

  // Primary
  static const solaraGoldLight = Color(0xFFF9D976);
  static const solaraGold = Color(0xFFF6BD60);
  static const celestialBlueLight = Color(0xFF0C1D3A);
  static const celestialBlueDark = Color(0xFF080C14);

  // Typography
  static const textPrimary = Color(0xFFEAEAEA);
  static const textSecondary = Color(0xFFACACAC);

  // Frosted Glass
  static const glassFill = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const glassBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // Elements
  static const fireStart = Color(0xFFFF6B6B);
  static const fireEnd = Color(0xFFFFD93D);
  static const fireGlow = Color(0xFFFFD93D);

  static const waterStart = Color(0xFF1A2980);
  static const waterEnd = Color(0xFF26D0CE);
  static const waterGlow = Color(0xFF26D0CE);

  static const airStart = Color(0xFF7F7F7F);
  static const airEnd = Color(0xFFC9C9C9);
  static const airGlow = Color(0xFFC9C9C9);

  static const earthStart = Color(0xFF593E2B);
  static const earthEnd = Color(0xFFB49774);
  static const earthGlow = Color(0xFFB49774);

  // Spiral
  static const spiralLine = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const spiralDotActive = Color(0xFFF6BD60);
  static const spiralDotInactive = Color(0x66FFFFFF);
  static const spiralDotDim = Color(0x55555555);

  // Planet colors (Major Arcana)
  static const planetSun = Color(0xFFFFD700);
  static const planetMoon = Color(0xFFC0C8E0);
  static const planetMercury = Color(0xFF7BE0AD);
  static const planetVenus = Color(0xFFFF8FA0);
  static const planetMars = Color(0xFFFF4444);
  static const planetJupiter = Color(0xFF6B5BFF);
  static const planetSaturn = Color(0xFF8B7355);
  static const planetUranus = Color(0xFF00D4FF);
  static const planetNeptune = Color(0xFF9B6BFF);
  static const planetPluto = Color(0xFF2A0030);

  // Element colors (Minor Arcana)
  static const elementWands = Color(0xFFFF6B35);
  static const elementCups = Color(0xFF4DA8DA);
  static const elementSwords = Color(0xFFB8C4D0);
  static const elementPentacles = Color(0xFFC4A265);

  // Moon event
  static const fullMoonRing = Color(0xFFFFF0C0);
  static const newMoonCore = Color(0xFF2A0030);

  static const _planetMap = {
    'sun': planetSun,
    'moon': planetMoon,
    'mercury': planetMercury,
    'venus': planetVenus,
    'mars': planetMars,
    'jupiter': planetJupiter,
    'saturn': planetSaturn,
    'uranus': planetUranus,
    'neptune': planetNeptune,
    'pluto': planetPluto,
  };

  static const _elementMap = {
    'fire': elementWands,
    'water': elementCups,
    'air': elementSwords,
    'earth': elementPentacles,
  };

  static Color planetColor(String planet) =>
      _planetMap[planet] ?? solaraGold;

  static Color elementColor(String element) =>
      _elementMap[element] ?? textSecondary;
}
