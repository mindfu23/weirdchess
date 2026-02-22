import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_result.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Three-Check Chess — win by giving check three times.
/// All standard chess rules apply; a player who gives check three times wins
/// immediately, in addition to the normal checkmate win condition.
class ThreeCheckChess extends ChessVariant {
  static const _whiteChecksKey = 'white_checks';
  static const _blackChecksKey = 'black_checks';

  @override
  String get id => 'three_check';

  @override
  String get name => 'Three-Check';

  @override
  String get description =>
      'Give check 3 times to win. Standard rules otherwise.';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFE8D5B7);

  @override
  Color get darkSquareColor => const Color(0xFF9B7355);

  @override
  String get rulesUrl => 'https://www.chess.com/variants/3-check';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Three-Check follows all standard chess rules with one addition:

Win conditions:
- Checkmate (standard)
- Give check THREE times — the check counter is shown for both sides

Strategy:
- Checks are valuable even when they don't lead to immediate material gain
- Perpetual check wins the game instead of drawing
- Defend carefully — checks cost you a counter
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

  /// After each move, if the opponent's king is in check, increment the
  /// moving side's check counter.
  @override
  void updateVariantData(
    Board board,
    Move move,
    PieceColor justMoved,
    Map<String, dynamic> data,
  ) {
    data[_whiteChecksKey] ??= 0;
    data[_blackChecksKey] ??= 0;

    final opponentColor = justMoved.opposite;
    if (board.isInCheck(opponentColor)) {
      final key =
          justMoved == PieceColor.white ? _whiteChecksKey : _blackChecksKey;
      data[key] = (data[key] as int) + 1;
    }
  }

  @override
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  ) {
    final whiteChecks = (data[_whiteChecksKey] ?? 0) as int;
    final blackChecks = (data[_blackChecksKey] ?? 0) as int;

    if (whiteChecks >= 3) return GameResult.whiteWins;
    if (blackChecks >= 3) return GameResult.blackWins;
    return null;
  }

  /// Returns the current check counts [white, black].
  static (int, int) getCheckCounts(Map<String, dynamic> data) {
    return (
      (data[_whiteChecksKey] ?? 0) as int,
      (data[_blackChecksKey] ?? 0) as int,
    );
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription:
              'Moves one square in any direction. Can castle with a Rook.',
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
