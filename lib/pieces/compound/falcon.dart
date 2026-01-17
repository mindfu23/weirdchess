import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Falcon: Moves forward like a Bishop (diagonal), backward like a Rook (orthogonal)
/// Used in Decimal Falcon-Hunter Chess
class Falcon extends Piece {
  Falcon({required super.color, super.hasMoved})
      : super(symbol: 'Fa', name: 'Falcon', value: 5);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    final forward = color.direction; // -1 for white (up), 1 for black (down)

    // Forward diagonal moves (toward opponent)
    final forwardDiagonals = [
      Position(forward, -1),
      Position(forward, 1),
    ];
    moves.addAll(getSlidingMoves(board, position, forwardDiagonals));

    // Backward orthogonal moves (toward own side)
    final backwardOrthogonals = [
      Position(-forward, 0), // backward
      const Position(0, -1), // left
      const Position(0, 1), // right
    ];
    moves.addAll(getSlidingMoves(board, position, backwardOrthogonals));

    return moves;
  }

  @override
  Piece copy() => Falcon(color: color, hasMoved: hasMoved);
}
