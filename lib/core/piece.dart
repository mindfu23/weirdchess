import 'move.dart';
import 'board.dart';

/// Player color
enum PieceColor { white, black }

extension PieceColorExtension on PieceColor {
  PieceColor get opposite =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;

  int get direction => this == PieceColor.white ? -1 : 1;
}

/// Base class for all chess pieces
abstract class Piece {
  final PieceColor color;
  final String symbol;
  final String name;
  final int value;
  bool hasMoved;

  Piece({
    required this.color,
    required this.symbol,
    required this.name,
    required this.value,
    this.hasMoved = false,
  });

  /// Get all pseudo-legal moves for this piece (doesn't check for check)
  List<Move> getPseudoLegalMoves(Board board, Position position);

  /// Get all legal moves (filters out moves that leave king in check)
  List<Move> getLegalMoves(Board board, Position position) {
    final pseudoLegal = getPseudoLegalMoves(board, position);
    return pseudoLegal.where((move) {
      final testBoard = board.copy();
      testBoard.makeMove(move);
      return !testBoard.isInCheck(color);
    }).toList();
  }

  /// Returns positions this piece can attack (for check detection)
  List<Position> getAttackedSquares(Board board, Position position) {
    return getPseudoLegalMoves(board, position).map((m) => m.to).toList();
  }

  /// Create a copy of this piece
  Piece copy();

  /// Generate sliding moves in given directions
  List<Move> getSlidingMoves(
    Board board,
    Position from,
    List<Position> directions, {
    int maxDistance = 100,
  }) {
    final moves = <Move>[];
    for (final dir in directions) {
      for (int dist = 1; dist <= maxDistance; dist++) {
        final to = from + dir * dist;
        if (!to.isValid(board.size)) break;

        final target = board.getPiece(to);
        if (target == null) {
          moves.add(Move(from: from, to: to));
        } else {
          if (target.color != color) {
            moves.add(Move(from: from, to: to, isCapture: true));
          }
          break;
        }
      }
    }
    return moves;
  }

  /// Generate leaping moves to specific offsets
  List<Move> getLeapingMoves(Board board, Position from, List<Position> offsets) {
    final moves = <Move>[];
    for (final offset in offsets) {
      final to = from + offset;
      if (!to.isValid(board.size)) continue;

      final target = board.getPiece(to);
      if (target == null) {
        moves.add(Move(from: from, to: to));
      } else if (target.color != color) {
        moves.add(Move(from: from, to: to, isCapture: true));
      }
    }
    return moves;
  }

  @override
  String toString() => '${color == PieceColor.white ? 'W' : 'B'}$symbol';
}
