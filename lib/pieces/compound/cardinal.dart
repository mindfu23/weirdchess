import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Cardinal: Bishop + Knight (used in Grand Chess)
class Cardinal extends Piece {
  Cardinal({required super.color, super.hasMoved})
      : super(symbol: 'C', name: 'Cardinal', value: 6);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    // Bishop moves (diagonal sliding)
    moves.addAll(getSlidingMoves(board, position, Direction.diagonal));
    // Knight moves (leaping)
    moves.addAll(getLeapingMoves(board, position, Direction.knightMoves));
    return moves;
  }

  @override
  Piece copy() => Cardinal(color: color, hasMoved: hasMoved);
}
