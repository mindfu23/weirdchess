import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../pieces/standard/standard_pieces.dart';
import '../pieces/compound/compound_pieces.dart';
import 'variant_base.dart';

/// Grand Chess - 10x10 variant by Christian Freeling (1984)
class GrandChess extends ChessVariant {
  @override
  String get id => 'grand_chess';

  @override
  String get name => 'Grand Chess';

  @override
  String get description =>
      '10x10 variant with Marshal (R+N) and Cardinal (B+N)';

  @override
  int get boardSize => 10;

  @override
  Color get lightSquareColor => const Color(0xFFF0D9B5);

  @override
  Color get darkSquareColor => const Color(0xFFB58863);

  @override
  String get rulesUrl => 'https://www.chessvariants.com/large.dir/grand.html';

  @override
  List<String> get promotionOptions => ['Q', 'M', 'C', 'R', 'B', 'N'];

  @override
  String get rulesSummary => '''
Grand Chess is played on a 10x10 board with two new pieces:
- Marshal (M): Combines Rook and Knight moves
- Cardinal (C): Combines Bishop and Knight moves

Setup: Pawns on 3rd rank, pieces on 1st-2nd ranks.
Pawns promote on reaching the 8th, 9th, or 10th rank.
On 8th/9th rank, promotion is optional. On 10th, mandatory.
No castling in Grand Chess.
''';

  @override
  Board createInitialBoard() {
    final board = Board(size: 10);

    // Grand Chess standard setup (chessvariants.com):
    // Rank 1 (row 9): R . . . . . . . . R (Rooks in corners)
    // Rank 2 (row 8): . N B Q C K M B N . (pieces on b-i files)
    // Rank 3 (row 7): 10 pawns

    // White back rank (row 9) - Rooks in corners
    _placePiece(board, 9, 0, Rook(color: PieceColor.white));
    _placePiece(board, 9, 9, Rook(color: PieceColor.white));

    // White 2nd rank (row 8): N B Q C K M B N on files b-i
    _placePiece(board, 8, 1, Knight(color: PieceColor.white));
    _placePiece(board, 8, 2, Bishop(color: PieceColor.white));
    _placePiece(board, 8, 3, Queen(color: PieceColor.white));
    _placePiece(board, 8, 4, Cardinal(color: PieceColor.white));
    _placePiece(board, 8, 5, King(color: PieceColor.white));
    _placePiece(board, 8, 6, Marshal(color: PieceColor.white));
    _placePiece(board, 8, 7, Bishop(color: PieceColor.white));
    _placePiece(board, 8, 8, Knight(color: PieceColor.white));

    // White pawns (row 7, rank 3)
    for (int col = 0; col < 10; col++) {
      _placePiece(board, 7, col, _createWhitePawn());
    }

    // Black pieces (mirrored)
    // Black back rank (row 0) - Rooks in corners
    _placePiece(board, 0, 0, Rook(color: PieceColor.black));
    _placePiece(board, 0, 9, Rook(color: PieceColor.black));

    // Black 2nd rank (row 1): N B Q C K M B N on files b-i
    _placePiece(board, 1, 1, Knight(color: PieceColor.black));
    _placePiece(board, 1, 2, Bishop(color: PieceColor.black));
    _placePiece(board, 1, 3, Queen(color: PieceColor.black));
    _placePiece(board, 1, 4, Cardinal(color: PieceColor.black));
    _placePiece(board, 1, 5, King(color: PieceColor.black));
    _placePiece(board, 1, 6, Marshal(color: PieceColor.black));
    _placePiece(board, 1, 7, Bishop(color: PieceColor.black));
    _placePiece(board, 1, 8, Knight(color: PieceColor.black));

    // Black pawns (row 2, rank 8)
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
        startRow: 7, // Rank 3
        promotionRow: 0, // Rank 10
        promotionOptions: promotionOptions,
      );

  Pawn _createBlackPawn() => Pawn(
        color: PieceColor.black,
        startRow: 2, // Rank 8
        promotionRow: 9, // Rank 1
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
      case 'M':
        return Marshal(color: color);
      case 'C':
        return Cardinal(color: color);
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
          movementDescription:
              'Moves any number of squares horizontally, vertically, or diagonally.',
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
          movementDescription:
              'Moves in an L-shape: 2 squares in one direction and 1 square perpendicular. Can leap over pieces.',
        ),
        'M': const PieceInfo(
          name: 'Marshal',
          symbol: 'M',
          value: 8,
          movementDescription:
              'Combines Rook and Knight. Can move like a Rook (any distance orthogonally) OR like a Knight (L-shape leap).',
        ),
        'C': const PieceInfo(
          name: 'Cardinal',
          symbol: 'C',
          value: 6,
          movementDescription:
              'Combines Bishop and Knight. Can move like a Bishop (any distance diagonally) OR like a Knight (L-shape leap).',
        ),
        'P': const PieceInfo(
          name: 'Pawn',
          symbol: 'P',
          value: 1,
          movementDescription:
              'Moves forward one square (two from starting position). Captures diagonally. Promotes on reaching the far side.',
        ),
      };
}
