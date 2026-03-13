import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import '../../services/scoreboard_service.dart';
import '../../variants/variant_base.dart';

/// Home screen with variant selection.
///
/// Narrow (<800 px): tabbed layout (8×8 / 10×10 / Scoreboard), clamped to 460 px.
/// Wide (≥800 px): single scrollable page with section dividers, responsive
///   grid (3 cols at 800–1099, 4 cols at ≥1100), and larger fonts.
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            if (isWide) {
              return _WideLayout(
                variants8x8: variants8x8,
                variants10x10: variants10x10,
                allVariants: variants,
                width: constraints.maxWidth,
              );
            }
            return _NarrowLayout(
              tabController: _tabController,
              variants8x8: variants8x8,
              variants10x10: variants10x10,
              allVariants: variants,
            );
          },
        ),
      ),
    );
  }
}

// ── Narrow layout (current tabbed design, <800 px) ──────────────────────────

class _NarrowLayout extends StatelessWidget {
  final TabController tabController;
  final List<ChessVariant> variants8x8;
  final List<ChessVariant> variants10x10;
  final List<ChessVariant> allVariants;

  const _NarrowLayout({
    required this.tabController,
    required this.variants8x8,
    required this.variants10x10,
    required this.allVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                style: TextStyle(color: Color(0xFF9B8E85), fontSize: 13),
              ),
            ),
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFFF9B8A),
              unselectedLabelColor: const Color(0xFF9B8E85),
              indicatorColor: const Color(0xFFFF9B8A),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: const Color(0xFF2D3542),
              tabs: const [
                Tab(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('8×8 Variants',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Standard Layout',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('10×10 Variants',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Larger Layout',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Scoreboard',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Win / Loss Stats',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _VariantGrid(variants: variants8x8),
                  _VariantGrid(variants: variants10x10),
                  _ScoreboardList(variants: allVariants),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wide layout (unified grid, ≥800 px) ─────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  final List<ChessVariant> variants8x8;
  final List<ChessVariant> variants10x10;
  final List<ChessVariant> allVariants;
  final double width;

  const _WideLayout({
    required this.variants8x8,
    required this.variants10x10,
    required this.allVariants,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Responsive grid columns: 3 at 800–1099, 4 at ≥1100.
    final crossAxisCount = width >= 1100 ? 4 : 3;

    // Font scale: 1.0 at 800 px, up to 1.25 at 1400 px+.
    final fontScale = (1.0 + ((width - 800) / 2400).clamp(0.0, 0.25));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Choose your weird chess battle',
                style: TextStyle(
                  fontFamily: 'Righteous',
                  color: const Color(0xFFF5E6D3),
                  fontSize: 24 * fontScale,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'classic rules and wild twists',
                style: TextStyle(
                  color: const Color(0xFF9B8E85),
                  fontSize: 14 * fontScale,
                ),
              ),

              // ── 8×8 section ──
              _SectionDivider(
                  label: '8×8 Variants — Standard Layout',
                  fontScale: fontScale),
              _ResponsiveVariantGrid(
                variants: variants8x8,
                crossAxisCount: crossAxisCount,
                fontScale: fontScale,
              ),

              // ── 10×10 section ──
              _SectionDivider(
                  label: '10×10 Variants — Larger Layout',
                  fontScale: fontScale),
              _ResponsiveVariantGrid(
                variants: variants10x10,
                crossAxisCount: crossAxisCount,
                fontScale: fontScale,
              ),

              // ── Scoreboard section ──
              _SectionDivider(
                  label: 'Scoreboard — Win / Loss Stats',
                  fontScale: fontScale),
              _ScoreboardWide(
                  variants: allVariants, fontScale: fontScale),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal divider with a label, matching the Option C mockup.
class _SectionDivider extends StatelessWidget {
  final String label;
  final double fontScale;

  const _SectionDivider({required this.label, this.fontScale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFFF9B8A),
              fontSize: 13 * fontScale,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: Color(0xFF2D3542), thickness: 1),
          ),
        ],
      ),
    );
  }
}

/// Non-scrollable grid of variant cards (used in the wide layout).
class _ResponsiveVariantGrid extends ConsumerWidget {
  final List<ChessVariant> variants;
  final int crossAxisCount;
  final double fontScale;

  const _ResponsiveVariantGrid({
    required this.variants,
    required this.crossAxisCount,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 112 * fontScale,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        return _VariantCard(
          variant: variant,
          fontScale: fontScale,
          onTap: () => _launchVariant(context, ref, variant),
        );
      },
    );
  }
}

/// Scoreboard rendered inline (not in a ListView) for the wide layout.
class _ScoreboardWide extends ConsumerWidget {
  final List<ChessVariant> variants;
  final double fontScale;

  const _ScoreboardWide({
    required this.variants,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreboard = ref.watch(scoreboardProvider);
    final played = variants
        .where((v) => (scoreboard[v.id]?.gamesPlayed ?? 0) > 0)
        .toList();

    if (played.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No games completed yet. Your results will appear here.',
          style: TextStyle(
            color: const Color(0xFF9B8E85),
            fontSize: 14 * fontScale,
          ),
        ),
      );
    }

    return Column(
      children: played.map((variant) {
        final stats = scoreboard[variant.id]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12 * fontScale),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3542),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.name,
                      style: TextStyle(
                        color: const Color(0xFFF5E6D3),
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.gamesPlayed} game${stats.gamesPlayed == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: const Color(0xFF9B8E85),
                        fontSize: 11 * fontScale,
                      ),
                    ),
                  ],
                ),
              ),
              _StatBadge(
                  label: 'W',
                  count: stats.wins,
                  color: const Color(0xFF4CAF82),
                  fontScale: fontScale),
              SizedBox(width: 12 * fontScale),
              _StatBadge(
                  label: 'L',
                  count: stats.losses,
                  color: const Color(0xFFFF6B6B),
                  fontScale: fontScale),
              SizedBox(width: 12 * fontScale),
              _StatBadge(
                  label: 'D',
                  count: stats.draws,
                  color: const Color(0xFFFF9B8A),
                  fontScale: fontScale),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared widgets (used in both layouts) ────────────────────────────────────

/// Launches a variant: selects it, restores saved game, navigates to /game.
Future<void> _launchVariant(
    BuildContext context, WidgetRef ref, ChessVariant variant) async {
  ref.read(selectedVariantProvider.notifier).select(variant);
  ref.read(humanColorProvider.notifier).set(PieceColor.white);
  final wasRestored =
      await ref.read(gameNotifierProvider.notifier).restoreGame(variant);
  ref.read(gameRestoredProvider.notifier).set(wasRestored);
  if (context.mounted) context.go('/game');
}

/// Narrow-mode scrollable grid (unchanged from before).
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
          onTap: () => _launchVariant(context, ref, variant),
        );
      },
    );
  }
}

/// Narrow-mode scoreboard list (unchanged from before).
class _ScoreboardList extends ConsumerWidget {
  final List<ChessVariant> variants;

  const _ScoreboardList({required this.variants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreboard = ref.watch(scoreboardProvider);
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
              _StatBadge(
                  label: 'W',
                  count: stats.wins,
                  color: const Color(0xFF4CAF82)),
              const SizedBox(width: 12),
              _StatBadge(
                  label: 'L',
                  count: stats.losses,
                  color: const Color(0xFFFF6B6B)),
              const SizedBox(width: 12),
              _StatBadge(
                  label: 'D',
                  count: stats.draws,
                  color: const Color(0xFFFF9B8A)),
            ],
          ),
        );
      },
    );
  }
}

class _VariantCard extends ConsumerWidget {
  final ChessVariant variant;
  final VoidCallback onTap;
  final double fontScale;

  const _VariantCard({
    required this.variant,
    required this.onTap,
    this.fontScale = 1.0,
  });

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
          padding: EdgeInsets.all(12 * fontScale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges — top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasSaved.asData?.value == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF82).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'In Progress',
                        style: TextStyle(
                          color: const Color(0xFF4CAF82),
                          fontSize: 9 * fontScale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sizeLabel,
                      style: TextStyle(
                        color: const Color(0xFF9B8E85),
                        fontSize: 10 * fontScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8 * fontScale),

              // Icon + name/description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32 * fontScale,
                    height: 32 * fontScale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconFor(variant.id),
                      color: const Color(0xFFFF9B8A),
                      size: 18 * fontScale,
                    ),
                  ),
                  SizedBox(width: 8 * fontScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF5E6D3),
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3 * fontScale),
                        Text(
                          variant.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF9B8E85),
                            fontSize: 10 * fontScale,
                            height: 1.4,
                          ),
                        ),
                      ],
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

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final double fontScale;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
