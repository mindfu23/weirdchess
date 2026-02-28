import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

// ── Brand palette ────────────────────────────────────────────────────────────
const _kSurface = Color(0xFF2D3542);
const _kTextPrimary = Color(0xFFF5E6D3);
const _kTextMuted = Color(0xFF9B8E85);

/// Panel that displays information about the currently selected piece.
/// Positioned via parent widget for easy relocation during UI upgrades.
class PieceInfoPanel extends ConsumerWidget {
  const PieceInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.watch(gameNotifierProvider.notifier);
    final variant = ref.watch(selectedVariantProvider);

    final selectedPos = notifier.selectedPosition;
    if (selectedPos == null) return const SizedBox.shrink();

    final piece = gameState.board.getPiece(selectedPos);
    if (piece == null) return const SizedBox.shrink();

    final pieceInfo = variant.pieceInfo[piece.symbol];
    if (pieceInfo == null) return const SizedBox.shrink();

    return PieceInfoInline(
      piece: piece,
      name: pieceInfo.name,
      symbol: pieceInfo.symbol,
      value: pieceInfo.value,
      movementDescription: pieceInfo.movementDescription,
    );
  }
}

/// The actual card displaying piece information.
/// Separated for reusability (e.g., in dialogs, tooltips).
class PieceInfoCard extends StatelessWidget {
  final Piece piece;
  final String name;
  final String symbol;
  final int value;
  final String movementDescription;

  const PieceInfoCard({
    super.key,
    required this.piece,
    required this.name,
    required this.symbol,
    required this.value,
    required this.movementDescription,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    final colorName = isWhite ? 'White' : 'Black';

    return Card(
      elevation: 4,
      color: _kSurface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with piece symbol and name
            Row(
              children: [
                _buildPieceIcon(isWhite),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        '$colorName · Value: $value',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFF4A5568)),
            // Movement description
            const Text(
              'Movement',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              movementDescription,
              style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceIcon(bool isWhite) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // White piece: white fill, dark border; Black piece: dark fill, light border.
        color: isWhite ? Colors.white : const Color(0xFF1A1A1A),
        border: Border.all(
          color: isWhite ? const Color(0xFF4A5568) : _kTextMuted,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: isWhite ? const Color(0xFF1A1A1A) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Inline version of piece info for embedding in the score panel.
/// No Card wrapper or maxWidth — inherits container width from parent.
class PieceInfoInline extends StatelessWidget {
  final Piece piece;
  final String name;
  final String symbol;
  final int value;
  final String movementDescription;

  const PieceInfoInline({
    super.key,
    required this.piece,
    required this.name,
    required this.symbol,
    required this.value,
    required this.movementDescription,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    final colorName = isWhite ? 'White' : 'Black';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: Color(0xFF4A5568)),
        // Header with piece symbol and name
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWhite ? Colors.white : const Color(0xFF1A1A1A),
                border: Border.all(
                  color: isWhite ? const Color(0xFF4A5568) : _kTextMuted,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF1A1A1A) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  '$colorName · Value: $value',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Movement',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTextMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          movementDescription,
          style: const TextStyle(fontSize: 12, color: _kTextPrimary),
        ),
      ],
    );
  }
}
