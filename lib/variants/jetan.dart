import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/jetan/jetan_pieces.dart';
import 'variant_base.dart';

/// Jetan (Barsoomian Chess) - from Edgar Rice Burroughs' "The Chessmen of Mars"
class Jetan extends ChessVariant {
  @override
  String get id => 'jetan';

  @override
  String get name => 'Jetan';

  @override
  String get description =>
      'Barsoomian chess from Mars with unique warrior pieces';

  @override
  int get boardSize => 10;

  @override
  Color get lightSquareColor => const Color(0xFFFF8C00); // Dark orange

  @override
  Color get darkSquareColor => const Color(0xFF1A1A1A); // Near black

  @override
  String get rulesUrl => 'https://www.chessvariants.com/fictional.dir/jetan.html';

  @override
  List<String> get promotionOptions => ['Pr', 'Fl', 'Dw', 'Pd', 'Wa', 'Th'];

  @override
  String get rulesSummary => '''
Jetan is Barsoomian (Martian) chess from Edgar Rice Burroughs' novels.

Piece movement (squares in given direction):
- Chief (Cf): 3 squares any direction - capture ends game
- Princess (Pr): 3 squares any direction
- Flier (Fl): 3 squares diagonal
- Dwar (Dw): 3 squares orthogonal
- Padwar (Pd): 2 squares diagonal
- Warrior (Wa): 2 squares orthogonal
- Thoat (Th): 2 squares any direction OR knight leap
- Panthan (Pa): 1 square any direction

Win by capturing the opponent's Chief or reaching their back rank with your Princess.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 10);

    // Orange (White equivalent) - bottom
    // Row 9: Wa Pd Dw Fl Cf Pr Fl Dw Pd Wa
    _placePiece(board, 9, 0, Warrior(color: PieceColor.white));
    _placePiece(board, 9, 1, Padwar(color: PieceColor.white));
    _placePiece(board, 9, 2, Dwar(color: PieceColor.white));
    _placePiece(board, 9, 3, Flier(color: PieceColor.white));
    _placePiece(board, 9, 4, Chief(color: PieceColor.white));
    _placePiece(board, 9, 5, Princess(color: PieceColor.white));
    _placePiece(board, 9, 6, Flier(color: PieceColor.white));
    _placePiece(board, 9, 7, Dwar(color: PieceColor.white));
    _placePiece(board, 9, 8, Padwar(color: PieceColor.white));
    _placePiece(board, 9, 9, Warrior(color: PieceColor.white));

    // Row 8: Th Pa Pa Pa Pa Pa Pa Pa Pa Th
    _placePiece(board, 8, 0, Thoat(color: PieceColor.white));
    for (int col = 1; col <= 8; col++) {
      _placePiece(board, 8, col, Panthan(color: PieceColor.white));
    }
    _placePiece(board, 8, 9, Thoat(color: PieceColor.white));

    // Black - top (mirrored)
    // Row 0: Wa Pd Dw Fl Pr Cf Fl Dw Pd Wa (Princess and Chief swapped for black)
    _placePiece(board, 0, 0, Warrior(color: PieceColor.black));
    _placePiece(board, 0, 1, Padwar(color: PieceColor.black));
    _placePiece(board, 0, 2, Dwar(color: PieceColor.black));
    _placePiece(board, 0, 3, Flier(color: PieceColor.black));
    _placePiece(board, 0, 4, Princess(color: PieceColor.black));
    _placePiece(board, 0, 5, Chief(color: PieceColor.black));
    _placePiece(board, 0, 6, Flier(color: PieceColor.black));
    _placePiece(board, 0, 7, Dwar(color: PieceColor.black));
    _placePiece(board, 0, 8, Padwar(color: PieceColor.black));
    _placePiece(board, 0, 9, Warrior(color: PieceColor.black));

    // Row 1: Th Pa Pa Pa Pa Pa Pa Pa Pa Th
    _placePiece(board, 1, 0, Thoat(color: PieceColor.black));
    for (int col = 1; col <= 8; col++) {
      _placePiece(board, 1, col, Panthan(color: PieceColor.black));
    }
    _placePiece(board, 1, 9, Thoat(color: PieceColor.black));

    return board;
  }

  void _placePiece(Board board, int row, int col, Piece piece) {
    board.setPiece(Position(row, col), piece);
  }

  @override
  Piece createPiece(String symbol, PieceColor color) {
    switch (symbol) {
      case 'Cf':
        return Chief(color: color);
      case 'Pr':
        return Princess(color: color);
      case 'Fl':
        return Flier(color: color);
      case 'Dw':
        return Dwar(color: color);
      case 'Pd':
        return Padwar(color: color);
      case 'Wa':
        return Warrior(color: color);
      case 'Th':
        return Thoat(color: color);
      case 'Pa':
        return Panthan(color: color);
      default:
        throw ArgumentError('Unknown piece symbol: $symbol');
    }
  }

  @override
  Map<String, PieceInfo> get pieceInfo => {
        'Cf': const PieceInfo(
          name: 'Chief',
          symbol: 'Cf',
          value: 10000,
          movementDescription: 'Moves up to 3 squares in any direction. Capture ends the game.',
        ),
        'Pr': const PieceInfo(
          name: 'Princess',
          symbol: 'Pr',
          value: 9,
          movementDescription: 'Moves up to 3 squares in any direction. Reaching enemy back rank wins.',
        ),
        'Fl': const PieceInfo(
          name: 'Flier',
          symbol: 'Fl',
          value: 5,
          movementDescription: 'Moves up to 3 squares diagonally.',
        ),
        'Dw': const PieceInfo(
          name: 'Dwar',
          symbol: 'Dw',
          value: 5,
          movementDescription: 'Moves up to 3 squares orthogonally (horizontal/vertical).',
        ),
        'Pd': const PieceInfo(
          name: 'Padwar',
          symbol: 'Pd',
          value: 3,
          movementDescription: 'Moves up to 2 squares diagonally.',
        ),
        'Wa': const PieceInfo(
          name: 'Warrior',
          symbol: 'Wa',
          value: 3,
          movementDescription: 'Moves up to 2 squares orthogonally.',
        ),
        'Th': const PieceInfo(
          name: 'Thoat',
          symbol: 'Th',
          value: 4,
          movementDescription: 'Moves up to 2 squares any direction OR leaps like a Knight.',
        ),
        'Pa': const PieceInfo(
          name: 'Panthan',
          symbol: 'Pa',
          value: 1,
          movementDescription: 'Moves 1 square in any direction (like a King).',
        ),
      };
}
