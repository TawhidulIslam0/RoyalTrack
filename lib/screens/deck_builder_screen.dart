import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  List<Map<String, dynamic>> cards = [];
  List<Map<String, dynamic>> towerTroops = [];

  final List<Map<String, dynamic>> selected = [];

  Map<String, dynamic>? selectedTower;

  bool loading = false;
  Object? error;
  String search = '';

  static const List<Map<String, dynamic>> _fallbackTowerTroops = [
    {
      'name': 'Tower Princess',
      'rarity': 'Common',
      'isTowerTroop': true,
    },
    {
      'name': 'Cannoneer',
      'rarity': 'Epic',
      'isTowerTroop': true,
    },
    {
      'name': 'Dagger Duchess',
      'rarity': 'Legendary',
      'isTowerTroop': true,
    },
    {
      'name': 'Royal Chef',
      'rarity': 'Legendary',
      'isTowerTroop': true,
    },
  ];

  // ------------------------------------------------------------
  // CARD HELPERS
  // ------------------------------------------------------------

  bool _sameCard(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a['id'] != null && b['id'] != null) {
      return a['id'] == b['id'];
    }

    return safeString(a['name']).toLowerCase() ==
        safeString(b['name']).toLowerCase();
  }

  bool _isSelected(Map<String, dynamic> card) {
    return selected.any((item) => _sameCard(item, card));
  }

  // ------------------------------------------------------------
  // LOAD CARDS FROM API
  // ------------------------------------------------------------

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.instance.cards();

      if (!mounted) return;

      final rawItems = List<dynamic>.from(
        data['items'] ?? [],
      );

      final rawTowers = List<dynamic>.from(
        data['supportItems'] ?? [],
      );

      final parsedCards = rawItems
          .where((item) => item is Map)
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      final parsedTowers = rawTowers
          .where((item) => item is Map)
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      final finalTowerTroops = parsedTowers.isNotEmpty
          ? parsedTowers
          : _fallbackTowerTroops
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

      setState(() {
        cards = parsedCards;
        towerTroops = finalTowerTroops;
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

  @override
  void initState() {
    super.initState();
    load();
  }

  // ------------------------------------------------------------
  // ELIXIR CALCULATION
  // ------------------------------------------------------------

  double get average {
    if (selected.isEmpty) return 0;

    final total = selected.fold<double>(
      0,
      (sum, card) => sum + cardElixir(card).toDouble(),
    );

    return total / selected.length;
  }

  // ------------------------------------------------------------
  // TOWER TROOP SELECTION
  // ------------------------------------------------------------

  Future<void> _pickTowerTroop() async {
    final options = towerTroops.isNotEmpty
        ? towerTroops
        : _fallbackTowerTroops;

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Choose Tower Troop',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Applies to your tower slot for this deck',
                  ),
                ),
                ...options.map((tower) {
                  final name = safeString(tower['name']);

                  final isCurrent = selectedTower != null &&
                      safeString(selectedTower!['name'])
                          .toLowerCase() ==
                      name.toLowerCase();

                  final img = cardImage(tower);

                  return ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: img.isNotEmpty
                          ? Image.network(
                              img,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.castle_rounded,
                                );
                              },
                            )
                          : const Icon(Icons.castle_rounded),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(rarity(tower)),
                    trailing: isCurrent
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx, tower);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTower = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // ADD CARD
  // ------------------------------------------------------------

  void _addCard(Map<String, dynamic> card) {
    if (selected.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your deck already contains 8 cards.'),
        ),
      );
      return;
    }

    if (_isSelected(card)) {
      return;
    }

    setState(() {
      selected.add(card);
    });
  }

  // ------------------------------------------------------------
  // REMOVE CARD
  // ------------------------------------------------------------

  void _removeCard(int index) {
    if (index < 0 || index >= selected.length) return;

    setState(() {
      selected.removeAt(index);
    });
  }

  // ------------------------------------------------------------
  // CLEAR DECK
  // ------------------------------------------------------------

  void _clearDeck() {
    if (selected.isEmpty && selectedTower == null) {
      return;
    }

    setState(() {
      selected.clear();
      selectedTower = null;
    });
  }

  // ------------------------------------------------------------
  // SAVE DECK
  // ------------------------------------------------------------

  Future<void> _save() async {
    if (selected.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your deck must contain exactly 8 cards.'),
        ),
      );
      return;
    }

    final name =
        'Deck ${DateTime.now().month}/${DateTime.now().day}';

    final deckData = {
      'name': name,
      'towerTroop': selectedTower?['name'],
      'cards': selected.map((card) => card['name']).toList(),
      'ids': selected.map((card) => card['id']).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };

    final json = jsonEncode(deckData);

    try {
      await AppSettings.instance.saveDeck(json);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck saved locally'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save deck: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SAVED DECK HELPERS
  // ------------------------------------------------------------

  Map<String, dynamic>? _parseSavedDeck(String json) {
    try {
      final decoded = jsonDecode(json);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed saved data.
    }

    return null;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();

    final visibleCards = cards.where((card) {
      final name = safeString(card['name']).toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query);

      final alreadySelected = _isSelected(card);

      return matchesSearch && !alreadySelected;
    }).toList();

    final towerImage = selectedTower != null
        ? cardImage(selectedTower!)
        : '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppHeader(
            subtitle: 'Create and save your own decks',
          ),

          // ----------------------------------------------------
          // DECK BUILDER CARD
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deck header
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your deck',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${selected.length}/8 cards',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Average elixir: ${average.toStringAsFixed(1)}',
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // TOWER TROOP
                    // ------------------------------------------------

                    InkWell(
                      onTap: _pickTowerTroop,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha(90),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: towerImage.isNotEmpty
                                  ? Image.network(
                                      towerImage,
                                      fit: BoxFit.contain,
                                      errorBuilder: (
                                        _,
                                        __,
                                        ___,
                                      ) {
                                        return const Icon(
                                          Icons.castle_rounded,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.castle_rounded,
                                    ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tower Troop',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    selectedTower == null
                                        ? 'Tap to select a Tower Troop'
                                        : safeString(
                                            selectedTower!['name'],
                                          ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (selectedTower != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                                tooltip: 'Clear Tower Troop',
                                onPressed: () {
                                  setState(() {
                                    selectedTower = null;
                                  });
                                },
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // 8 CARD DECK GRID
                    // ------------------------------------------------

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        // Empty deck slot
                        if (index >= selected.length) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.add),
                            ),
                          );
                        }

                        final card = selected[index];
                        final image = cardImage(card);

                        return InkWell(
                          onTap: () => _removeCard(index),
                          borderRadius:
                              BorderRadius.circular(12),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Card image
                                if (image.isNotEmpty)
                                  Image.network(
                                    image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                      _,
                                      __,
                                      ___,
                                    ) {
                                      return const Icon(
                                        Icons.broken_image,
                                      );
                                    },
                                  )
                                else
                                  const Center(
                                    child: Icon(Icons.style),
                                  ),

                                // Card name
                                Align(
                                  alignment:
                                      Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black54,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      safeString(card['name']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign:
                                          TextAlign.center,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                // Remove indicator
                                const Align(
                                  alignment:
                                      Alignment.topRight,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // DECK BUTTONS
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                (selected.isEmpty &&
                                        selectedTower == null)
                                    ? null
                                    : _clearDeck,
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            label: const Text('Clear'),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: FilledButton.icon(
                            onPressed: selected.length == 8
                                ? _save
                                : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Save deck'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --------------------------------------------------------
          // ADD CARDS SECTION
          // --------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'Add cards',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Find a card',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // Loading
          if (loading)
            const LoadingView(
              label: 'Loading card list…',
            ),

          // Error
          if (error != null && !loading)
            ErrorView(
              error: error!,
              onRetry: load,
            ),

          // --------------------------------------------------------
          // CARD LIST
          // --------------------------------------------------------

          if (!loading && error == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleCards.take(100).map((card) {
                  final image = cardImage(card);

                  return SizedBox(
                    width: 100,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: selected.length >= 8
                            ? null
                            : () => _addCard(card),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 74,
                                child: image.isNotEmpty
                                    ? Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (
                                          _,
                                          __,
                                          ___,
                                        ) {
                                          return const Icon(
                                            Icons.broken_image,
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.style,
                                      ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                safeString(card['name']),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                '${cardElixir(card)} elixir',
                                style: const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // --------------------------------------------------------
          // SAVED DECKS
          // --------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              6,
            ),
            child: Text(
              'Saved decks',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          AnimatedBuilder(
            animation: AppSettings.instance,
            builder: (context, _) {
              final decks =
                  AppSettings.instance.savedDecks;

              if (decks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No saved decks yet. Create an 8-card deck and save it.',
                  ),
                );
              }

              return Column(
                children: decks.asMap().entries.map((entry) {
                  final deck =
                      _parseSavedDeck(entry.value);

                  // Skip corrupted deck data instead of crashing.
                  if (deck == null) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Card(
                        child: ListTile(
                          title: const Text(
                            'Invalid saved deck',
                          ),
                          subtitle: const Text(
                            'This saved entry could not be loaded.',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            onPressed: () {
                              AppSettings.instance
                                  .removeDeckAt(entry.key);
                            },
                          ),
                        ),
                      ),
                    );
                  }

                  final rawCards = deck['cards'];

                  final names = rawCards is List
                      ? rawCards.join(' • ')
                      : '';

                  final towerName =
                      deck['towerTroop']?.toString();

                  final subtitle = towerName != null &&
                          towerName.isNotEmpty
                      ? 'Tower: $towerName\n$names'
                      : names;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          safeString(
                            deck['name'] ?? 'Saved deck',
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          tooltip: 'Delete saved deck',
                          onPressed: () {
                            AppSettings.instance
                                .removeDeckAt(entry.key);
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}