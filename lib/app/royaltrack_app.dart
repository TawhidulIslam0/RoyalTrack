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
  @override
  Widget build(BuildContext context) {
    final dark = AppSettings.instance.darkMode;
    const seed = Color(0xFF4D8DFF);
    return MaterialApp(
      title: 'RoyalTrack',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF4F6FA), cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero)),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark), useMaterial3: true, cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero)),
      home: const MainShell(),
    );
  }
}
