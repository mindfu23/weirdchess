import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import '../pieces/compound/compound_pieces.dart';
import 'variant_base.dart';

/// Omega Chess - Commercial variant with Champion and Wizard pieces
/// Note: The original has 4 corner "wizard squares" but this version uses standard 10x10
class OmegaChess extends ChessVariant {
  @override
  String get id => 'omega_chess';

  @override
  String get name => 'Omega Chess';

  @override
  String get description =>
      '10x10 variant with Champion and Wizard pieces';

  @override
  int get boardSize => 10;

  @override
  Color get lightSquareColor => const Color(0xFFE8E8E8); // Light gray

  @override
  Color get darkSquareColor => const Color(0xFF4A4A4A); // Dark gray

  @override
  String get rulesUrl => 'https://www.chessvariants.com/large.dir/omega.html';

  @override
  List<String> get promotionOptions => ['Q', 'Ch', 'W', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Omega Chess is a commercial 10x10 variant with two new pieces:

- Champion (Ch): Leaps 1 or 2 squares orthogonally, or 2 squares diagonally
- Wizard (W): Leaps 1 square diagonally, or makes a (3,1) camel leap

The original game has 4 extra corner squares for Wizards, but this
version uses a standard 10x10 board with Wizards starting in the corners.

Standard chess rules apply with these additions.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 10);

    // White pieces (bottom)
    // Row 9: W R N B Q K B N R W
    _placePiece(board, 9, 0, Wizard(color: PieceColor.white));
    _placePiece(board, 9, 1, Rook(color: PieceColor.white));
    _placePiece(board, 9, 2, Knight(color: PieceColor.white));
    _placePiece(board, 9, 3, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 4, Queen(color: PieceColor.white));
    _placePiece(board, 9, 5, King(color: PieceColor.white));
    _placePiece(board, 9, 6, Bishop(color: PieceColor.white));
    _placePiece(board, 9, 7, Knight(color: PieceColor.white));
    _placePiece(board, 9, 8, Rook(color: PieceColor.white));
    _placePiece(board, 9, 9, Wizard(color: PieceColor.white));

    // Row 8: Ch P P P P P P P P Ch
    _placePiece(board, 8, 0, Champion(color: PieceColor.white));
    for (int col = 1; col <= 8; col++) {
      _placePiece(board, 8, col, _createWhitePawn());
    }
    _placePiece(board, 8, 9, Champion(color: PieceColor.white));

    // Black pieces (top, mirrored)
    // Row 0: W R N B Q K B N R W
    _placePiece(board, 0, 0, Wizard(color: PieceColor.black));
    _placePiece(board, 0, 1, Rook(color: PieceColor.black));
    _placePiece(board, 0, 2, Knight(color: PieceColor.black));
    _placePiece(board, 0, 3, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 4, Queen(color: PieceColor.black));
    _placePiece(board, 0, 5, King(color: PieceColor.black));
    _placePiece(board, 0, 6, Bishop(color: PieceColor.black));
    _placePiece(board, 0, 7, Knight(color: PieceColor.black));
    _placePiece(board, 0, 8, Rook(color: PieceColor.black));
    _placePiece(board, 0, 9, Wizard(color: PieceColor.black));

    // Row 1: Ch P P P P P P P P Ch
    _placePiece(board, 1, 0, Champion(color: PieceColor.black));
    for (int col = 1; col <= 8; col++) {
      _placePiece(board, 1, col, _createBlackPawn());
    }
    _placePiece(board, 1, 9, Champion(color: PieceColor.black));

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
      case 'Ch':
        return Champion(color: color);
      case 'W':
        return Wizard(color: color);
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
        'Ch': const PieceInfo(
          name: 'Champion',
          symbol: 'Ch',
          value: 4,
          movementDescription: 'Leaps 1 or 2 squares orthogonally, or 2 squares diagonally. Jumps over pieces.',
        ),
        'W': const PieceInfo(
          name: 'Wizard',
          symbol: 'W',
          value: 4,
          movementDescription: 'Leaps 1 square diagonally, or makes a (3,1) camel leap. Jumps over pieces.',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription: 'Moves forward one square (two from start). Captures diagonally.',
        ),
      };
}
