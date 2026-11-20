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
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;

  void _goToTab(int index) {
    setState(() => selected = index);
  }

  void _openRankings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RankingsScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateTab: _goToTab,
        onOpenRankings: _openRankings,
        onOpenSettings: _openSettings,
      ),
      const PlayerScreen(),
      const ClanScreen(),
      const CardsScreen(),
      const DeckBuilderScreen(),
    ];

    const labels = ['Home', 'Players', 'Clans', 'Cards', 'Decks'];
    const icons = [
      Icons.home_outlined,
      Icons.person_search_outlined,
      Icons.shield_outlined,
      Icons.style_outlined,
      Icons.view_carousel_outlined,
    ];
    const selectedIcons = [
      Icons.home_rounded,
      Icons.person_search_rounded,
      Icons.shield_rounded,
      Icons.style_rounded,
      Icons.view_carousel_rounded,
    ];

    return Scaffold(
      body: IndexedStack(index: selected, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: _goToTab,
        destinations: List.generate(
          labels.length,
          (i) => NavigationDestination(
            icon: Icon(icons[i]),
            selectedIcon: Icon(selectedIcons[i]),
            label: labels[i],
          ),
        ),
      ),
    );
  }
}