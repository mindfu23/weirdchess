import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_result.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Horde Chess — 36 white pawns vs a standard black army.
///
/// Rules:
/// - White (the Horde): 36 pawns, NO king.
/// - Black: standard chess setup (king, queen, 2 rooks, 2 bishops, 2 knights,
///   8 pawns).
/// - White wins by checkmating Black's king.
/// - Black wins by capturing ALL of White's pieces (pawns + any promoted).
/// - White has no king so White can never be in check or checkmated; all
///   moves that are pseudo-legal are legal for White.
/// - White pawns CAN promote on rank 8 (Black's back rank).
class HordeChess extends ChessVariant {
  @override
  String get id => 'horde';

  @override
  String get name => 'Horde Chess';

  @override
  String get description =>
      'Survive the pawn invasion! Black vs 36 white pawns.';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFF5F5DC);

  @override
  Color get darkSquareColor => const Color(0xFF8B6914);

  @override
  String get rulesUrl =>
      'https://www.chess.com/variants/horde';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Horde Chess — asymmetric battle:

White (the Horde):
- 36 pawns on ranks 1-5, NO king
- White wins by checkmating Black's king
- Pawns can promote on rank 8

Black (Standard army):
- Normal chess setup
- Black wins by capturing ALL White pieces (pawns + promoted)
- Normal king — can be checked and checkmated

Notes:
- White has no king, so White is never in "check"
- All White moves are legal as long as they follow pawn/piece rules
- Once all Horde pawns/pieces are gone, Black wins
''';

  // ── Starting position ─────────────────────────────────────────────────

  @override
  Board createInitialBoard() {
    final board = Board(size: 8);

    // Black standard setup (rows 0-1 = ranks 8-7)
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

    // White Horde: 36 pawns
    // Ranks 1-4 (rows 7-4) = 32 pawns
    for (int row = 4; row <= 7; row++) {
      for (int col = 0; col < 8; col++) {
        board.setPiece(Position(row, col), _whitePawn());
      }
    }
    // Rank 5 (row 3): b5, c5, f5, g5 (cols 1,2,5,6)
    board.setPiece(const Position(3, 1), _whitePawnStatic());
    board.setPiece(const Position(3, 2), _whitePawnStatic());
    board.setPiece(const Position(3, 5), _whitePawnStatic());
    board.setPiece(const Position(3, 6), _whitePawnStatic());

    return board;
  }

  static Pawn _whitePawnStatic() => Pawn(
        color: PieceColor.white,
        startRow: 6, // standard double-push row
        promotionRow: 0,
        promotionOptions: ['Q', 'R', 'B', 'N'],
      );

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

  /// White has no king — [requiresKing] is false for white so board.isInCheck()
  /// already returns false (king not found). This flag is informational for
  /// any future UI that might warn about missing kings.
  @override
  bool requiresKing(PieceColor color) => color == PieceColor.black;

  /// White's move generation: since there is no white king, all pseudo-legal
  /// pawn moves (and promoted-piece moves) are legal — board.isInCheck(white)
  /// already returns false. So we can use the standard implementation and it
  /// behaves correctly. But to be explicit and avoid any edge-case issues with
  /// the check filter seeing a missing king, we bypass the filter for White.
  @override
  List<Move> getLegalMoves(Board board, Position pos, Piece piece) {
    if (piece.color == PieceColor.white) {
      // White has no king — all pseudo-legal moves are legal.
      return piece.getPseudoLegalMoves(board, pos);
    }
    // Black uses standard check-filtering.
    return piece.getLegalMoves(board, pos);
  }

  /// Black wins when all White pieces are captured.
  @override
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  ) {
    if (board.getPieces(PieceColor.white).isEmpty) {
      return GameResult.blackWins;
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
              'Black only. Moves one square in any direction. Can be checkmated.',
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
              'Moves horizontally or vertically.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription: 'Moves diagonally.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription: 'L-shape. Jumps over pieces.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription:
              'White Horde: advances toward rank 8 and can promote. '
              'Black: standard pawn.',
        ),
      };
}
