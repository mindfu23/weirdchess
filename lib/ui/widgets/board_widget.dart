import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/move.dart';
import '../../services/game_service.dart';
import 'piece_widget.dart';

/// Widget that displays the chess board
class BoardWidget extends ConsumerWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(selectedVariantProvider);
    final boardSize = variant.boardSize;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[800]!, width: 4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
          ),
          itemCount: boardSize * boardSize,
          itemBuilder: (context, index) {
            final row = index ~/ boardSize;
            final col = index % boardSize;
            final position = Position(row.toInt(), col.toInt());

            return _SquareWidget(
              position: position,
              lightColor: variant.lightSquareColor,
              darkColor: variant.darkSquareColor,
            );
          },
        ),
      ),
    );
  }
}

class _SquareWidget extends ConsumerWidget {
  final Position position;
  final Color lightColor;
  final Color darkColor;

  const _SquareWidget({
    required this.position,
    required this.lightColor,
    required this.darkColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.watch(gameNotifierProvider.notifier);
    final piece = gameState.board.getPiece(position);

    final isLight = (position.row + position.col) % 2 == 0;
    final squareColor = isLight ? lightColor : darkColor;

    // Check if this square is selected or a valid move
    final isSelected = notifier.selectedPosition == position;
    final isValidMove = notifier.selectedPieceMoves.any((m) => m.to == position);
    final moveForSquare = isValidMove
        ? notifier.selectedPieceMoves.firstWhere((m) => m.to == position)
        : null;

    // Highlight colors
    Color? highlightColor;
    if (isSelected) {
      highlightColor = Colors.yellow.withAlpha(128);
    } else if (isValidMove) {
      highlightColor = moveForSquare?.isCapture == true
          ? Colors.red.withAlpha(102)
          : Colors.green.withAlpha(102);
    }

    // Check if this was the last move
    final lastMove = gameState.moveHistory.isNotEmpty
        ? gameState.moveHistory.last.move
        : null;
    final isLastMoveSquare =
        lastMove != null && (lastMove.from == position || lastMove.to == position);

    return GestureDetector(
      onTap: () => notifier.onSquareTap(position),
      child: Container(
        decoration: BoxDecoration(
          color: squareColor,
          border: isLastMoveSquare
              ? Border.all(color: Colors.blue.withAlpha(128), width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // Highlight overlay
            if (highlightColor != null)
              Positioned.fill(
                child: Container(color: highlightColor),
              ),
            // Move indicator dot (for empty squares)
            if (isValidMove && piece == null)
              Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withAlpha(153),
                  ),
                ),
              ),
            // Piece
            if (piece != null)
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pieceSize = constraints.maxWidth * 0.8;
                    return PieceWidget(piece: piece, size: pieceSize);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
