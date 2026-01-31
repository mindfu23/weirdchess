import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import 'variant_base.dart';

/// Standard Chess - Classic 8x8 chess
class StandardChess extends ChessVariant {
  @override
  String get id => 'standard_chess';

  @override
  String get name => 'Standard Chess';

  @override
  String get description => 'Classic 8x8 chess with standard rules';

  @override
  int get boardSize => 8;

  @override
  Color get lightSquareColor => const Color(0xFFF0D9B5);

  @override
  Color get darkSquareColor => const Color(0xFFB58863);

  @override
  String get rulesUrl => 'https://www.chess.com/learn-how-to-play-chess';

  @override
  List<String> get promotionOptions => ['Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Standard Chess is played on an 8x8 board with 16 pieces per side.

Pieces:
- King (K): Moves one square in any direction
- Queen (Q): Moves any distance horizontally, vertically, or diagonally
- Rook (R): Moves any distance horizontally or vertically
- Bishop (B): Moves any distance diagonally
- Knight (N): Moves in an L-shape (2+1 squares), can jump over pieces
- Pawn (P): Moves forward, captures diagonally

Special moves:
- Castling: King and Rook swap positions (kingside O-O or queenside O-O-O)
- En Passant: Pawn captures another pawn that just moved two squares
- Promotion: Pawn reaching the 8th rank promotes to any piece

Win by checkmate (opponent's King cannot escape capture).
Draw by stalemate, insufficient material, 50-move rule, or threefold repetition.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 8);

    // White pieces (row 7 = rank 1)
    _placePiece(board, 7, 0, Rook(color: PieceColor.white));
    _placePiece(board, 7, 1, Knight(color: PieceColor.white));
    _placePiece(board, 7, 2, Bishop(color: PieceColor.white));
    _placePiece(board, 7, 3, Queen(color: PieceColor.white));
    _placePiece(board, 7, 4, King(color: PieceColor.white));
    _placePiece(board, 7, 5, Bishop(color: PieceColor.white));
    _placePiece(board, 7, 6, Knight(color: PieceColor.white));
    _placePiece(board, 7, 7, Rook(color: PieceColor.white));

    // White pawns (row 6 = rank 2)
    for (int col = 0; col < 8; col++) {
      _placePiece(board, 6, col, _createWhitePawn());
    }

    // Black pieces (row 0 = rank 8)
    _placePiece(board, 0, 0, Rook(color: PieceColor.black));
    _placePiece(board, 0, 1, Knight(color: PieceColor.black));
    _placePiece(board, 0, 2, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 3, Queen(color: PieceColor.black));
    _placePiece(board, 0, 4, King(color: PieceColor.black));
    _placePiece(board, 0, 5, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 6, Knight(color: PieceColor.black));
    _placePiece(board, 0, 7, Rook(color: PieceColor.black));

    // Black pawns (row 1 = rank 7)
    for (int col = 0; col < 8; col++) {
      _placePiece(board, 1, col, _createBlackPawn());
    }

    return board;
  }

  void _placePiece(Board board, int row, int col, Piece piece) {
    board.setPiece(Position(row, col), piece);
  }

  Pawn _createWhitePawn() => Pawn(
        color: PieceColor.white,
        startRow: 6,
        promotionRow: 0,
        promotionOptions: promotionOptions,
      );

  Pawn _createBlackPawn() => Pawn(
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
        return color == PieceColor.white ? _createWhitePawn() : _createBlackPawn();
      default:
        throw ArgumentError('Unknown piece symbol: $symbol');
    }
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'K': const PieceInfo(
          name: 'King',
          symbol: 'K',
          value: 10000,
          movementDescription: 'Moves one square in any direction. Can castle with a Rook if neither has moved.',
        ),
        'Q': const PieceInfo(
          name: 'Queen',
          symbol: 'Q',
          value: 9,
          movementDescription: 'Moves any number of squares horizontally, vertically, or diagonally.',
        ),
        'R': const PieceInfo(
          name: 'Rook',
          symbol: 'R',
          value: 5,
          movementDescription: 'Moves any number of squares horizontally or vertically. Participates in castling.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription: 'Moves any number of squares diagonally. Stays on its starting color.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription: 'Moves in an L-shape: 2 squares in one direction and 1 square perpendicular. Can jump over pieces.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription: 'Moves forward one square (two from starting position). Captures diagonally. Promotes on the last rank.',
        ),
      };
}
