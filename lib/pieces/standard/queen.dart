import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class Queen extends Piece {
  Queen({required super.color, super.hasMoved})
      : super(symbol: 'Q', name: 'Queen', value: 9);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.all);
  }

  @override
  Piece copy() => Queen(color: color, hasMoved: hasMoved);
}
