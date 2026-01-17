import 'package:flutter/foundation.dart';

/// Represents a position on the chess board
@immutable
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  Position operator +(Position other) => Position(row + other.row, col + other.col);
  Position operator -(Position other) => Position(row - other.row, col - other.col);
  Position operator *(int scalar) => Position(row * scalar, col * scalar);

  bool isValid(int boardSize) =>
      row >= 0 && row < boardSize && col >= 0 && col < boardSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';

  String toAlgebraic(int boardSize) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (boardSize - row).toString();
    return '$file$rank';
  }

  static Position? fromAlgebraic(String notation, int boardSize) {
    if (notation.length < 2) return null;
    final file = notation[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(notation.substring(1));
    if (rank == null || file < 0 || file >= boardSize) return null;
    return Position(boardSize - rank, file);
  }
}

/// Represents a chess move
@immutable
class Move {
  final Position from;
  final Position to;
  final String? promotionPiece;
  final bool isCapture;
  final bool isCastling;
  final bool isEnPassant;

  const Move({
    required this.from,
    required this.to,
    this.promotionPiece,
    this.isCapture = false,
    this.isCastling = false,
    this.isEnPassant = false,
  });

  Move copyWith({
    Position? from,
    Position? to,
    String? promotionPiece,
    bool? isCapture,
    bool? isCastling,
    bool? isEnPassant,
  }) {
    return Move(
      from: from ?? this.from,
      to: to ?? this.to,
      promotionPiece: promotionPiece ?? this.promotionPiece,
      isCapture: isCapture ?? this.isCapture,
      isCastling: isCastling ?? this.isCastling,
      isEnPassant: isEnPassant ?? this.isEnPassant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move && from == other.from && to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  @override
  String toString() => '${from.toAlgebraic(10)}-${to.toAlgebraic(10)}';

  String toAlgebraic(int boardSize) {
    final fromStr = from.toAlgebraic(boardSize);
    final toStr = to.toAlgebraic(boardSize);
    final capture = isCapture ? 'x' : '-';
    final promo = promotionPiece != null ? '=$promotionPiece' : '';
    return '$fromStr$capture$toStr$promo';
  }
}

/// Direction vectors for piece movement
class Direction {
  static const Position north = Position(-1, 0);
  static const Position south = Position(1, 0);
  static const Position east = Position(0, 1);
  static const Position west = Position(0, -1);
  static const Position northEast = Position(-1, 1);
  static const Position northWest = Position(-1, -1);
  static const Position southEast = Position(1, 1);
  static const Position southWest = Position(1, -1);

  static const List<Position> orthogonal = [north, south, east, west];
  static const List<Position> diagonal = [northEast, northWest, southEast, southWest];
  static const List<Position> all = [
    north, south, east, west,
    northEast, northWest, southEast, southWest
  ];

  static const List<Position> knightMoves = [
    Position(-2, -1), Position(-2, 1),
    Position(-1, -2), Position(-1, 2),
    Position(1, -2), Position(1, 2),
    Position(2, -1), Position(2, 1),
  ];
}
