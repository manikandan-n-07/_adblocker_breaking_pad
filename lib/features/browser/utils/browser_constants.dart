import 'package:flutter/material.dart';

class BrowserConstants {
  static const String appName = 'BREAKING PAD';
  static const String appFullName = 'BREAKING PAD Browser';
  static const String appVersion = '1.0.0';
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

  // Pure Monochrome Black & White Palette - ZERO other colors
  static const Color background = Color(0xFF000000);       // Pure Black
  static const Color surface = Color(0xFF0D0D0D);          // Near Black Card
  static const Color surfaceLight = Color(0xFF1A1A1A);     // Lifted Surface
  static const Color surfaceHighlight = Color(0xFF262626); // Hover/Selection
  static const Color border = Color(0xFF262626);           // Subtle Line
  static const Color borderLight = Color(0xFF404040);      // High-Contrast Border
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure White Text
  static const Color textSecondary = Color(0xFF888888);    // Mid Grey
  static const Color textHint = Color(0xFF555555);         // Low Grey
  static const Color accent = Color(0xFFFFFFFF);           // White Accent
  static const Color accentCyan = Color(0xFFFFFFFF);       // White
  static const Color iconColor = Color(0xFFFFFFFF);        // White Icon
  static const Color iconMuted = Color(0xFF777777);        // Muted Grey Icon
  static const Color success = Color(0xFFFFFFFF);          // White
  static const Color warning = Color(0xFFB0B0B0);          // Light Grey
  static const Color error = Color(0xFFFFFFFF);            // White
  static const Color privateModeAccent = Color(0xFFB0B0B0);// Light Grey
  static const Color privateModeSurface = Color(0xFF050505);// Deep Black
}
