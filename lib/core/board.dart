import 'move.dart';
import 'piece.dart';

/// Represents a chess board of arbitrary size
class Board {
  final int size;
  final List<List<Piece?>> _squares;
  Position? enPassantTarget;

  Board({required this.size})
      : _squares = List.generate(size, (_) => List.filled(size, null));

  Board._copy(this.size, this._squares, this.enPassantTarget);

  /// Get piece at position
  Piece? getPiece(Position pos) {
    if (!pos.isValid(size)) return null;
    return _squares[pos.row][pos.col];
  }

  /// Set piece at position
  void setPiece(Position pos, Piece? piece) {
    if (pos.isValid(size)) {
      _squares[pos.row][pos.col] = piece;
    }
  }

  /// Remove piece from position and return it
  Piece? removePiece(Position pos) {
    final piece = getPiece(pos);
    setPiece(pos, null);
    return piece;
  }

  /// Execute a move on the board
  void makeMove(Move move) {
    final piece = removePiece(move.from);
    if (piece == null) return;

    // Handle en passant capture
    if (move.isEnPassant && enPassantTarget != null) {
      final captureRow = move.from.row;
      removePiece(Position(captureRow, move.to.col));
    }

    // Handle castling
    if (move.isCastling) {
      final isKingside = move.to.col > move.from.col;
      final rookFromCol = isKingside ? size - 1 : 0;
      final rookToCol = isKingside ? move.to.col - 1 : move.to.col + 1;
      final rook = removePiece(Position(move.from.row, rookFromCol));
      if (rook != null) {
        rook.hasMoved = true;
        setPiece(Position(move.from.row, rookToCol), rook);
      }
    }

    piece.hasMoved = true;
    setPiece(move.to, piece);

    // Update en passant target
    enPassantTarget = null;
    if (piece.symbol == 'P') {
      final moveDistance = (move.to.row - move.from.row).abs();
      if (moveDistance == 2) {
        enPassantTarget = Position(
          (move.from.row + move.to.row) ~/ 2,
          move.to.col,
        );
      }
    }
  }

  /// Find the king of given color
  Position? findKing(PieceColor color) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.symbol == 'K' && piece.color == color) {
          return Position(row, col);
        }
      }
    }
    return null;
  }

  /// Check if the given color's king is in check
  bool isInCheck(PieceColor color) {
    final kingPos = findKing(color);
    if (kingPos == null) return false;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.color != color) {
          final attacks = piece.getAttackedSquares(this, Position(row, col));
          if (attacks.contains(kingPos)) return true;
        }
      }
    }
    return false;
  }

  /// Check if a square is attacked by any piece of given color
  bool isSquareAttacked(Position pos, PieceColor byColor) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.color == byColor) {
          final attacks = piece.getAttackedSquares(this, Position(row, col));
          if (attacks.contains(pos)) return true;
        }
      }
    }
    return false;
  }

  /// Get all pieces of a given color
  List<(Position, Piece)> getPieces(PieceColor color) {
    final pieces = <(Position, Piece)>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.color == color) {
          pieces.add((Position(row, col), piece));
        }
      }
    }
    return pieces;
  }

  /// Get all legal moves for a given color
  List<Move> getAllLegalMoves(PieceColor color) {
    final moves = <Move>[];
    for (final (pos, piece) in getPieces(color)) {
      moves.addAll(piece.getLegalMoves(this, pos));
    }
    return moves;
  }

  /// Create a deep copy of the board
  Board copy() {
    final newSquares = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => _squares[row][col]?.copy(),
      ),
    );
    return Board._copy(size, newSquares, enPassantTarget);
  }

  /// Clear the board
  void clear() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        _squares[row][col] = null;
      }
    }
    enPassantTarget = null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (int row = 0; row < size; row++) {
      buffer.write('${size - row}'.padLeft(2));
      buffer.write(' ');
      for (int col = 0; col < size; col++) {
        final piece = _squares[row][col];
        buffer.write(piece?.toString() ?? ' . ');
        buffer.write(' ');
      }
      buffer.writeln();
    }
    buffer.write('   ');
    for (int col = 0; col < size; col++) {
      buffer.write(' ${String.fromCharCode('a'.codeUnitAt(0) + col)}  ');
    }
    return buffer.toString();
  }
}
