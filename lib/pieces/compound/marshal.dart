import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Marshal: Rook + Knight (used in Grand Chess)
class Marshal extends Piece {
  Marshal({required super.color, super.hasMoved})
      : super(symbol: 'M', name: 'Marshal', value: 8);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    // Rook moves (orthogonal sliding)
    moves.addAll(getSlidingMoves(board, position, Direction.orthogonal));
    // Knight moves (leaping)
    moves.addAll(getLeapingMoves(board, position, Direction.knightMoves));
    return moves;
  }

  @override
  Piece copy() => Marshal(color: color, hasMoved: hasMoved);
}
