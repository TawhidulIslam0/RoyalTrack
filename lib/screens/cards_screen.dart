import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];

  bool loading = false;
  Object? error;

  String query = '';
  String filter = 'All';

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filters = [
    'All',
    'Evo',
    'Hero',
    'Tower',
    'Common',
    'Rare',
    'Epic',
    'Legendary',
    'Champion',
  ];

static const Set<String> _evolutionNames = {
    'barbarians',
    'royal giant',
    'firecracker',
    'skeletons',
    'mortar',
    'knight',
    'royal recruits',
    'bats',
    'archers',
    'ice spirit',
    'valkyrie',
    'bomber',
    'wall breakers',
    'tesla',
    'zap',
    'battle ram',
    'wizard',
    'goblin barrel',
    'goblin giant',
    'goblin drill',
    'goblin cage',
    'pekka',
    'mega knight',
    'electro dragon',
    'musketeer',
    'cannon',
    'giant snowball',
    'dart goblin',
    'lumberjack',
    'hunter',
    'executioner',
    'witch',
    'inferno dragon',
    'skeleton barrel',
    'furnace',
    'baby dragon',
    'skeleton army',
    'royal ghost',
    'royal hogs',
    'minion horde',
    'princess',
    'elite barbarians',
    'electro giant',
    'giant',
    'mirror',
  };

  static const Set<String> _heroNames = {
    'knight',
    'giant',
    'mini pekka',
    'musketeer',
    'ice golem',
    'wizard',
    'goblins',
    'mega minion',
    'barbarian barrel',
    'magic archer',
    'balloon',
    'bowler',
    'dark prince',
    'tombstone',
    'berserker',
    'valkyrie',
    'ice wizard',
    'electro wizard',

  };

  static const List<Map<String, dynamic>> _fallbackTowerTroops = [
    {'name': 'Tower Princess', 'rarity': 'common', 'isTowerTroop': true},
    {'name': 'Cannoneer', 'rarity': 'epic', 'isTowerTroop': true},
    {'name': 'Dagger Duchess', 'rarity': 'legendary', 'isTowerTroop': true},
    {'name': 'Royal Chef', 'rarity': 'legendary', 'isTowerTroop': true},
  ];

  String _normalizeName(dynamic raw) {
    return (raw ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _spriteForCard(Map<String, dynamic> c, String activeFilter) {
    final icons = c['iconUrls'];
    final regularUrl = cardImage(c);

    if (icons is Map) {
      final evoUrl = (icons['evolutionMedium'] ?? icons['evoMedium'] ?? '')
          .toString()
          .trim();

      final heroUrl = (icons['heroMedium'] ?? '').toString().trim();

      if (activeFilter == 'Evo' && evoUrl.isNotEmpty) {
        return evoUrl;
      }

      if (activeFilter == 'Hero' && heroUrl.isNotEmpty) {
        return heroUrl;
      }
    }

    return regularUrl;
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final data = await ApiService.instance.cards();

      if (!mounted) return;

      final rawItems = List<dynamic>.from(data['items'] ?? []);
      final rawTowers = List<dynamic>.from(data['supportItems'] ?? []);

      final standard = rawItems.map((c) {
        final map = Map<String, dynamic>.from(c as Map);
        final key = _normalizeName(map['name']);

        map['isTowerTroop'] = false;
        map['hasEvo'] = _evolutionNames.contains(key);
        map['hasHero'] = _heroNames.contains(key);

        return map;
      }).toList();

      final towers = rawTowers.isNotEmpty
          ? rawTowers.map((c) {
              final map = Map<String, dynamic>.from(c as Map);

              map['isTowerTroop'] = true;
              map['hasEvo'] = false;
              map['hasHero'] = false;

              return map;
            }).toList()
          : _fallbackTowerTroops
              .map((t) => Map<String, dynamic>.from(t))
              .toList();

      setState(() {
        cards = [...standard, ...towers];
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _rarityColor(String rarityLabel) {
    switch (rarityLabel.trim().toLowerCase()) {
      case 'common':
        return const Color(0xFF64748B);
      case 'rare':
        return const Color(0xFFF59E0B);
      case 'epic':
        return const Color(0xFF9333EA);
      case 'legendary':
        return const Color(0xFF06B6D4);
      case 'champion':
        return const Color(0xFFEC4899);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _filterAccent(String f, ThemeData theme) {
    switch (f) {
      case 'All':
        return theme.colorScheme.primary;
      case 'Evo':
        return const Color(0xFF9333EA);
      case 'Hero':
        return const Color(0xFFD97706);
      case 'Tower':
        return const Color(0xFF2563EB);
      default:
        return _rarityColor(f);
    }
  }

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      query = '';
      filter = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = query.trim().toLowerCase();
    final selectedFilter = filter.trim().toLowerCase();

    final filtered = cards.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final cardRarity = rarity(c).trim().toLowerCase();

      final isTower = c['isTowerTroop'] == true;
      final isEvo = c['hasEvo'] == true;
      final isHero = c['hasHero'] == true;

      final matchesName = q.isEmpty || name.contains(q);

      final matchesFilter = selectedFilter == 'all' ||
          (selectedFilter == 'tower' && isTower) ||
          (selectedFilter == 'evo' && isEvo) ||
          (selectedFilter == 'hero' && isHero) ||
          (!isTower && cardRarity == selectedFilter);

      return matchesName && matchesFilter;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          const AppHeader(
            subtitle: 'Cards, evos, heroes & tower troops',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => query = '');
                        },
                      ),
                hintText: 'Search cards, evos, heroes & towers...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final isSelected = filter == f;
                final accent = _filterAccent(f, theme);

                return ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? accent : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: accent.withAlpha(34),
                  side: BorderSide(
                    color: isSelected ? accent : theme.colorScheme.outlineVariant,
                  ),
                  onSelected: (_) => setState(() => filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          if (loading)
            const Expanded(child: LoadingView(label: 'Loading cards…'))
          else if (error != null)
            Expanded(child: ErrorView(error: error!, onRetry: load))
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyView(message: 'No matching cards found.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Reset filters'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: load,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.80,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final img = _spriteForCard(c, filter);
                    final cardRarityText = rarity(c);
                    final accent = _rarityColor(cardRarityText);
                    final elixir = c['elixirCost'];

                    final isTower = c['isTowerTroop'] == true;
                    final isEvo = c['hasEvo'] == true;
                    final isHero = c['hasHero'] == true;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  img.isEmpty
                                      ? Icon(
                                          isTower
                                              ? Icons.castle_rounded
                                              : Icons.image_not_supported_rounded,
                                          size: isTower ? 44 : 28,
                                          color: isTower
                                              ? const Color(0xFF2563EB)
                                              : null,
                                        )
                                      : Image.network(
                                          img,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            isTower
                                                ? Icons.castle_rounded
                                                : Icons.broken_image_rounded,
                                            size: isTower ? 44 : 28,
                                            color: isTower
                                                ? const Color(0xFF2563EB)
                                                : null,
                                          ),
                                        ),
                                  if (filter == 'Evo' && isEvo)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: _modeTag(
                                        'EVO',
                                        const Color(0xFF9333EA),
                                      ),
                                    ),
                                  if (filter == 'Hero' && isHero)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: _modeTag(
                                        'HERO',
                                        const Color(0xFFD97706),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              safeString(c['name']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isEvo || isHero || isTower) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  if (isTower)
                                    _miniBadge(
                                      'Tower',
                                      const Color(0xFF2563EB),
                                    ),
                                  if (isEvo)
                                    _miniBadge(
                                      'Evo',
                                      const Color(0xFF9333EA),
                                    ),
                                  if (isHero)
                                    _miniBadge(
                                      'Hero',
                                      const Color(0xFFD97706),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isTower && elixir != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9333EA).withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$elixir elixir',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF9333EA),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    cardRarityText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}