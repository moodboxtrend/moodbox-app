import 'package:flutter/material.dart';

/// Design tokens for MoodBox.
/// Primary: violet-purple | Accent: amber | Per-type gradients for category cards.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6D4AFF);
  static const Color primaryDark = Color(0xFFB39DFF);
  static const Color accent = Color(0xFFFFB020);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Light mode ──
  static const Color lightBackground = Color(0xFFF7F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E1B2E);
  static const Color lightMuted = Color(0xFF6B6478);

  // ── Dark mode ──
  static const Color darkBackground = Color(0xFF120F1D);
  static const Color darkSurface = Color(0xFF1B1830);
  static const Color darkText = Color(0xFFF0EEF7);
  static const Color darkMuted = Color(0xFFA39CBA);

  // ── Per content-type gradient pairs (start → end) ──
  static const Color jokeStart   = Color(0xFFFF8C42);
  static const Color jokeEnd     = Color(0xFFFFD166);

  static const Color recipeStart = Color(0xFFFF4E7A);
  static const Color recipeEnd   = Color(0xFFFF8FA3);

  static const Color storyStart  = Color(0xFF6D4AFF);
  static const Color storyEnd    = Color(0xFFA78BFA);

  static const Color wallpaperStart = Color(0xFF06B6D4);
  static const Color wallpaperEnd   = Color(0xFF67E8F9);

  static const Color videoStart  = Color(0xFF10B981);
  static const Color videoEnd    = Color(0xFF6EE7B7);

  static const Color generalStart = Color(0xFF8B5CF6);
  static const Color generalEnd   = Color(0xFFC4B5FD);

  // ── Quote / Hero banner ──
  static const Color quoteStart  = Color(0xFF1B1830);
  static const Color quoteEnd    = Color(0xFF2D2459);

  // ── Splash gradient ──
  static const Color splashTop    = Color(0xFF0D0B1A);
  static const Color splashBottom = Color(0xFF1B1830);

  // ── Helpers ──
  static List<Color> gradientForType(String type) {
    switch (type) {
      case 'joke':      return [jokeStart, jokeEnd];
      case 'recipe':    return [recipeStart, recipeEnd];
      case 'story':     return [storyStart, storyEnd];
      case 'wallpaper': return [wallpaperStart, wallpaperEnd];
      case 'video':     return [videoStart, videoEnd];
      default:          return [generalStart, generalEnd];
    }
  }

  static List<Color> gradientFromHex(String? hex, String type) {
    if (hex != null &&
        hex.startsWith('#') &&
        hex.length >= 7 &&
        hex.toUpperCase() != '#6D4AFF') {
      try {
        final clean = hex.replaceAll('#', '');
        final baseColor = Color(int.parse('FF$clean', radix: 16));
        final hsl = HSLColor.fromColor(baseColor);
        final lighterColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
        return [baseColor, lighterColor];
      } catch (_) {}
    }
    return gradientForType(type);
  }

  static Color textOnGradientForType(String type) {
    return Colors.white;
  }
}
