import '../../core/board.dart';
import '../../core/move.dart';
import '../../core/piece.dart';

/// Chief: Moves up to 3 squares in any direction
class Chief extends Piece {
  Chief({required super.color, super.hasMoved})
      : super(symbol: 'Cf', name: 'Chief', value: 10000);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.all, maxDistance: 3);
  }

  @override
  Piece copy() => Chief(color: color, hasMoved: hasMoved);
}

/// Princess: Moves up to 3 squares in any direction
/// Note: In traditional Jetan, cannot move until another piece occupies her square
/// This simplified version allows normal movement
class Princess extends Piece {
  Princess({required super.color, super.hasMoved})
      : super(symbol: 'Pr', name: 'Princess', value: 9);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.all, maxDistance: 3);
  }

  @override
  Piece copy() => Princess(color: color, hasMoved: hasMoved);
}

/// Flier: Moves up to 3 squares diagonally
class Flier extends Piece {
  Flier({required super.color, super.hasMoved})
      : super(symbol: 'Fl', name: 'Flier', value: 5);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.diagonal, maxDistance: 3);
  }

  @override
  Piece copy() => Flier(color: color, hasMoved: hasMoved);
}

/// Dwar: Moves up to 3 squares orthogonally
class Dwar extends Piece {
  Dwar({required super.color, super.hasMoved})
      : super(symbol: 'Dw', name: 'Dwar', value: 5);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.orthogonal, maxDistance: 3);
  }

  @override
  Piece copy() => Dwar(color: color, hasMoved: hasMoved);
}

/// Padwar: Moves up to 2 squares diagonally
class Padwar extends Piece {
  Padwar({required super.color, super.hasMoved})
      : super(symbol: 'Pd', name: 'Padwar', value: 3);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.diagonal, maxDistance: 2);
  }

  @override
  Piece copy() => Padwar(color: color, hasMoved: hasMoved);
}

/// Warrior: Moves up to 2 squares orthogonally
class Warrior extends Piece {
  Warrior({required super.color, super.hasMoved})
      : super(symbol: 'Wa', name: 'Warrior', value: 3);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getSlidingMoves(board, position, Direction.orthogonal, maxDistance: 2);
  }

  @override
  Piece copy() => Warrior(color: color, hasMoved: hasMoved);
}

/// Thoat: Moves up to 2 squares in any direction OR leaps like a knight
class Thoat extends Piece {
  Thoat({required super.color, super.hasMoved})
      : super(symbol: 'Th', name: 'Thoat', value: 4);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    final moves = <Move>[];
    // 2 squares in any direction (sliding)
    moves.addAll(getSlidingMoves(board, position, Direction.all, maxDistance: 2));
    // Knight leap
    moves.addAll(getLeapingMoves(board, position, Direction.knightMoves));
    return moves;
  }

  @override
  Piece copy() => Thoat(color: color, hasMoved: hasMoved);
}

/// Panthan: Moves 1 square in any direction (like a king)
class Panthan extends Piece {
  Panthan({required super.color, super.hasMoved})
      : super(symbol: 'Pa', name: 'Panthan', value: 1);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) {
    return getLeapingMoves(board, position, Direction.all);
  }

  @override
  Piece copy() => Panthan(color: color, hasMoved: hasMoved);
}
