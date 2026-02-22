import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_service.dart';
import '../../variants/variant_base.dart';

/// Home screen with variant selection.
/// Two tabs — 8×8 (default) and 10×10 — replace the old section-header scroll.
/// Content is centre-clamped to 460 px so cards don't balloon on wide screens.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = ref.watch(variantsProvider);
    final variants8x8 = variants.where((v) => v.boardSize == 8).toList();
    final variants10x10 = variants.where((v) => v.boardSize == 10).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _VariantGrid(variants: variants8x8),
                        _VariantGrid(variants: variants10x10),
                      ],
                    ),
                  ),
                ],
              ),
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
          onTap: () {
            ref.read(selectedVariantProvider.notifier).select(variant);
            ref.read(gameNotifierProvider.notifier).newGame(variant);
            context.go('/game');
          },
        );
      },
    );
  }
}

class _VariantCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final boardSize = variant.boardSize;
    final sizeLabel = '$boardSize×$boardSize';

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
              // Size badge — top right
              Align(
                alignment: Alignment.centerRight,
                child: Container(
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
