import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/move.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import '../../variants/king_of_the_hill.dart';
import 'atomic_explosion_overlay.dart';
import 'move_animation_overlay.dart';
import 'piece_widget.dart';

/// Widget that displays the chess board.
class BoardWidget extends ConsumerWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(selectedVariantProvider);
    final boardSize = variant.boardSize;
    final humanColor = ref.watch(humanColorProvider);

    // Flip the board when human plays Black.
    final isFlipped = humanColor == PieceColor.black;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[800]!, width: 4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: boardSize,
              ),
              itemCount: boardSize * boardSize,
              itemBuilder: (context, index) {
                final gridRow = isFlipped
                    ? boardSize - 1 - (index ~/ boardSize)
                    : index ~/ boardSize;
                final gridCol = isFlipped
                    ? boardSize - 1 - (index % boardSize)
                    : index % boardSize;
                final position = Position(gridRow, gridCol);

                return _SquareWidget(
                  position: position,
                  lightColor: variant.lightSquareColor,
                  darkColor: variant.darkSquareColor,
                  pieceSet: variant.pieceSet,
                );
              },
            ),
            // Piece move animation overlay (slide + capture fade).
            Positioned.fill(
              child: IgnorePointer(
                child: MoveAnimationOverlay(boardSize: boardSize, pieceSet: variant.pieceSet),
              ),
            ),
            // Atomic explosion animation — only active for Atomic Chess.
            if (variant.id == 'atomic')
              Positioned.fill(
                child: IgnorePointer(
                  child: AtomicExplosionBoardOverlay(boardSize: boardSize),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SquareWidget extends ConsumerWidget {
  final Position position;
  final Color lightColor;
  final Color darkColor;
  final String pieceSet;

  const _SquareWidget({
    required this.position,
    required this.lightColor,
    required this.darkColor,
    this.pieceSet = 'standard',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.watch(gameNotifierProvider.notifier);
    final variant = ref.watch(selectedVariantProvider);
    final craters = ref.watch(atomicCratersProvider);

    final isLight = (position.row + position.col) % 2 == 0;
    final squareColor = isLight ? lightColor : darkColor;

    // King of the Hill: highlight the central 4 squares.
    final isHillSquare = variant.id == 'king_of_the_hill' &&
        KingOfTheHillChess.hillSquares.contains(position);

    // Atomic Chess: persistent scorch mark after an explosion.
    final isCrater = craters.contains(position);

    // Fog of War: compute fogged squares for the current player.
    final foggedSquares = notifier.foggedSquares;
    final isInFog = foggedSquares?.contains(position) ?? false;

    // Hide opponent pieces that are in fog.
    final rawPiece = gameState.board.getPiece(position);
    var piece = (isInFog && rawPiece?.color != gameState.currentTurn)
        ? null
        : rawPiece;

    // During move animation, suppress the piece at the destination (and
    // castling rook positions) so the overlay's sliding copy is the only
    // one visible.
    final animEvent = ref.watch(moveAnimationEventProvider);
    if (animEvent != null) {
      if (position == animEvent.to ||
          position == animEvent.secondaryTo ||
          position == animEvent.secondaryFrom) {
        piece = null;
      }
    }

    // Check if this square is selected or a valid move destination.
    final isSelected = notifier.selectedPosition == position;
    final isValidMove = notifier.selectedPieceMoves.any((m) => m.to == position);
    final moveForSquare = isValidMove
        ? notifier.selectedPieceMoves.firstWhere((m) => m.to == position)
        : null;

    Color? highlightColor;
    if (isSelected) {
      highlightColor = Colors.yellow.withAlpha(128);
    } else if (isValidMove) {
      highlightColor = moveForSquare?.isCapture == true
          ? Colors.red.withAlpha(102)
          : Colors.green.withAlpha(102);
    }

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

            // Atomic crater — scorched earth mark (before piece, after highlight)
            if (isCrater)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1A0A00).withAlpha(160),
                        const Color(0xFF3D1A00).withAlpha(60),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

            // Move indicator dot (empty squares not in fog)
            if (isValidMove && piece == null && !isInFog)
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
                    return PieceWidget(piece: piece!, size: pieceSize, pieceSet: pieceSet);
                  },
                ),
              ),

            // King of the Hill — golden border on the 4 central squares
            if (isHillSquare)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2.5,
                    ),
                    color: const Color(0xFFFFD700).withAlpha(18),
                  ),
                ),
              ),

            // Fog overlay — drawn on top to obscure unknown squares
            if (isInFog)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(160),
                ),
              ),

            // Faint dot for moves into fog (player knows they can move there)
            if (isValidMove && isInFog)
              Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(80),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
