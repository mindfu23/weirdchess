import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Champion: Leaps 1 or 2 squares orthogonally (used in Omega Chess)
class Champion extends Piece {
  Champion({required super.color, super.hasMoved})
      : super(symbol: 'Ch', name: 'Champion', value: 4);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];

    // Leap 1 square orthogonally
    moves.addAll(getLeapingMoves(board, position, Direction.orthogonal));

    // Leap 2 squares orthogonally (jumping over pieces)
    final twoSquareOffsets = [
      const Position(-2, 0),
      const Position(2, 0),
      const Position(0, -2),
      const Position(0, 2),
    ];
    moves.addAll(getLeapingMoves(board, position, twoSquareOffsets));

    // Also leaps 2 squares diagonally
    final diagOffsets = [
      const Position(-2, -2),
      const Position(-2, 2),
      const Position(2, -2),
      const Position(2, 2),
    ];
    moves.addAll(getLeapingMoves(board, position, diagOffsets));

    return moves;
  }

  @override
  Piece copy() => Champion(color: color, hasMoved: hasMoved);
}
