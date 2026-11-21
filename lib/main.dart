import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/browser/engine/adguard_engine.dart';
import 'features/browser/screens/browser_screen.dart';
import 'features/browser/utils/browser_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure high-contrast monochrome system navigation bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize engine asynchronously in background — app launches immediately with ZERO delay!
  AdGuardEngine.instance.init();

  runApp(const BreakingPadBrowserApp());
}

class BreakingPadBrowserApp extends StatelessWidget {
  const BreakingPadBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: BrowserConstants.appFullName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BrowserConstants.background,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: BrowserConstants.surface,
          error: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: BrowserConstants.surface,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        cardColor: BrowserConstants.surface,
        dividerColor: BrowserConstants.border,
        useMaterial3: true,
      ),
      home: const BrowserScreen(),
    );
  }
}
