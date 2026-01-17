import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class Bishop extends Piece {
  Bishop({required super.color, super.hasMoved})
      : super(symbol: 'B', name: 'Bishop', value: 3);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.diagonal);
  }

  @override
  Piece copy() => Bishop(color: color, hasMoved: hasMoved);
}
