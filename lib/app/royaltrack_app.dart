import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../screens/main_shell.dart';

class RoyalTrackApp extends StatefulWidget {
  const RoyalTrackApp({super.key});
  @override
  State<RoyalTrackApp> createState() => _RoyalTrackAppState();
}

class _RoyalTrackAppState extends State<RoyalTrackApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const royalBlue = Color(0xFF2563EB);
    const royalGold = Color(0xFFF5B82E);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: royalBlue,
      secondary: royalGold,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E131F) : const Color(0xFFF1F5FB),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF172033) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 3,
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        indicatorColor: royalBlue.withValues(alpha: isDark ? 0.28 : 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppSettings.instance.darkMode;
    return MaterialApp(
      title: 'RoyalTrack',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainShell(),
    );
  }
}