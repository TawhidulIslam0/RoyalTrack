
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

  final List<Map<String, dynamic>?> slots =
      List<Map<String, dynamic>?>.filled(8, null);

  int? activeSlotIndex;
  Map<String, dynamic>? selectedTower;

  bool loading = false;
  Object? error;
  String search = '';

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
    'electro wizard',
    'ice wizard',
  };

  static const List<Map<String, dynamic>> _fallbackTowerTroops = [
    {'name': 'Tower Princess', 'rarity': 'Common', 'isTowerTroop': true},
    {'name': 'Cannoneer', 'rarity': 'Epic', 'isTowerTroop': true},
    {'name': 'Dagger Duchess', 'rarity': 'Legendary', 'isTowerTroop': true},
    {'name': 'Royal Chef', 'rarity': 'Legendary', 'isTowerTroop': true},
  ];

  String _normalizeName(dynamic raw) {
    return (raw ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _sameCard(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a['id'] != null && b['id'] != null) {
      return a['id'] == b['id'];
    }

    return _normalizeName(a['name']) == _normalizeName(b['name']);
  }

  bool _isEvo(Map<String, dynamic> card) {
    return _evolutionNames.contains(_normalizeName(card['name']));
  }

  bool _isHeroOrChampion(Map<String, dynamic> card) {
    final key = _normalizeName(card['name']);
    final cardRarity = rarity(card).trim().toLowerCase();

    return _heroNames.contains(key) || cardRarity == 'champion';
  }

  bool _canFitInSlot(Map<String, dynamic> card, int slotIndex) {
    if (slotIndex == 0) return _isEvo(card);
    if (slotIndex == 1) return _isHeroOrChampion(card);
    if (slotIndex == 2) {
      return _isEvo(card) || _isHeroOrChampion(card);
    }

    return true;
  }

  String _slotRoleLabel(int index) {
    switch (index) {
      case 0:
        return 'EVO';
      case 1:
        return 'HERO';
      case 2:
        return 'WILD';
      default:
        return '';
    }
  }

  String _spriteForSlot(Map<String, dynamic> card, int slotIndex) {
    final icons = card['iconUrls'];
    final regular = cardImage(card);

    if (icons is Map) {
      final evoUrl = (icons['evolutionMedium'] ?? icons['evoMedium'] ?? '')
          .toString()
          .trim();

      final heroUrl = (icons['heroMedium'] ?? '')
          .toString()
          .trim();

      if (slotIndex == 0 && evoUrl.isNotEmpty) {
        return evoUrl;
      }

      if (slotIndex == 1 && heroUrl.isNotEmpty) {
        return heroUrl;
      }

      if (slotIndex == 2) {
        if (_isEvo(card) && evoUrl.isNotEmpty) {
          return evoUrl;
        }

        if (_isHeroOrChampion(card) && heroUrl.isNotEmpty) {
          return heroUrl;
        }
      }
    }

    return regular;
  }

  int get filledCount => slots.where((card) => card != null).length;

  double get average {
    final filled = slots.whereType<Map<String, dynamic>>().toList();

    if (filled.isEmpty) return 0;

    final total = filled.fold<double>(
      0,
      (sum, card) => sum + cardElixir(card).toDouble(),
    );

    return total / filled.length;
  }

  void _assignCard(Map<String, dynamic> card) {
    if (activeSlotIndex != null && slots[activeSlotIndex!] == null) {
      final target = activeSlotIndex!;

      if (_canFitInSlot(card, target)) {
        setState(() {
          slots[target] = card;
          activeSlotIndex = null;
        });
        return;
      }
    }

    int? chosenIndex;

    if (_isEvo(card) && slots[0] == null) {
      chosenIndex = 0;
    } else if (_isHeroOrChampion(card) && slots[1] == null) {
      chosenIndex = 1;
    } else if ((_isEvo(card) || _isHeroOrChampion(card)) &&
        slots[2] == null) {
      chosenIndex = 2;
    } else {
      for (int i = 3; i < 8; i++) {
        if (slots[i] == null) {
          chosenIndex = i;
          break;
        }
      }
    }

    if (chosenIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available slot for this card.'),
        ),
      );
      return;
    }

    setState(() {
      slots[chosenIndex!] = card;
      activeSlotIndex = null;
    });
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

      final rawItems = List<dynamic>.from(data['items'] ?? []);
      final rawTowers = List<dynamic>.from(data['supportItems'] ?? []);

      final parsedCards = rawItems
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final parsedTowers = rawTowers.isNotEmpty
          ? rawTowers
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : _fallbackTowerTroops
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

      setState(() {
        cards = parsedCards;
        towerTroops = parsedTowers;
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

  Future<void> _pickTowerTroop() async {
    final options = towerTroops.isNotEmpty
        ? towerTroops
        : _fallbackTowerTroops;

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
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
                subtitle: Text('Select your Tower Troop'),
              ),
              ...options.map((tower) {
                final name = safeString(tower['name']);

                final isCurrent = selectedTower != null &&
                    _normalizeName(selectedTower!['name']) ==
                        _normalizeName(name);

                final img = cardImage(tower);

                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: img.isNotEmpty
                        ? Image.network(
                            img,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.castle_rounded),
                          )
                        : const Icon(Icons.castle_rounded),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(rarity(tower)),
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, tower),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => selectedTower = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = search.trim().toLowerCase();

    final visible = cards.where((card) {
      final matchesSearch = q.isEmpty ||
          (card['name'] ?? '').toString().toLowerCase().contains(q);

      final alreadyInDeck = slots
          .whereType<Map<String, dynamic>>()
          .any((existing) => _sameCard(existing, card));

      final matchesTargetSlot = activeSlotIndex == null ||
          _canFitInSlot(card, activeSlotIndex!);

      return matchesSearch && !alreadyInDeck && matchesTargetSlot;
    }).toList();

    final towerImg = selectedTower != null
        ? cardImage(selectedTower!)
        : '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppHeader(subtitle: 'Build decks just like in-game'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Battle Deck',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$filledCount/8 cards',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeSlotIndex == null
                          ? 'Evo • Hero/Champion • Wild • 5 normal slots'
                          : 'Filtering for Slot ${activeSlotIndex! + 1} (${_slotRoleLabel(activeSlotIndex!).isEmpty ? 'NORMAL' : _slotRoleLabel(activeSlotIndex!)})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) =>
                          _buildDeckSlot(index, theme),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA).withAlpha(28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF9333EA).withAlpha(90),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 18,
                                color: Color(0xFF9333EA),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                average.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF9333EA),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTowerTroop,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withAlpha(90),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: towerImg.isNotEmpty
                                        ? Image.network(
                                            towerImg,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.castle_rounded,
                                              size: 20,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.castle_rounded,
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedTower == null
                                          ? 'Tower Troop'
                                          : safeString(
                                              selectedTower!['name'],
                                            ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selectedTower != null)
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => selectedTower = null,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: filledCount == 0 &&
                                    selectedTower == null &&
                                    activeSlotIndex == null
                                ? null
                                : () => setState(() {
                                      for (int i = 0; i < 8; i++) {
                                        slots[i] = null;
                                      }
                                      selectedTower = null;
                                      activeSlotIndex = null;
                                    }),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: filledCount == 8 ? _save : null,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeSlotIndex == null
                      ? 'Card collection'
                      : 'Eligible for Slot ${activeSlotIndex! + 1}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activeSlotIndex != null)
                  TextButton(
                    onPressed: () => setState(() => activeSlotIndex = null),
                    child: const Text('Show all'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Find a card',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => search = value),
            ),
          ),
          if (loading) const LoadingView(label: 'Loading card list…'),
          if (error != null && !loading)
            ErrorView(error: error!, onRetry: load),
          if (!loading && error == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visible.take(120).map((card) {
                  final img = cardImage(card);
                  final hasEvo = _isEvo(card);
                  final hasHero = _isHeroOrChampion(card);

                  return SizedBox(
                    width: 100,
                    child: Card(
                      child: InkWell(
                        onTap: filledCount >= 8
                            ? null
                            : () => _assignCard(card),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 74,
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : const Icon(Icons.style),
                              ),
                              Text(
                                safeString(card['name']),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cardElixir(card)} elixir',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (hasEvo || hasHero) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (hasEvo)
                                      _tinyTag(
                                        'EVO',
                                        const Color(0xFF9333EA),
                                      ),
                                    if (hasEvo && hasHero)
                                      const SizedBox(width: 4),
                                    if (hasHero)
                                      _tinyTag(
                                        'HERO',
                                        const Color(0xFFD97706),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Text(
              'Saved decks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: AppSettings.instance,
            builder: (context, _) {
              final decks = AppSettings.instance.savedDecks;

              if (decks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No saved decks yet. Fill all 8 slots and save your deck.',
                  ),
                );
              }

              return Column(
                children: decks.asMap().entries.map((entry) {
                  final data = jsonDecode(entry.value) as Map;
                  final names = (data['cards'] as List).join(' • ');

                  final details = <String>[
                    if (data['towerTroop'] != null)
                      'Tower: ${data['towerTroop']}',
                    if (data['evoSlot'] != null)
                      'Evo: ${data['evoSlot']}',
                    if (data['heroSlot'] != null)
                      'Hero: ${data['heroSlot']}',
                    if (data['wildSlot'] != null)
                      'Wild: ${data['wildSlot']}',
                  ].join(' • ');

                  final subtitleText =
                      details.isNotEmpty ? '$details\n$names' : names;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          safeString(data['name'] ?? 'Saved deck'),
                        ),
                        subtitle: Text(
                          subtitleText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              AppSettings.instance.removeDeckAt(entry.key),
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

  Widget _buildDeckSlot(int index, ThemeData theme) {
    final card = slots[index];
    final isTargeted = activeSlotIndex == index;

    final Color borderColor = switch (index) {
      0 => const Color(0xFF9333EA),
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFFA855F7),
      _ => isTargeted
          ? theme.colorScheme.primary
          : theme.colorScheme.outlineVariant,
    };

    final double borderWidth = index < 3 || isTargeted ? 2.2 : 1.2;

    if (card == null) {
      final role = _slotRoleLabel(index);

      return InkWell(
        onTap: () => setState(() {
          activeSlotIndex = activeSlotIndex == index ? null : index;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isTargeted
                ? borderColor.withAlpha(36)
                : index < 3
                    ? borderColor.withAlpha(14)
                    : Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                index == 0
                    ? Icons.auto_awesome_rounded
                    : index == 1
                        ? Icons.workspace_premium_rounded
                        : index == 2
                            ? Icons.stars_rounded
                            : Icons.add,
                size: 20,
                color: index < 3 ? borderColor : null,
              ),
              if (role.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: borderColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final image = _spriteForSlot(card, index);
    final cardName = safeString(card['name']);

    final badgeText = switch (index) {
      0 => 'EVO',
      1 => 'HERO',
      2 => _isEvo(card) ? 'EVO' : 'HERO',
      _ => '',
    };

    return InkWell(
      onTap: () => setState(() {
        slots[index] = null;
        activeSlotIndex = index;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.style),
            ),
            if (badgeText.isNotEmpty)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeText == 'EVO'
                        ? const Color(0xFF9333EA)
                        : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 1),
                color: Colors.black54,
                child: Text(
                  cardName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.close,
                color: Colors.redAccent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tinyTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (filledCount != 8) return;

    final orderedCards = slots.whereType<Map<String, dynamic>>().toList();
    final name = 'Deck ${DateTime.now().month}/${DateTime.now().day}';

    final json = jsonEncode({
      'name': name,
      'towerTroop': selectedTower?['name'],
      'evoSlot': slots[0]?['name'],
      'heroSlot': slots[1]?['name'],
      'wildSlot': slots[2]?['name'],
      'cards': orderedCards.map((card) => card['name']).toList(),
      'ids': orderedCards.map((card) => card['id']).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    });

    await AppSettings.instance.saveDeck(json);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck saved locally')),
      );
    }
  }
}
