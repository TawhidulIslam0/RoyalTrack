import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/section_title.dart';
import '../services/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.onOpenRankings,
    required this.onOpenSettings,
  });

  final ValueChanged<int> onNavigateTab;
  final VoidCallback onOpenRankings;
  final VoidCallback onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tagController = TextEditingController();
  bool _isClanSearch = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _submitQuickSearch() {
    final raw = _tagController.text.trim().toUpperCase();
    if (raw.isEmpty) {
      widget.onNavigateTab(_isClanSearch ? 2 : 1);
      return;
    }
    final formatted = raw.startsWith('#') ? raw : '#$raw';
    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $formatted — paste in lookup bar'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    widget.onNavigateTab(_isClanSearch ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // Top App Header with Rankings and Settings
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withAlpha(64),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFCD34D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROYALTRACK',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Clash Royale Companion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Rankings',
                onPressed: widget.onOpenRankings,
                icon: const Icon(Icons.leaderboard_rounded, size: 20),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hero Card with Interactive Quick Tag Search
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF172554), Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withAlpha(72),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5B82E).withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF5B82E).withAlpha(128),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFFCD34D),
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'OFFICIAL API • LIVE DATA',
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Stats. Cards.\nDecks. Clans.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Lookup Input Box
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isClanSearch = !_isClanSearch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5B82E),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isClanSearch
                                    ? Icons.shield_rounded
                                    : Icons.person_rounded,
                                size: 16,
                                color: const Color(0xFF1E1B18),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isClanSearch ? 'Clan' : 'Player',
                                style: const TextStyle(
                                  color: Color(0xFF1E1B18),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _submitQuickSearch(),
                          decoration: InputDecoration(
                            hintText: _isClanSearch
                                ? 'Enter #CLANTAG...'
                                : 'Enter #PLAYERTAG...',
                            hintStyle: TextStyle(
                              color: Colors.white.withAlpha(166),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitQuickSearch,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const SectionTitle('Quick access'),
          const SizedBox(height: 10),

          // Interactive 2x2 Feature Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.38,
            children: [
              _QuickAccessTile(
                icon: Icons.person_search_rounded,
                title: 'Player lookup',
                desc: 'Profile & battle log',
                color: const Color(0xFF3B82F6),
                onTap: () => widget.onNavigateTab(1),
              ),
              _QuickAccessTile(
                icon: Icons.shield_rounded,
                title: 'Clan lookup',
                desc: 'Clan info & members',
                color: const Color(0xFF8B5CF6),
                onTap: () => widget.onNavigateTab(2),
              ),
              _QuickAccessTile(
                icon: Icons.style_rounded,
                title: 'Card database',
                desc: 'Browse all cards',
                color: const Color(0xFF10B981),
                onTap: () => widget.onNavigateTab(3),
              ),
              _QuickAccessTile(
                icon: Icons.view_carousel_rounded,
                title: 'Deck builder',
                desc: 'Build & save decks',
                color: const Color(0xFFF59E0B),
                onTap: () => widget.onNavigateTab(4),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const SectionTitle('Saved favorites'),
          const SizedBox(height: 8),

          // Interactive Saved Favorites Card
          AnimatedBuilder(
            animation: AppSettings.instance,
            builder: (context, _) {
              final favs = AppSettings.instance.favorites;
              if (favs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5B82E)
                                .withAlpha(isDark ? 42 : 36),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_outline_rounded,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No saved tags yet',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bookmark a player or clan from its profile for 1-tap access.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: favs.map((tag) {
                      return InputChip(
                        avatar: const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        label: Text(
                          '#$tag',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '#$tag'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied #$tag to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          widget.onNavigateTab(1);
                        },
                        onDeleted: () =>
                            AppSettings.instance.toggleFavorite(tag),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // Compact Data Transparency Notice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live player, clan, battle, and card data comes directly from the official Supercell API via your backend proxy—no fabricated win rates.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 52 : 32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}