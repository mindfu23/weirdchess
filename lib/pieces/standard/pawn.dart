import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class Pawn extends Piece {
  final int startRow;
  final int promotionRow;
  final List<String> promotionOptions;

  Pawn({
    required super.color,
    super.hasMoved,
    required this.startRow,
    required this.promotionRow,
    this.promotionOptions = const ['Q', 'R', 'B', 'N'],
  }) : super(symbol: 'P', name: 'Pawn', value: 1);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    final dir = color.direction;

    // Forward move
    final oneStep = Position(position.row + dir, position.col);
    if (oneStep.isValid(board.size) && board.getPiece(oneStep) == null) {
      _addMoveWithPromotion(moves, position, oneStep, false, board.size);

      // Two-step from starting position
      if (position.row == startRow) {
        final twoStep = Position(position.row + 2 * dir, position.col);
        if (board.getPiece(twoStep) == null) {
          moves.add(Move(from: position, to: twoStep));
        }
      }
    }

    // Diagonal captures
    for (final colOffset in [-1, 1]) {
      final capturePos = Position(position.row + dir, position.col + colOffset);
      if (!capturePos.isValid(board.size)) continue;

      final target = board.getPiece(capturePos);
      if (target != null && target.color != color) {
        _addMoveWithPromotion(moves, position, capturePos, true, board.size);
      }

      // En passant
      if (board.enPassantTarget == capturePos) {
        moves.add(Move(
          from: position,
          to: capturePos,
          isCapture: true,
          isEnPassant: true,
        ));
      }
    }

    return moves;
  }

  void _addMoveWithPromotion(
    List<Move> moves,
    Position from,
    Position to,
    bool isCapture,
    int boardSize,
  ) {
    if (to.row == promotionRow) {
      for (final promo in promotionOptions) {
        moves.add(Move(
          from: from,
          to: to,
          isCapture: isCapture,
          promotionPiece: promo,
        ));
      }
    } else {
      moves.add(Move(from: from, to: to, isCapture: isCapture));
    }
  }

  @override
  List<Position> getAttackedSquares(Board board, Position position) {
    final dir = color.direction;
    final attacked = <Position>[];

    for (final colOffset in [-1, 1]) {
      final pos = Position(position.row + dir, position.col + colOffset);
      if (pos.isValid(board.size)) {
        attacked.add(pos);
      }
    }

    return attacked;
  }

  @override
  Piece copy() => Pawn(
        color: color,
        hasMoved: hasMoved,
        startRow: startRow,
        promotionRow: promotionRow,
        promotionOptions: promotionOptions,
      );
}
