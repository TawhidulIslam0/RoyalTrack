import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clear(BuildContext context) async {
    await AppSettings.instance.clearLocal();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local favorites and saved decks cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AppHeader(subtitle: 'App preferences'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AnimatedBuilder(
                      animation: AppSettings.instance,
                      builder: (context, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dark mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: AppSettings.instance.darkMode,
                            onChanged: AppSettings.instance.setDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _clear(context),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear saved favorites and decks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}