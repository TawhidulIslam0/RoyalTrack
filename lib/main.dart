import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/royaltrack_app.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppSettings.instance.init(prefs);
  runApp(const RoyalTrackApp());
}
