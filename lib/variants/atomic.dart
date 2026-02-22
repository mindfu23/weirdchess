import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_result.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Atomic Chess — captures cause explosions.
///
/// Rules:
/// - When a piece is captured, an explosion occurs at the capture square.
/// - The explosion destroys: the capturing piece, the captured piece, and all
///   non-pawn pieces on the 8 surrounding squares.
/// - Pawns are immune to explosion blast (only destroyed by direct capture).
/// - A king caught in an explosion loses the game immediately.
/// - There is no traditional "check" — you win by exploding the opponent's king.
/// - You may NOT make a capture that would also explode your own king.
/// - Non-capture moves have no explosion and follow standard legality.
/// - En passant: explosion is centered on the captured pawn's square.
class AtomicChess extends ChessVariant {
  @override
  String get id => 'atomic';

  @override
  String get name => 'Atomic Chess';

  @override
  String get description =>
      'Captures explode! Destroy the opponent\'s king to win.';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFF5DEB3);

  @override
  Color get darkSquareColor => const Color(0xFFCD853F);

  @override
  String get rulesUrl =>
      'https://www.chess.com/variants/atomic';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Atomic Chess uses the standard starting position with explosive rules:

Captures:
- Every capture triggers a 3×3 explosion at the capture square
- The explosion destroys: the capturer, all non-pawn pieces in the blast zone
- Pawns survive explosions (but are destroyed by direct pawn captures)
- En passant: the explosion centres on the captured pawn's square

Win condition:
- Explode the opponent's king (no traditional checkmate)

Illegal moves:
- Any capture that would also explode your own king

Note: You CAN move into positions where your king could be captured, because
the opponent capturing your king would also destroy their capturing piece.
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

  /// Atomic legal move generation:
  /// - Non-capture moves: always legal (no traditional check restriction).
  /// - Capture moves: only legal if the explosion does NOT destroy own king.
  @override
  List<Move> getLegalMoves(Board board, Position pos, Piece piece) {
    final pseudoLegal = piece.getPseudoLegalMoves(board, pos);

    return pseudoLegal.where((move) {
      if (!move.isCapture) {
        // Non-captures are always legal in Atomic.
        return true;
      }
      // For captures, simulate explosion and check that own king survives.
      final testBoard = board.copy();
      testBoard.makeMove(move);
      _applyExplosionToBoard(testBoard, move);
      return testBoard.findKing(piece.color) != null;
    }).toList();
  }

  /// Apply the explosion to the board and return all destroyed pieces
  /// (for MoveRecord so undo can restore them).
  @override
  List<(Position, Piece)> applyPostCaptureEffect(Board board, Move move) {
    return _applyExplosionToBoard(board, move);
  }

  /// Shared explosion logic used by both [getLegalMoves] (simulation) and
  /// [applyPostCaptureEffect] (real application).
  List<(Position, Piece)> _applyExplosionToBoard(Board board, Move move) {
    final casualties = <(Position, Piece)>[];

    Position explosionCenter;
    bool removeCenter;

    if (move.isEnPassant) {
      // Explosion is centred on the captured pawn's square (not move.to).
      // The captured pawn is already removed by board.makeMove(); the
      // capturing pawn (a pawn) survives since pawns are blast-immune.
      explosionCenter = Position(move.from.row, move.to.col);
      removeCenter = false;
    } else {
      // Regular capture: explosion at the capture square.
      // The capturing piece (now at move.to) is also destroyed.
      explosionCenter = move.to;
      removeCenter = true;
    }

    if (removeCenter) {
      final capturer = board.removePiece(explosionCenter);
      if (capturer != null) casualties.add((explosionCenter, capturer));
    }

    // Destroy all non-pawn pieces in the 8 surrounding squares.
    for (final dir in Direction.all) {
      final pos = explosionCenter + dir;
      if (!pos.isValid(board.size)) continue;
      final p = board.getPiece(pos);
      if (p != null && p.symbol != 'P') {
        board.removePiece(pos);
        casualties.add((pos, p));
      }
    }

    return casualties;
  }

  /// Win by exploding the opponent's king; draw if both kings explode.
  /// This overrides any stalemate result set by _updateGameResult when all
  /// pieces are gone after an explosion.
  @override
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  ) {
    final whiteKingExists = board.findKing(PieceColor.white) != null;
    final blackKingExists = board.findKing(PieceColor.black) != null;

    if (!whiteKingExists && !blackKingExists) return GameResult.draw;
    if (!whiteKingExists) return GameResult.blackWins;
    if (!blackKingExists) return GameResult.whiteWins;

    return null;
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription:
              'Moves one square in any direction. Cannot be captured safely — '
              'any capture would also destroy the capturing piece.',
        ),
        'Q': const PieceInfo(
          name: 'Queen',
          symbol: 'Q',
          value: 9,
          movementDescription:
              'Moves any number of squares in any direction. '
              'Capturing triggers an explosion!',
        ),
        'R': const PieceInfo(
          name: 'Rook',
          symbol: 'R',
          value: 5,
          movementDescription:
              'Moves horizontally or vertically. Captures explode.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription:
              'Moves diagonally. Captures explode.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription:
              'L-shape mover, jumps over pieces. Captures explode.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription:
              'Moves forward, captures diagonally. '
              'Immune to explosion blast — only dies by direct capture.',
        ),
      };
}
