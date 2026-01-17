import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import '../pieces/compound/compound_pieces.dart';
import 'variant_base.dart';

/// Hyderabad Decimal Chess - 18th century Indian variant
class HyderabadChess extends ChessVariant {
  @override
  String get id => 'hyderabad_chess';

  @override
  String get name => 'Hyderabad Decimal';

  @override
  String get description =>
      '10x10 Indian variant with Wazir, Zurafa, and Dabbaba';

  @override
  int get boardSize => 10;

  @override
  Color get lightSquareColor => const Color(0xFFF5DEB3); // Wheat

  @override
  Color get darkSquareColor => const Color(0xFF8B4513); // Saddle brown

  @override
  String get rulesUrl => 'https://www.chessvariants.com/historic.dir/indiangr.html';

  @override
  List<String> get promotionOptions => ['Z', 'W', 'D', 'Q', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Hyderabad Decimal Chess is an 18th-century Indian variant on a 10x10 board.

Special pieces:
- Zurafa (Z): Queen + Knight combined (Amazon)
- Wazir (W): Bishop + Knight combined (Cardinal)
- Dabbaba (D): Rook + Knight combined (Marshal)

The game uses standard chess rules with these compound pieces added.
Pawns promote on the last rank to any piece except King.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 10);

    // White pieces (bottom)
    // Row 9 (rank 1): R D B Q Z K W B D R
    _placePiece(board, 9, 0, Rook(color: PieceColor.white));
    _placePiece(board, 9, 1, Marshal(color: PieceColor.white)); // Dabbaba
    _placePiece(board, 9, 2, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 3, Queen(color: PieceColor.white));
    _placePiece(board, 9, 4, Amazon(color: PieceColor.white)); // Zurafa
    _placePiece(board, 9, 5, King(color: PieceColor.white));
    _placePiece(board, 9, 6, Cardinal(color: PieceColor.white)); // Wazir
    _placePiece(board, 9, 7, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 8, Marshal(color: PieceColor.white)); // Dabbaba
    _placePiece(board, 9, 9, Rook(color: PieceColor.white));

    // White knights on row 8
    _placePiece(board, 8, 1, Knight(color: PieceColor.white));
    _placePiece(board, 8, 8, Knight(color: PieceColor.white));

    // White pawns (row 7)
    for (int col = 0; col < 10; col++) {
      _placePiece(board, 7, col, _createWhitePawn());
    }

    // Black pieces (top, mirrored)
    _placePiece(board, 0, 0, Rook(color: PieceColor.black));
    _placePiece(board, 0, 1, Marshal(color: PieceColor.black)); // Dabbaba
    _placePiece(board, 0, 2, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 3, Queen(color: PieceColor.black));
    _placePiece(board, 0, 4, Amazon(color: PieceColor.black)); // Zurafa
    _placePiece(board, 0, 5, King(color: PieceColor.black));
    _placePiece(board, 0, 6, Cardinal(color: PieceColor.black)); // Wazir
    _placePiece(board, 0, 7, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 8, Marshal(color: PieceColor.black)); // Dabbaba
    _placePiece(board, 0, 9, Rook(color: PieceColor.black));

    // Black knights on row 1
    _placePiece(board, 1, 1, Knight(color: PieceColor.black));
    _placePiece(board, 1, 8, Knight(color: PieceColor.black));

    // Black pawns (row 2)
    for (int col = 0; col < 10; col++) {
      _placePiece(board, 2, col, _createBlackPawn());
    }

    return board;
  }

  void _placePiece(Board board, int row, int col, Piece piece) {
    board.setPiece(Position(row, col), piece);
  }

  Pawn _createWhitePawn() => Pawn(
        color: PieceColor.white,
        startRow: 7,
        promotionRow: 0,
        promotionOptions: promotionOptions,
      );

  Pawn _createBlackPawn() => Pawn(
        color: PieceColor.black,
        startRow: 2,
        promotionRow: 9,
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
      case 'Z': // Zurafa (Amazon)
      case 'A':
        return Amazon(color: color);
      case 'W': // Wazir (Cardinal)
      case 'C':
        return Cardinal(color: color);
      case 'D': // Dabbaba (Marshal)
      case 'M':
        return Marshal(color: color);
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
          movementDescription: 'Moves one square in any direction.',
        ),
        'Q': const PieceInfo(
          name: 'Queen',
          symbol: 'Q',
          value: 9,
          movementDescription: 'Moves any distance horizontally, vertically, or diagonally.',
        ),
        'A': const PieceInfo(
          name: 'Zurafa (Giraffe)',
          symbol: 'Z',
          value: 12,
          movementDescription: 'Queen + Knight. Moves like a Queen OR leaps like a Knight.',
        ),
        'C': const PieceInfo(
          name: 'Wazir',
          symbol: 'W',
          value: 6,
          movementDescription: 'Bishop + Knight. Moves diagonally any distance OR leaps like a Knight.',
        ),
        'M': const PieceInfo(
          name: 'Dabbaba',
          symbol: 'D',
          value: 8,
          movementDescription: 'Rook + Knight. Moves orthogonally any distance OR leaps like a Knight.',
        ),
        'R': const PieceInfo(
          name: 'Rook',
          symbol: 'R',
          value: 5,
          movementDescription: 'Moves any distance horizontally or vertically.',
        ),
        'B': const PieceInfo(
          name: 'Bishop',
          symbol: 'B',
          value: 3,
          movementDescription: 'Moves any distance diagonally.',
        ),
        'N': const PieceInfo(
          name: 'Knight',
          symbol: 'N',
          value: 3,
          movementDescription: 'Leaps in an L-shape: 2 squares + 1 square perpendicular.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription: 'Moves forward one square (two from start). Captures diagonally.',
        ),
      };
}
