import 'package:flutter/material.dart';

class BrowserConstants {
  static const String appName = 'BREAKING PAD';
  static const String appFullName = 'BREAKING PAD Browser';
  static const String appVersion = '1.0.3';
  static const String defaultHomepage = ''; // Blank = Instant Home Screen

  // Realistic Chrome User Agents
  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.113 Mobile Safari/537.36';

  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  // Search Engine Configurations
  static const Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q={query}',
    'DuckDuckGo': 'https://duckduckgo.com/?q={query}',
    'Bing': 'https://www.bing.com/search?q={query}',
    'Brave': 'https://search.brave.com/search?q={query}',
    'Ecosia': 'https://www.ecosia.org/search?q={query}',
  };

  // ─────────────────────────── DARK PALETTE ───────────────────────────
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceHighlight = Color(0xFF262626);
  static const Color border = Color(0xFF262626);
  static const Color borderLight = Color(0xFF404040);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textHint = Color(0xFF555555);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentCyan = Color(0xFFFFFFFF);
  static const Color iconColor = Color(0xFFFFFFFF);
  static const Color iconMuted = Color(0xFF777777);
  static const Color success = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFFFFFFF);
  static const Color privateModeAccent = Color(0xFFB0B0B0);
  static const Color privateModeSurface = Color(0xFF050505);

  // ─────────────────────────── LIGHT PALETTE ──────────────────────────
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F2F2);
  static const Color lightSurfaceLight = Color(0xFFE5E5E5);
  static const Color lightSurfaceHighlight = Color(0xFFD9D9D9);
  static const Color lightBorder = Color(0xFFD9D9D9);
  static const Color lightBorderLight = Color(0xFFBFBFBF);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextHint = Color(0xFFAAAAAA);
  static const Color lightIconColor = Color(0xFF000000);
  static const Color lightIconMuted = Color(0xFF888888);

  // ─────────────────────────── THEME HELPERS ──────────────────────────
  static ThemeData buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white,
        surface: surface,
        error: Colors.white,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      cardColor: surface,
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white38;
          }
          return Colors.white12;
        }),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black,
        surface: lightSurface,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      cardColor: lightSurface,
      dividerColor: lightBorder,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.black),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black38;
          }
          return Colors.black12;
        }),
      ),
      useMaterial3: true,
    );
  }
}
