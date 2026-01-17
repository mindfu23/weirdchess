import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Amazon/Zurafa: Queen + Knight (used in Hyderabad as Zurafa/Giraffe)
class Amazon extends Piece {
  Amazon({required super.color, super.hasMoved})
      : super(symbol: 'A', name: 'Amazon', value: 12);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    // Queen moves (all directions sliding)
    moves.addAll(getSlidingMoves(board, position, Direction.all));
    // Knight moves (leaping)
    moves.addAll(getLeapingMoves(board, position, Direction.knightMoves));
    return moves;
  }

  @override
  Piece copy() => Amazon(color: color, hasMoved: hasMoved);
}
