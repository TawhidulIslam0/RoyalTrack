import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'player_screen.dart';
import 'clan_screen.dart';
import 'cards_screen.dart';
import 'deck_builder_screen.dart';
import 'settings_screen.dart';
import 'rankings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int selected = 0;
  final screens = const [HomeScreen(), PlayerScreen(), ClanScreen(), CardsScreen(), DeckBuilderScreen(), RankingsScreen(), SettingsScreen()];
  final labels = const ['Home', 'Players', 'Clans', 'Cards', 'Decks', 'Rankings', 'Settings'];
  final icons = const [Icons.home_rounded, Icons.person_search_rounded, Icons.shield_rounded, Icons.style_rounded, Icons.view_carousel_rounded, Icons.leaderboard_rounded, Icons.settings_rounded];
  @override Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: selected, children: screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => setState(() => selected = i),
      destinations: List.generate(labels.length, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i])),
    ),
  );
}
