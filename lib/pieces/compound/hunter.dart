import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Hunter: Moves forward like a Rook (orthogonal), backward like a Bishop (diagonal)
/// Used in Decimal Falcon-Hunter Chess
class Hunter extends Piece {
  Hunter({required super.color, super.hasMoved})
      : super(symbol: 'Hu', name: 'Hunter', value: 5);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    final forward = color.direction; // -1 for white (up), 1 for black (down)

    // Forward orthogonal moves (toward opponent)
    final forwardOrthogonals = [
      Position(forward, 0), // forward
      const Position(0, -1), // left
      const Position(0, 1), // right
    ];
    moves.addAll(getSlidingMoves(board, position, forwardOrthogonals));

    // Backward diagonal moves (toward own side)
    final backwardDiagonals = [
      Position(-forward, -1),
      Position(-forward, 1),
    ];
    moves.addAll(getSlidingMoves(board, position, backwardDiagonals));

    return moves;
  }

  @override
  Piece copy() => Hunter(color: color, hasMoved: hasMoved);
}
