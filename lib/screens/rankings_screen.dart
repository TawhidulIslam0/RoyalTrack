import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  final TextEditingController location =
      TextEditingController(text: 'global');

  List<Map<String, dynamic>> players = [];

  bool hasLoaded = false;
  bool loading = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final query = location.text.trim().isEmpty
        ? 'global'
        : location.text.trim();

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final raw = await ApiService.instance.rankings(query);

      if (!mounted) return;

      final List<dynamic> items = switch (raw) {
        List<dynamic> list => list,
        Map map when map['items'] is List =>
          map['items'] as List<dynamic>,
        _ => <dynamic>[],
      };

      final results = items
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        players = results;
        hasLoaded = true;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e;
        hasLoaded = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = location.text.trim().isEmpty
        ? 'global'
        : location.text.trim();

    return Material(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppHeader(
              subtitle: 'Global & regional player rankings',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: location,
                      decoration: const InputDecoration(
                        labelText: 'Location ID',
                        hintText: 'global or location ID',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => load(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: loading ? null : load,
                    child: const Text('Load'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (loading)
              const LoadingView(label: 'Loading rankings…'),

            if (error != null && !loading)
              ErrorView(
                error: error!,
                onRetry: load,
              ),

            if (!loading && error == null && players.isNotEmpty)
              ...players.take(100).map((item) {
                final clanMap = item['clan'] is Map
                    ? item['clan'] as Map
                    : null;

                final rank = item['rank'] ?? '—';
                final name = (item['name'] ?? 'Player').toString();
                final tag = (item['tag'] ?? '').toString();

                final trophies =
                    item['trophies'] ?? item['score'] ?? '';

                final clanName = clanMap?['name'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('$rank'),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      clanName != null
                          ? '$tag • $clanName'
                          : tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '$trophies',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),

            if (!loading && error == null && players.isEmpty)
              EmptyView(
                message: hasLoaded
                    ? 'No rankings returned for "$query".'
                    : 'Choose a location and load rankings.',
              ),
          ],
        ),
      ),
    );
  }
}