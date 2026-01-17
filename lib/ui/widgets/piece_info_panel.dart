import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

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
    if (selectedPos == null) {
      return const SizedBox.shrink();
    }

    final piece = gameState.board.getPiece(selectedPos);
    if (piece == null) {
      return const SizedBox.shrink();
    }

    final pieceInfo = variant.pieceInfo[piece.symbol];
    if (pieceInfo == null) {
      return const SizedBox.shrink();
    }

    return PieceInfoCard(
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
                        ),
                      ),
                      Text(
                        '$colorName · Value: $value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Movement description
            Text(
              'Movement',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              movementDescription,
              style: const TextStyle(fontSize: 13),
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
        color: isWhite ? Colors.white : Colors.grey[800],
        border: Border.all(
          color: isWhite ? Colors.grey[800]! : Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: isWhite ? Colors.grey[800] : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
