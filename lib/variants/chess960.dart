import 'dart:math';
import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Chess960 (Fischer Random Chess) — randomised starting positions.
///
/// Rules:
/// - The back rank is randomised for both sides (White mirrored for Black).
/// - Three constraints on the random position:
///   1. King is between the two rooks (enables castling).
///   2. Bishops are on opposite-coloured squares.
///   3. Otherwise fully random.
/// - Standard chess rules apply. Castling is modified:
///   - King always ends on g1/c1 (g8/c8 for Black).
///   - Rook always ends on f1/d1 (f8/d8 for Black).
///   - The rook can start anywhere between the king and the edge.
class Chess960 extends ChessVariant {
  /// Optional fixed starting position (0-959). Null = randomise each game.
  final int? positionId;

  Chess960({this.positionId});

  @override
  String get id => 'chess960';

  @override
  String get name => 'Chess960';

  @override
  String get description =>
      'Fischer Random — 960 starting positions, same endgame.';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFF0E68C);

  @override
  Color get darkSquareColor => const Color(0xFF556B2F);

  @override
  String get rulesUrl =>
      'https://www.chess.com/variants/chess960';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Chess960 (Fischer Random) uses the same rules as standard chess, except:

Setup:
- The back rank pieces are randomly shuffled each game
- Bishops must be on opposite-coloured squares
- The king must be between the two rooks (for castling)
- Black mirrors White's arrangement

Castling:
- King always ends on g1 (kingside) or c1 (queenside)
- Rook always ends on f1 (kingside) or d1 (queenside)
- The rook can start from any legal Chess960 position
- All standard castling restrictions apply (clear path, no check)

Position 518 = the standard chess starting position.
''';

  // ── Board setup ──────────────────────────────────────────────────────────

  @override
  Board createInitialBoard() {
    final backRank = _generateBackRank();
    final board = Board(size: 8);

    // White (row 7 = rank 1) and Black (row 0 = rank 8) mirror each other.
    for (int col = 0; col < 8; col++) {
      board.setPiece(
          Position(7, col), _createPieceForSymbol(backRank[col], PieceColor.white, col));
      board.setPiece(
          Position(0, col), _createPieceForSymbol(backRank[col], PieceColor.black, col));
    }

    for (int col = 0; col < 8; col++) {
      board.setPiece(Position(6, col), _whitePawn());
      board.setPiece(Position(1, col), _blackPawn());
    }

    return board;
  }

  /// Generate a valid Chess960 back-rank arrangement as a list of piece symbols.
  List<String> _generateBackRank() {
    final id = positionId ?? Random().nextInt(960);
    return _positionFromId(id);
  }

  /// Maps a Chess960 position ID (0-959) to the back-rank symbol list.
  /// Algorithm from https://en.wikipedia.org/wiki/Fischer_random_chess_numbering_scheme
  List<String> _positionFromId(int n) {
    final rank = List.filled(8, '');

    // Step 1: dark-square bishop (n1 = n % 4, places on cols 1,3,5,7)
    final n1 = n % 4;
    rank[n1 * 2 + 1] = 'B';
    n = n ~/ 4;

    // Step 2: light-square bishop (n2 = n % 4, places on cols 0,2,4,6)
    final n2 = n % 4;
    rank[n2 * 2] = 'B';
    n = n ~/ 4;

    // Step 3: queen (n3 = n % 6, places on nth empty square)
    final n3 = n % 6;
    n = n ~/ 6;
    int qCount = 0;
    for (int col = 0; col < 8; col++) {
      if (rank[col] == '') {
        if (qCount == n3) {
          rank[col] = 'Q';
          break;
        }
        qCount++;
      }
    }

    // Step 4: knights (n = 0-9 encodes the two knight positions in remaining 5 squares)
    final knightTable = [
      [0, 1], [0, 2], [0, 3], [0, 4],
      [1, 2], [1, 3], [1, 4],
      [2, 3], [2, 4],
      [3, 4],
    ];
    final knightCols = knightTable[n % 10];
    int kIdx = 0;
    int kCount = 0;
    for (int col = 0; col < 8; col++) {
      if (rank[col] == '') {
        if (kCount == knightCols[0] || kCount == knightCols[1]) {
          rank[col] = 'N';
          kIdx++;
          if (kIdx == 2) break;
        }
        kCount++;
      }
    }

    // Step 5: remaining 3 squares get R-K-R (left to right)
    final remaining = <int>[];
    for (int col = 0; col < 8; col++) {
      if (rank[col] == '') remaining.add(col);
    }
    rank[remaining[0]] = 'R';
    rank[remaining[1]] = 'K';
    rank[remaining[2]] = 'R';

    return rank;
  }

  Piece _createPieceForSymbol(String symbol, PieceColor color, int col) {
    switch (symbol) {
      case 'K':
        return King(color: color);
      case 'Q':
        return Queen(color: color);
      case 'R':
        return Rook(color: color);
      case 'B':
        return Bishop(color: color);
      case 'N':
        return Knight(color: color);
      default:
        throw StateError('Unexpected symbol $symbol in back rank');
    }
  }

  Pawn _whitePawn() => Pawn(
        color: PieceColor.white,
        startRow: 6,
        promotionRow: 0,
        promotionOptions: promotionOptions,
      );

  Pawn _blackPawn() => Pawn(
        color: PieceColor.black,
        startRow: 1,
        promotionRow: 7,
        promotionOptions: promotionOptions,
      );

  @override
  Piece createPiece(String symbol, PieceColor color) {
    switch (symbol) {
      case 'K':
        return King(color: color);
      case 'Q':
        return Queen(color: color);
      case 'R':
        return Rook(color: color);
      case 'B':
        return Bishop(color: color);
      case 'N':
        return Knight(color: color);
      case 'P':
        return color == PieceColor.white ? _whitePawn() : _blackPawn();
      default:
        throw ArgumentError('Unknown piece symbol: $symbol');
    }
  }

  // ── Variant hooks ──────────────────────────────────────────────────────

  /// Override king move generation to produce Chess960-aware castling moves.
  /// All other pieces use standard legal move generation.
  @override
  List<Move> getLegalMoves(Board board, Position pos, Piece piece) {
    if (piece.symbol != 'K') {
      return piece.getLegalMoves(board, pos);
    }

    // Get all non-castling king moves and filter by check.
    final pseudoLegal = piece.getPseudoLegalMoves(board, pos);
    final moves = pseudoLegal
        .where((m) => !m.isCastling)
        .where((m) {
          final testBoard = board.copy();
          testBoard.makeMove(m);
          return !testBoard.isInCheck(piece.color);
        })
        .toList();

    // Add Chess960-correct castling moves.
    if (!piece.hasMoved && !board.isInCheck(piece.color)) {
      moves.addAll(_getChess960CastlingMoves(board, pos, piece));
    }

    return moves;
  }

  List<Move> _getChess960CastlingMoves(
      Board board, Position kingPos, Piece king) {
    final moves = <Move>[];
    final row = kingPos.row;

    // Kingside: king ends on g-file (col 6), rook ends on f-file (col 5).
    final kingsideRookCol = _findRookCol(board, row, kingPos.col, true);
    if (kingsideRookCol != null) {
      final kingDest = Position(row, 6);
      final rookDest = Position(row, 5);
      if (_isCastleLegal(board, kingPos, kingsideRookCol, kingDest, rookDest, king.color)) {
        moves.add(Move(from: kingPos, to: kingDest, isCastling: true));
      }
    }

    // Queenside: king ends on c-file (col 2), rook ends on d-file (col 3).
    final queensideRookCol = _findRookCol(board, row, kingPos.col, false);
    if (queensideRookCol != null) {
      final kingDest = Position(row, 2);
      final rookDest = Position(row, 3);
      if (_isCastleLegal(board, kingPos, queensideRookCol, kingDest, rookDest, king.color)) {
        moves.add(Move(from: kingPos, to: kingDest, isCastling: true));
      }
    }

    return moves;
  }

  /// Finds the column of an unmoved rook on [row] to the right (kingside=true)
  /// or left (kingside=false) of the king's column.
  int? _findRookCol(Board board, int row, int kingCol, bool kingside) {
    if (kingside) {
      for (int col = board.size - 1; col > kingCol; col--) {
        final p = board.getPiece(Position(row, col));
        if (p != null) {
          if (p.symbol == 'R' && !p.hasMoved) return col;
          break;
        }
      }
    } else {
      for (int col = 0; col < kingCol; col++) {
        final p = board.getPiece(Position(row, col));
        if (p != null) {
          if (p.symbol == 'R' && !p.hasMoved) return col;
          break;
        }
      }
    }
    return null;
  }

  /// Validates Chess960 castling: path between all involved squares must be
  /// clear (excluding king and rook), and the king must not pass through check.
  bool _isCastleLegal(
    Board board,
    Position kingPos,
    int rookCol,
    Position kingDest,
    Position rookDest,
    PieceColor color,
  ) {
    final row = kingPos.row;

    // All squares in the range [min, max] of king/rook start/end must be clear,
    // except for the king and rook themselves.
    final minCol = [kingPos.col, rookCol, kingDest.col, rookDest.col]
        .reduce((a, b) => a < b ? a : b);
    final maxCol = [kingPos.col, rookCol, kingDest.col, rookDest.col]
        .reduce((a, b) => a > b ? a : b);

    for (int col = minCol; col <= maxCol; col++) {
      if (col == kingPos.col || col == rookCol) continue;
      if (board.getPiece(Position(row, col)) != null) return false;
    }

    // King must not pass through or land on an attacked square.
    final kingStart = kingPos.col;
    final kingEnd = kingDest.col;
    final step = kingStart < kingEnd ? 1 : -1;
    for (int col = kingStart; col != kingEnd + step; col += step) {
      if (board.isSquareAttacked(Position(row, col), color.opposite)) {
        return false;
      }
    }

    return true;
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription:
              'Moves one square in any direction. Chess960 castling: king always '
              'ends on g1 or c1, regardless of starting position.',
        ),
        'Q': const PieceInfo(
          name: 'Queen',
          symbol: 'Q',
          value: 9,
          movementDescription:
              'Moves any number of squares in any direction.',
        ),
        'R': const PieceInfo(
          name: 'Rook',
          symbol: 'R',
          value: 5,
          movementDescription:
              'Moves horizontally or vertically. In Chess960, can start '
              'from any column between the king and the board edge.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription:
              'Moves diagonally. One bishop per colour of square.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription: 'L-shape mover. Can jump over pieces.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription:
              'Moves forward, captures diagonally. Promotes on last rank.',
        ),
      };
}
