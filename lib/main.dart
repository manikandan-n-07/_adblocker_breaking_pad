import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/browser/engine/adguard_engine.dart';
import 'features/browser/screens/browser_screen.dart';
import 'features/browser/services/pip_service.dart';
import 'features/browser/services/theme_service.dart';
import 'features/browser/utils/browser_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in parallel
  await Future.wait([
    ThemeService.instance.init(),
    PiPService.instance.init(),
  ]);

  // Initialize ad-blocking engine in background (non-blocking)
  AdGuardEngine.instance.init();

  runApp(const BreakingPadBrowserApp());
}

class BreakingPadBrowserApp extends StatefulWidget {
  const BreakingPadBrowserApp({super.key});

  @override
  State<BreakingPadBrowserApp> createState() => _BreakingPadBrowserAppState();
}

class _BreakingPadBrowserAppState extends State<BreakingPadBrowserApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    _applySystemUI();
  }

  void _applySystemUI() {
    final isDark = ThemeService.instance.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    _applySystemUI();

    return MaterialApp(
      title: BrowserConstants.appFullName,
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: BrowserConstants.buildLightTheme(),
      darkTheme: BrowserConstants.buildDarkTheme(),
      home: const BrowserScreen(),
    );
  }
}
