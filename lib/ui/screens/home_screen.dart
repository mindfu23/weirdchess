import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import '../../services/scoreboard_service.dart';
import '../../variants/variant_base.dart';

/// Home screen with variant selection.
/// Two tabs — 8×8 (default) and 10×10 — replace the old section-header scroll.
/// Content is centre-clamped to 460 px so cards don't balloon on wide screens.
class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variants = ref.watch(variantsProvider);
    final variants8x8 = variants.where((v) => v.boardSize == 8).toList();
    final variants10x10 = variants.where((v) => v.boardSize == 10).toList();

    return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          // Left-aligned logo + title
          centerTitle: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/mascot.svg',
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 10),
              const Text(
                'WeirdChess',
                style: TextStyle(
                  fontFamily: 'Righteous',
                  color: Color(0xFFF5E6D3),
                  fontSize: 24,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFFFF9B8A)),
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(
                      'Choose your weird chess battle',
                      style: TextStyle(
                        fontFamily: 'Righteous',
                        color: Color(0xFFF5E6D3),
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'classic rules and wild twists',
                      style: TextStyle(
                        color: Color(0xFF9B8E85),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Tab bar — left-aligned, with size + layout description
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFFFF9B8A),
                    unselectedLabelColor: const Color(0xFF9B8E85),
                    indicatorColor: const Color(0xFFFF9B8A),
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: const Color(0xFF2D3542),
                    tabs: [
                      Tab(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              '8×8 Variants',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Standard Layout',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              '10×10 Variants',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Larger Layout',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Scoreboard',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Win / Loss Stats',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _VariantGrid(variants: variants8x8),
                        _VariantGrid(variants: variants10x10),
                        _ScoreboardTab(variants: variants),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _VariantGrid extends ConsumerWidget {
  final List<ChessVariant> variants;

  const _VariantGrid({required this.variants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 112,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        return _VariantCard(
          variant: variant,
          onTap: () async {
            ref.read(selectedVariantProvider.notifier).select(variant);
            // Reset human colour to white before starting any new game so
            // we don't accidentally trigger AI before the Horde dialog shows.
            ref.read(humanColorProvider.notifier).set(PieceColor.white);
            await ref.read(gameNotifierProvider.notifier).restoreGame(variant);
            if (context.mounted) context.go('/game');
          },
        );
      },
    );
  }
}

class _VariantCard extends ConsumerWidget {
  final ChessVariant variant;
  final VoidCallback onTap;

  const _VariantCard({required this.variant, required this.onTap});

  IconData _iconFor(String id) {
    switch (id) {
      case 'standard_chess':
        return Icons.grid_on;
      case 'atomic':
        return Icons.local_fire_department;
      case 'chess960':
        return Icons.shuffle;
      case 'three_check':
        return Icons.filter_3;
      case 'king_of_the_hill':
        return Icons.filter_center_focus;
      case 'horde':
        return Icons.groups;
      case 'fog_of_war':
        return Icons.cloud;
      case 'grand_chess':
        return Icons.castle;
      case 'omega_chess':
        return Icons.all_inclusive;
      case 'decimal_chess':
        return Icons.grid_4x4;
      case 'hyderabad_chess':
        return Icons.diamond;
      case 'jetan':
        return Icons.auto_awesome;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardSize = variant.boardSize;
    final sizeLabel = '$boardSize×$boardSize';
    final hasSaved = ref.watch(hasSavedGameProvider(variant.id));

    return Material(
      color: const Color(0xFF2D3542),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFFFF9B8A).withAlpha(40),
        highlightColor: const Color(0xFFFF9B8A).withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges — top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // "In Progress" badge
                  if (hasSaved.asData?.value == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF82).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                          color: Color(0xFF4CAF82),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Size badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sizeLabel,
                      style: const TextStyle(
                        color: Color(0xFF9B8E85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Icon + name/description on the same row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconFor(variant.id),
                      color: const Color(0xFFFF9B8A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF5E6D3),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          variant.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9B8E85),
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Mini board colour preview — kept for reference, hidden from UI.
              Offstage(
                offstage: true,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                      ),
                      itemCount: 16,
                      itemBuilder: (_, i) {
                        final r = i ~/ 4;
                        final c = i % 4;
                        return Container(
                          color: (r + c) % 2 == 0
                              ? variant.lightSquareColor
                              : variant.darkSquareColor,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scoreboard Tab ──────────────────────────────────────────────────────────

class _ScoreboardTab extends ConsumerWidget {
  final List<ChessVariant> variants;

  const _ScoreboardTab({required this.variants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreboard = ref.watch(scoreboardProvider);

    // Only show variants that have at least one game played.
    final played = variants
        .where((v) => (scoreboard[v.id]?.gamesPlayed ?? 0) > 0)
        .toList();

    if (played.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No games completed yet.\nYour results will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9B8E85), fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: played.length,
      itemBuilder: (context, index) {
        final variant = played[index];
        final stats = scoreboard[variant.id]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3542),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Variant name + game count
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.name,
                      style: const TextStyle(
                        color: Color(0xFFF5E6D3),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.gamesPlayed} game${stats.gamesPlayed == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF9B8E85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // W / L / D columns
              _StatBadge(label: 'W', count: stats.wins, color: const Color(0xFF4CAF82)),
              const SizedBox(width: 12),
              _StatBadge(label: 'L', count: stats.losses, color: const Color(0xFFFF6B6B)),
              const SizedBox(width: 12),
              _StatBadge(label: 'D', count: stats.draws, color: const Color(0xFFFF9B8A)),
            ],
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
