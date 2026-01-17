import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

class King extends Piece {
  King({required super.color, super.hasMoved})
      : super(symbol: 'K', name: 'King', value: 10000);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = getLeapingMoves(board, position, Direction.all);

    // Add castling moves
    if (!hasMoved && !board.isInCheck(color)) {
      // Kingside castling
      if (_canCastleKingside(board, position)) {
        moves.add(Move(
          from: position,
          to: Position(position.row, position.col + 2),
          isCastling: true,
        ));
      }
      // Queenside castling
      if (_canCastleQueenside(board, position)) {
        moves.add(Move(
          from: position,
          to: Position(position.row, position.col - 2),
          isCastling: true,
        ));
      }
    }

    return moves;
  }

  bool _canCastleKingside(Board board, Position kingPos) {
    final rookCol = board.size - 1;
    final rook = board.getPiece(Position(kingPos.row, rookCol));

    if (rook == null || rook.symbol != 'R' || rook.hasMoved) return false;

    // Check squares between king and rook are empty
    for (int col = kingPos.col + 1; col < rookCol; col++) {
      if (board.getPiece(Position(kingPos.row, col)) != null) return false;
    }

    // Check king doesn't pass through check
    for (int col = kingPos.col; col <= kingPos.col + 2; col++) {
      if (board.isSquareAttacked(Position(kingPos.row, col), color.opposite)) {
        return false;
      }
    }

    return true;
  }

  bool _canCastleQueenside(Board board, Position kingPos) {
    const rookCol = 0;
    final rook = board.getPiece(Position(kingPos.row, rookCol));

    if (rook == null || rook.symbol != 'R' || rook.hasMoved) return false;

    // Check squares between king and rook are empty
    for (int col = rookCol + 1; col < kingPos.col; col++) {
      if (board.getPiece(Position(kingPos.row, col)) != null) return false;
    }

    // Check king doesn't pass through check
    for (int col = kingPos.col; col >= kingPos.col - 2; col--) {
      if (board.isSquareAttacked(Position(kingPos.row, col), color.opposite)) {
        return false;
      }
    }

    return true;
  }

  @override
  List<Position> getAttackedSquares(Board board, Position position) {
    // King attacks all adjacent squares (not castling squares)
    return Direction.all
        .map((d) => position + d)
        .where((p) => p.isValid(board.size))
        .toList();
  }

  @override
  Piece copy() => King(color: color, hasMoved: hasMoved);
}
