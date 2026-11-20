import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();
  late SharedPreferences _prefs;
  void init(SharedPreferences prefs) => _prefs = prefs;
  bool get darkMode => _prefs.getBool('darkMode') ?? true;
  String get backendUrl => _prefs.getString('backendUrl') ?? 'http://10.0.2.2:3000';
  Future<void> setDarkMode(bool value) async { await _prefs.setBool('darkMode', value); notifyListeners(); }
  Future<void> setBackendUrl(String value) async { await _prefs.setString('backendUrl', value.trim().replaceAll(RegExp(r'/$'), '')); notifyListeners(); }
  List<String> get favorites => _prefs.getStringList('favorites') ?? [];
  Future<void> toggleFavorite(String tag) async {
    final items = favorites;
    final clean = tag.trim().toUpperCase().replaceAll('#', '');
    if (items.contains(clean)) { items.remove(clean); } else { items.add(clean); }
    await _prefs.setStringList('favorites', items);
    notifyListeners();
  }
  bool isFavorite(String tag) => favorites.contains(tag.trim().toUpperCase().replaceAll('#', ''));
  List<String> get savedDecks => _prefs.getStringList('savedDecks') ?? [];
  Future<void> saveDeck(String deckJson) async {
    final decks = savedDecks;
    decks.insert(0, deckJson);
    await _prefs.setStringList('savedDecks', decks);
    notifyListeners();
  }
  Future<void> removeDeckAt(int index) async {
    final decks = savedDecks;
    if (index >= 0 && index < decks.length) decks.removeAt(index);
    await _prefs.setStringList('savedDecks', decks);
    notifyListeners();
  }
  Future<void> clearLocal() async {
    await _prefs.remove('favorites');
    await _prefs.remove('savedDecks');
    notifyListeners();
  }
}
