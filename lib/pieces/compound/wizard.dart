import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Wizard: Leaps 1 square diagonally OR leaps to (3,1) or (1,3) squares (used in Omega Chess)
/// The (3,1) leap is like an extended knight move
class Wizard extends Piece {
  Wizard({required super.color, super.hasMoved})
      : super(symbol: 'W', name: 'Wizard', value: 4);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];

    // Leap 1 square diagonally (like a Ferz)
    moves.addAll(getLeapingMoves(board, position, Direction.diagonal));

    // Camel-like leap: (3,1) pattern
    final camelOffsets = [
      const Position(-3, -1),
      const Position(-3, 1),
      const Position(-1, -3),
      const Position(-1, 3),
      const Position(1, -3),
      const Position(1, 3),
      const Position(3, -1),
      const Position(3, 1),
    ];
    moves.addAll(getLeapingMoves(board, position, camelOffsets));

    return moves;
  }

  @override
  Piece copy() => Wizard(color: color, hasMoved: hasMoved);
}
