import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import '../pieces/compound/compound_pieces.dart';
import 'variant_base.dart';

/// Decimal Falcon-Hunter Chess - 10x10 variant with directional pieces
class DecimalChess extends ChessVariant {
  @override
  String get id => 'decimal_chess';

  @override
  String get name => 'Decimal Chess';

  @override
  String get description =>
      '10x10 variant with Falcon and Hunter pieces';

  @override
  int get boardSize => 10;

  @override
  Color get lightSquareColor => const Color(0xFFFFF8DC); // Cornsilk

  @override
  Color get darkSquareColor => const Color(0xFF2F4F4F); // Dark slate gray

  @override
  String get rulesUrl => 'https://www.chessvariants.com/index/listcomments.php?subjectid=decimal';

  @override
  List<String> get promotionOptions => ['Q', 'Fa', 'Hu', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Decimal Falcon-Hunter Chess is a 10x10 variant with two directional pieces:

- Falcon (Fa): Moves diagonally forward (toward opponent), orthogonally backward/sideways
- Hunter (Hu): Moves orthogonally forward/sideways, diagonally backward

These asymmetric pieces change behavior based on direction, making
positional play more complex. They're worth about 5 points each.

Standard chess rules apply with these additions.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 10);

    // White pieces (bottom)
    // Row 9: R N B Fa Q K Hu B N R
    _placePiece(board, 9, 0, Rook(color: PieceColor.white));
    _placePiece(board, 9, 1, Knight(color: PieceColor.white));
    _placePiece(board, 9, 2, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 3, Falcon(color: PieceColor.white));
    _placePiece(board, 9, 4, Queen(color: PieceColor.white));
    _placePiece(board, 9, 5, King(color: PieceColor.white));
    _placePiece(board, 9, 6, Hunter(color: PieceColor.white));
    _placePiece(board, 9, 7, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 8, Knight(color: PieceColor.white));
    _placePiece(board, 9, 9, Rook(color: PieceColor.white));

    // White pawns (row 8)
    for (int col = 0; col < 10; col++) {
      _placePiece(board, 8, col, _createWhitePawn());
    }

    // Black pieces (top, mirrored)
    // Row 0: R N B Hu Q K Fa B N R (mirrored positions for Falcon/Hunter)
    _placePiece(board, 0, 0, Rook(color: PieceColor.black));
    _placePiece(board, 0, 1, Knight(color: PieceColor.black));
    _placePiece(board, 0, 2, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 3, Hunter(color: PieceColor.black));
    _placePiece(board, 0, 4, Queen(color: PieceColor.black));
    _placePiece(board, 0, 5, King(color: PieceColor.black));
    _placePiece(board, 0, 6, Falcon(color: PieceColor.black));
    _placePiece(board, 0, 7, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 8, Knight(color: PieceColor.black));
    _placePiece(board, 0, 9, Rook(color: PieceColor.black));

    // Black pawns (row 1)
    for (int col = 0; col < 10; col++) {
      _placePiece(board, 1, col, _createBlackPawn());
    }

    return board;
  }

  void _placePiece(Board board, int row, int col, Piece piece) {
    board.setPiece(Position(row, col), piece);
  }

  Pawn _createWhitePawn() => Pawn(
        color: PieceColor.white,
        startRow: 8,
        promotionRow: 0,
        promotionOptions: promotionOptions,
      );

  Pawn _createBlackPawn() => Pawn(
        color: PieceColor.black,
        startRow: 1,
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
      case 'Fa':
        return Falcon(color: color);
      case 'Hu':
        return Hunter(color: color);
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
        'Fa': const PieceInfo(
          name: 'Falcon',
          symbol: 'Fa',
          value: 5,
          movementDescription: 'Moves diagonally forward (toward enemy), orthogonally backward and sideways.',
        ),
        'Hu': const PieceInfo(
          name: 'Hunter',
          symbol: 'Hu',
          value: 5,
          movementDescription: 'Moves orthogonally forward and sideways, diagonally backward.',
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
