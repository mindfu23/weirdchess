import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_service.dart';
import '../../variants/variant_base.dart';

/// Home screen with variant selection — 2-column grid with section headers
/// for 8×8 and 10×10 variants.  Content is centre-clamped to 460 px so
/// cards don't balloon on wide/desktop screens.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = ref.watch(variantsProvider);
    final variants8x8 = variants.where((v) => v.boardSize == 8).toList();
    final variants10x10 = variants.where((v) => v.boardSize == 10).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/mascot.svg',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 10),
            Text(
              'WeirdChess',
              style: const TextStyle(
                fontFamily: 'Righteous',
                color: Color(0xFFF5E6D3),
                fontSize: 24,
              ),
            ),
          ],
        ),
        centerTitle: true,
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
            // Clamp to phone-like width so cards don't stretch on wide screens.
            constraints: const BoxConstraints(maxWidth: 460),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose a Variant',
                          style: TextStyle(
                            fontFamily: 'Righteous',
                            color: Color(0xFFF5E6D3),
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${variants.length} variants — classic rules and wild twists',
                          style: const TextStyle(
                            color: Color(0xFF9B8E85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 8×8 section ───────────────────────────────────────────
                _SectionHeader(
                  label: '8×8 Variants',
                  count: variants8x8.length,
                ),
                _VariantGrid(variants: variants8x8),

                // ── 10×10 section ─────────────────────────────────────────
                _SectionHeader(
                  label: '10×10 Variants',
                  count: variants10x10.length,
                ),
                _VariantGrid(variants: variants10x10),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFF9B8A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3542),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF9B8E85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Divider(color: Color(0xFF2D3542), thickness: 1),
            ),
          ],
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Fixed height per card — compact without the board preview.
          mainAxisExtent: 112,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final variant = variants[index];
            return _VariantCard(
              variant: variant,
              onTap: () {
                ref
                    .read(selectedVariantProvider.notifier)
                    .select(variant);
                ref
                    .read(gameNotifierProvider.notifier)
                    .newGame(variant);
                context.go('/game');
              },
            );
          },
          childCount: variants.length,
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ChessVariant variant;
  final VoidCallback onTap;

  const _VariantCard({required this.variant, required this.onTap});

  /// Returns a Material icon that best represents each variant.
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
                      mainAxisAlignment: MainAxisAlignment.start,
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
