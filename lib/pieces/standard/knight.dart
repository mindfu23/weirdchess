import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class Knight extends Piece {
  Knight({required super.color, super.hasMoved})
      : super(symbol: 'N', name: 'Knight', value: 3);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getLeapingMoves(board, position, Direction.knightMoves);
  }

  @override
  Piece copy() => Knight(color: color, hasMoved: hasMoved);
}
