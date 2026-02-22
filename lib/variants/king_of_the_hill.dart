import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_result.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// King of the Hill — race your king to the center to win.
/// The four center squares (d4, d5, e4, e5 → cols 3-4, rows 3-4 in 0-indexed)
/// are the "hill". A player wins immediately when their king ends a move on
/// one of those squares. Standard checkmate is also still a win condition.
class KingOfTheHillChess extends ChessVariant {
  /// The four hill squares in board coordinates (row, col), 0-indexed.
  /// Row 3 = rank 5, Row 4 = rank 4 on an 8×8 board.
  /// Note: cannot be `const` because Position overrides == and hashCode.
  static final Set<Position> hillSquares = {
    const Position(3, 3), // d5
    const Position(3, 4), // e5
    const Position(4, 3), // d4
    const Position(4, 4), // e4
  };

  @override
  String get id => 'king_of_the_hill';

  @override
  String get name => 'King of the Hill';

  @override
  String get description =>
      'Race your king to the centre 4 squares to win.';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFDEB887);

  @override
  Color get darkSquareColor => const Color(0xFF8B4513);

  @override
  String get rulesUrl =>
      'https://www.chess.com/variants/king-of-the-hill';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
King of the Hill follows standard chess rules with one addition:

Win conditions:
- Checkmate (standard)
- Move your king to one of the four centre squares (d4, d5, e4, e5)

The centre squares are highlighted on the board.

Strategy:
- Racing your king to the centre is often faster than checkmating
- Controlling the centre has dual purpose: positional AND win-condition
- Your king must be safe on the centre square at the END of your move
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 8);

    board.setPiece(const Position(7, 0), Rook(color: PieceColor.white));
    board.setPiece(const Position(7, 1), Knight(color: PieceColor.white));
    board.setPiece(const Position(7, 2), Bishop(color: PieceColor.white));
    board.setPiece(const Position(7, 3), Queen(color: PieceColor.white));
    board.setPiece(const Position(7, 4), King(color: PieceColor.white));
    board.setPiece(const Position(7, 5), Bishop(color: PieceColor.white));
    board.setPiece(const Position(7, 6), Knight(color: PieceColor.white));
    board.setPiece(const Position(7, 7), Rook(color: PieceColor.white));
    for (int col = 0; col < 8; col++) {
      board.setPiece(Position(6, col), _whitePawn());
    }

    board.setPiece(const Position(0, 0), Rook(color: PieceColor.black));
    board.setPiece(const Position(0, 1), Knight(color: PieceColor.black));
    board.setPiece(const Position(0, 2), Bishop(color: PieceColor.black));
    board.setPiece(const Position(0, 3), Queen(color: PieceColor.black));
    board.setPiece(const Position(0, 4), King(color: PieceColor.black));
    board.setPiece(const Position(0, 5), Bishop(color: PieceColor.black));
    board.setPiece(const Position(0, 6), Knight(color: PieceColor.black));
    board.setPiece(const Position(0, 7), Rook(color: PieceColor.black));
    for (int col = 0; col < 8; col++) {
      board.setPiece(Position(1, col), _blackPawn());
    }

    return board;
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

  @override
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  ) {
    // The player who just moved is currentTurn.opposite.
    final justMoved = currentTurn.opposite;
    final kingPos = board.findKing(justMoved);

    if (kingPos != null && hillSquares.contains(kingPos)) {
      return justMoved == PieceColor.white
          ? GameResult.whiteWins
          : GameResult.blackWins;
    }

    return null;
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription:
              'Moves one square in any direction. Reach the centre (d4-e5) to win!',
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
              'Moves any number of squares horizontally or vertically.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription: 'Moves any number of squares diagonally.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription: 'Moves in an L-shape. Can jump over pieces.',
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
