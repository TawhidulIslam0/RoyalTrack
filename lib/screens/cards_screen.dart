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

  final TextEditingController _searchController =
      TextEditingController();

  static const List<String> _filters = [
    'All',
    'Common',
    'Rare',
    'Epic',
    'Legendary',
    'Champion',
    'Tower',
  ];

  static const List<Map<String, dynamic>> _fallbackTowerTroops = [
    {
      'name': 'Tower Princess',
      'rarity': 'common',
      'isTowerTroop': true,
    },
    {
      'name': 'Cannoneer',
      'rarity': 'epic',
      'isTowerTroop': true,
    },
    {
      'name': 'Dagger Duchess',
      'rarity': 'legendary',
      'isTowerTroop': true,
    },
    {
      'name': 'Royal Chef',
      'rarity': 'legendary',
      'isTowerTroop': true,
    },
  ];

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

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.instance.cards();

      if (!mounted) return;

      final rawItems =
          List<dynamic>.from(data['items'] ?? []);

      final rawTowers =
          List<dynamic>.from(data['supportItems'] ?? []);

      final List<Map<String, dynamic>> standard =
          rawItems.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map['isTowerTroop'] = false;
        return map;
      }).toList();

      final List<Map<String, dynamic>> towers =
          rawTowers.isNotEmpty
              ? rawTowers.map((item) {
                  final map =
                      Map<String, dynamic>.from(item as Map);
                  map['isTowerTroop'] = true;
                  return map;
                }).toList()
              : _fallbackTowerTroops
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();

      setState(() {
        cards = [...standard, ...towers];
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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
      final name =
          (c['name'] ?? '').toString().toLowerCase();

      final cardRarity =
          rarity(c).trim().toLowerCase();

      final isTower = c['isTowerTroop'] == true;

      final matchesName =
          q.isEmpty || name.contains(q);

      final matchesFilter =
          selectedFilter == 'all' ||
          (selectedFilter == 'tower' && isTower) ||
          (!isTower && cardRarity == selectedFilter);

      return matchesName && matchesFilter;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          const AppHeader(
            subtitle: 'Search and browse the official card catalog',
          ),

          // Search bar
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

                          setState(() {
                            query = '';
                          });
                        },
                      ),
                hintText: 'Search cards & tower troops...',
                filled: true,
                fillColor: theme
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(90),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),

          // Rarity filters
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: _filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final isSelected = filter == f;

                final accent = f == 'All'
                    ? theme.colorScheme.primary
                    : f == 'Tower'
                        ? const Color(0xFF2563EB)
                        : _rarityColor(f);

                return ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? accent : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: accent.withAlpha(34),
                  side: BorderSide(
                    color: isSelected
                        ? accent
                        : theme.colorScheme.outlineVariant,
                  ),
                  onSelected: (_) {
                    setState(() {
                      filter = f;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Loading state
          if (loading)
            const Expanded(
              child: LoadingView(
                label: 'Loading cards…',
              ),
            )

          // Error state
          else if (error != null)
            Expanded(
              child: ErrorView(
                error: error!,
                onRetry: load,
              ),
            )

          // Empty state
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyView(
                      message: 'No matching cards found.',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(
                        Icons.filter_alt_off_rounded,
                      ),
                      label: const Text('Reset filters'),
                    ),
                  ],
                ),
              ),
            )

          // Cards grid
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: load,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    8,
                    14,
                    24,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];

                    final img = cardImage(c);
                    final cardRarityText = rarity(c);
                    final accent =
                        _rarityColor(cardRarityText);

                    final elixir = c['elixirCost'];
                    final isTower =
                        c['isTowerTroop'] == true;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Card image
                            Expanded(
                              child: img.isEmpty
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
                                      errorBuilder:
                                          (_, __, ___) {
                                        return Icon(
                                          isTower
                                              ? Icons.castle_rounded
                                              : Icons.broken_image_rounded,
                                          size: isTower ? 44 : 28,
                                          color: isTower
                                              ? const Color(0xFF2563EB)
                                              : null,
                                        );
                                      },
                                    ),
                            ),

                            const SizedBox(height: 8),

                            // Card name
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

                            const SizedBox(height: 6),

                            // Card information
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                if (isTower) ...[
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB)
                                          .withAlpha(26),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Tower',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ] else if (elixir != null) ...[
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9333EA)
                                          .withAlpha(26),
                                      borderRadius:
                                          BorderRadius.circular(8),
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

                                // Rarity
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
}