import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import 'piece_widget.dart';

/// Overlay that animates piece movement (slide + capture fade) on the board.
///
/// Sits in the board's Stack above the GridView. During the ~200 ms animation
/// the real piece at the destination is suppressed by [_SquareWidget] so the
/// user only sees the sliding copy.
class MoveAnimationOverlay extends ConsumerWidget {
  final int boardSize;
  final String pieceSet;

  const MoveAnimationOverlay({super.key, required this.boardSize, this.pieceSet = 'standard'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(moveAnimationEventProvider);
    if (event == null) return const SizedBox.shrink();

    final humanColor = ref.watch(humanColorProvider);
    final isFlipped = humanColor == PieceColor.black;

    return _AnimatedPieceSlide(
      key: ValueKey('${event.from}-${event.to}'),
      event: event,
      boardSize: boardSize,
      isFlipped: isFlipped,
      pieceSet: pieceSet,
    );
  }
}

class _AnimatedPieceSlide extends StatefulWidget {
  final MoveAnimationEvent event;
  final int boardSize;
  final bool isFlipped;
  final String pieceSet;

  const _AnimatedPieceSlide({
    super.key,
    required this.event,
    required this.boardSize,
    required this.isFlipped,
    this.pieceSet = 'standard',
  });

  @override
  State<_AnimatedPieceSlide> createState() => _AnimatedPieceSlideState();
}

class _AnimatedPieceSlideState extends State<_AnimatedPieceSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convert a board Position to fractional offsets (0..1) within the overlay,
  /// accounting for board flip.
  Offset _positionToFraction(int row, int col) {
    final bs = widget.boardSize;
    final displayCol =
        widget.isFlipped ? (bs - 1 - col).toDouble() : col.toDouble();
    final displayRow =
        widget.isFlipped ? (bs - 1 - row).toDouble() : row.toDouble();
    return Offset(displayCol / bs, displayRow / bs);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final t = _curve.value;
        return Stack(
          children: [
            // Captured piece fading out at destination.
            if (e.capturedPiece != null)
              _buildFadingPiece(e.capturedPiece!, e.to.row, e.to.col, t),

            // Primary piece sliding from → to.
            _buildSlidingPiece(
                e.piece, e.from.row, e.from.col, e.to.row, e.to.col, t),

            // Secondary piece (castling rook) sliding.
            if (e.secondaryPiece != null &&
                e.secondaryFrom != null &&
                e.secondaryTo != null)
              _buildSlidingPiece(
                e.secondaryPiece!,
                e.secondaryFrom!.row,
                e.secondaryFrom!.col,
                e.secondaryTo!.row,
                e.secondaryTo!.col,
                t,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSlidingPiece(
      Piece piece, int fromRow, int fromCol, int toRow, int toCol, double t) {
    final bs = widget.boardSize;
    final from = _positionToFraction(fromRow, fromCol);
    final to = _positionToFraction(toRow, toCol);
    final current = Offset.lerp(from, to, t)!;

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final squareSize = constraints.maxWidth / bs;
          final pieceSize = squareSize * 0.8;
          final offset = squareSize * 0.1; // center within square

          return Stack(
            children: [
              Positioned(
                left: current.dx * constraints.maxWidth + offset,
                top: current.dy * constraints.maxHeight + offset,
                width: pieceSize,
                height: pieceSize,
                child: PieceWidget(piece: piece, size: pieceSize, pieceSet: widget.pieceSet),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFadingPiece(Piece piece, int row, int col, double t) {
    final bs = widget.boardSize;
    final pos = _positionToFraction(row, col);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final squareSize = constraints.maxWidth / bs;
          final pieceSize = squareSize * 0.8;
          final offset = squareSize * 0.1;

          return Stack(
            children: [
              Positioned(
                left: pos.dx * constraints.maxWidth + offset,
                top: pos.dy * constraints.maxHeight + offset,
                width: pieceSize,
                height: pieceSize,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: PieceWidget(piece: piece, size: pieceSize, pieceSet: widget.pieceSet),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
