import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Fog of War (Dark Chess) — each player can only see squares their pieces
/// attack or occupy.
///
/// Visibility rules (Lichess standard):
/// - A square is visible if any of the current player's pieces occupies or
///   attacks it.
/// - Sliding pieces (Q, R, B) reveal squares along their paths up to and
///   including the first occupied square (blocker stops further vision).
/// - Knights reveal their 8 jump squares.
/// - Kings reveal all 8 adjacent squares.
/// - Pawns reveal their two diagonal attack squares plus forward movement
///   squares (1 or 2 ahead depending on starting position).
///
/// Game logic:
/// - All moves use the full board — the engine always knows all piece positions.
/// - Visibility is a display-only filter: the board widget hides opponent pieces
///   that are on fogged squares.
/// - Check is still enforced by the engine (you must escape check even if you
///   cannot see the checking piece).
/// - En passant is available only when the opponent's pawn double-push was
///   visible (Lichess rule — we approximate this by standard en passant).
class FogOfWarChess extends ChessVariant {
  @override
  String get id => 'fog_of_war';

  @override
  String get name => 'Fog of War';

  @override
  String get description =>
      'You can only see squares your pieces attack. Move into the unknown!';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFB8D4E3);

  @override
  Color get darkSquareColor => const Color(0xFF2C3E50);

  @override
  String get rulesUrl =>
      'https://lichess.org/variant/fog-of-war';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Fog of War (Dark Chess) — limited visibility:

What you can see:
- Every square your pieces occupy
- Every square your pieces can move to or attack

What is hidden (fog):
- Opponent's pieces on squares not attacked by your pieces
- Empty squares not reachable by your pieces

Rules:
- You may move into fog — you might capture a hidden piece!
- The engine enforces check even when the checking piece is in fog
- "You are in check" is announced, but the checking piece may be hidden
- Standard chess rules otherwise (castling, en passant, promotion)

Strategy:
- Patrol with multiple piece types to expand your vision
- Develop quickly to see more of the board
- Opponent moves in fog are shown as "? moved"
''';

  // ── Board setup ──────────────────────────────────────────────────────────

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

  // ── Visibility ───────────────────────────────────────────────────────────

  /// Returns all squares visible to [color] based on their pieces' positions
  /// and attack patterns.
  @override
  Set<Position> getVisibleSquares(Board board, PieceColor color) {
    final visible = <Position>{};

    for (final (pos, piece) in board.getPieces(color)) {
      visible.add(pos); // Own square is always visible.

      if (piece.symbol == 'P') {
        _addPawnVisibility(board, pos, piece, visible);
      } else {
        // For all other pieces, use their attacked squares.
        visible.addAll(piece.getAttackedSquares(board, pos));
      }
    }

    return visible;
  }

  void _addPawnVisibility(
    Board board,
    Position pos,
    Piece piece,
    Set<Position> visible,
  ) {
    final dir = piece.color.direction; // -1 for white, +1 for black

    // Forward movement squares.
    final oneForward = Position(pos.row + dir, pos.col);
    if (oneForward.isValid(board.size)) {
      visible.add(oneForward);
      // Two squares from the starting rank (only if one-forward is empty).
      final startRow = piece.color == PieceColor.white
          ? board.size - 2
          : 1;
      if (pos.row == startRow && board.getPiece(oneForward) == null) {
        final twoForward = Position(pos.row + 2 * dir, pos.col);
        if (twoForward.isValid(board.size)) visible.add(twoForward);
      }
    }

    // Diagonal attack squares.
    for (final colOffset in [-1, 1]) {
      final diag = Position(pos.row + dir, pos.col + colOffset);
      if (diag.isValid(board.size)) visible.add(diag);
    }
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription:
              'Moves one square in any direction. Reveals all 8 adjacent squares.',
        ),
        'Q': const PieceInfo(
          name: 'Queen',
          symbol: 'Q',
          value: 9,
          movementDescription:
              'Moves any direction. Reveals long diagonals and ranks/files '
              'up to the first blocker.',
        ),
        'R': const PieceInfo(
          name: 'Rook',
          symbol: 'R',
          value: 5,
          movementDescription:
              'Moves horizontally or vertically. Excellent for revealing '
              'long ranks and files.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription:
              'Moves diagonally. Reveals diagonals up to the first blocker.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription:
              'L-shape. Reveals its 8 jump squares even through fog.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription:
              'Reveals its forward squares and diagonal attack squares.',
        ),
      };
}
