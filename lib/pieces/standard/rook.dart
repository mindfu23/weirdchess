import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class Rook extends Piece {
  Rook({required super.color, super.hasMoved})
      : super(symbol: 'R', name: 'Rook', value: 5);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.orthogonal);
  }

  @override
  Piece copy() => Rook(color: color, hasMoved: hasMoved);
}
