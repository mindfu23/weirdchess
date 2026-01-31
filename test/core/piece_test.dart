import 'package:flutter_test/flutter_test.dart';
import 'package:weirdchess/core/board.dart';
import 'package:weirdchess/core/move.dart';
import 'package:weirdchess/core/piece.dart';
import 'package:weirdchess/pieces/standard/standard_pieces.dart';
import 'package:weirdchess/pieces/compound/compound_pieces.dart';

void main() {
  group('Pawn', () {
    test('can move one square forward', () {
      final board = Board(size: 8);
      final pawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      pawn.hasMoved = true;
      board.setPiece(Position(5, 4), pawn);

      final moves = pawn.getPseudoLegalMoves(board, Position(5, 4));

      expect(moves.any((m) => m.to == Position(4, 4)), isTrue);
    });

    test('can move two squares from starting position', () {
      final board = Board(size: 8);
      final pawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      board.setPiece(Position(6, 4), pawn);

      final moves = pawn.getPseudoLegalMoves(board, Position(6, 4));

      expect(moves.any((m) => m.to == Position(4, 4)), isTrue);
      expect(moves.any((m) => m.to == Position(5, 4)), isTrue);
    });

    test('can capture diagonally', () {
      final board = Board(size: 8);
      final whitePawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      final blackPawn = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(4, 4), whitePawn);
      board.setPiece(Position(3, 5), blackPawn);

      final moves = whitePawn.getPseudoLegalMoves(board, Position(4, 4));

      expect(moves.any((m) => m.to == Position(3, 5) && m.isCapture), isTrue);
    });

    test('generates promotion moves', () {
      final board = Board(size: 8);
      final pawn = Pawn(
        color: PieceColor.white,
        startRow: 6,
        promotionRow: 0,
        promotionOptions: ['Q', 'R', 'B', 'N'],
      );
      board.setPiece(Position(1, 4), pawn);

      final moves = pawn.getPseudoLegalMoves(board, Position(1, 4));

      expect(moves.where((m) => m.promotionPiece != null).length, 4);
      expect(moves.any((m) => m.promotionPiece == 'Q'), isTrue);
      expect(moves.any((m) => m.promotionPiece == 'N'), isTrue);
    });

    test('can capture en passant', () {
      final board = Board(size: 8);
      final whitePawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      final blackPawn = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(3, 4), whitePawn);
      board.setPiece(Position(3, 5), blackPawn);
      board.enPassantTarget = Position(2, 5);

      final moves = whitePawn.getPseudoLegalMoves(board, Position(3, 4));

      expect(moves.any((m) => m.to == Position(2, 5) && m.isEnPassant), isTrue);
    });

    test('cannot move through pieces', () {
      final board = Board(size: 8);
      final whitePawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      final blocker = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(6, 4), whitePawn);
      board.setPiece(Position(5, 4), blocker);

      final moves = whitePawn.getPseudoLegalMoves(board, Position(6, 4));

      expect(moves.isEmpty, isTrue);
    });
  });

  group('Knight', () {
    test('moves in L-shape', () {
      final board = Board(size: 8);
      final knight = Knight(color: PieceColor.white);
      board.setPiece(Position(4, 4), knight);

      final moves = knight.getPseudoLegalMoves(board, Position(4, 4));

      expect(moves.length, 8);
      expect(moves.any((m) => m.to == Position(2, 3)), isTrue);
      expect(moves.any((m) => m.to == Position(2, 5)), isTrue);
      expect(moves.any((m) => m.to == Position(3, 2)), isTrue);
      expect(moves.any((m) => m.to == Position(3, 6)), isTrue);
      expect(moves.any((m) => m.to == Position(5, 2)), isTrue);
      expect(moves.any((m) => m.to == Position(5, 6)), isTrue);
      expect(moves.any((m) => m.to == Position(6, 3)), isTrue);
      expect(moves.any((m) => m.to == Position(6, 5)), isTrue);
    });

    test('can jump over pieces', () {
      final board = Board(size: 8);
      final knight = Knight(color: PieceColor.white);
      board.setPiece(Position(7, 1), knight);

      // Surround with pawns - knight can jump over them
      board.setPiece(Position(6, 0), Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0));
      board.setPiece(Position(6, 1), Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0));
      board.setPiece(Position(6, 2), Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0));

      final moves = knight.getPseudoLegalMoves(board, Position(7, 1));

      // Knight at b1 can reach: a3 (5,0), c3 (5,2), and d2 (6,3)
      expect(moves.length, 3);
      expect(moves.any((m) => m.to == Position(5, 0)), isTrue);
      expect(moves.any((m) => m.to == Position(5, 2)), isTrue);
      expect(moves.any((m) => m.to == Position(6, 3)), isTrue);
    });

    test('fewer moves in corner', () {
      final board = Board(size: 8);
      final knight = Knight(color: PieceColor.white);
      board.setPiece(Position(0, 0), knight);

      final moves = knight.getPseudoLegalMoves(board, Position(0, 0));

      expect(moves.length, 2);
    });
  });

  group('Bishop', () {
    test('moves diagonally', () {
      final board = Board(size: 8);
      final bishop = Bishop(color: PieceColor.white);
      board.setPiece(Position(4, 4), bishop);

      final moves = bishop.getPseudoLegalMoves(board, Position(4, 4));

      // Should have 13 diagonal squares (4+4+3+2)
      expect(moves.length, 13);
      expect(moves.any((m) => m.to == Position(0, 0)), isTrue);
      expect(moves.any((m) => m.to == Position(7, 7)), isTrue);
    });

    test('blocked by pieces', () {
      final board = Board(size: 8);
      final bishop = Bishop(color: PieceColor.white);
      final blocker = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);

      board.setPiece(Position(4, 4), bishop);
      board.setPiece(Position(3, 3), blocker);

      final moves = bishop.getPseudoLegalMoves(board, Position(4, 4));

      expect(moves.any((m) => m.to == Position(3, 3)), isFalse);
      expect(moves.any((m) => m.to == Position(2, 2)), isFalse);
    });

    test('can capture enemy pieces', () {
      final board = Board(size: 8);
      final bishop = Bishop(color: PieceColor.white);
      final enemy = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(4, 4), bishop);
      board.setPiece(Position(2, 2), enemy);

      final moves = bishop.getPseudoLegalMoves(board, Position(4, 4));

      expect(moves.any((m) => m.to == Position(2, 2) && m.isCapture), isTrue);
      expect(moves.any((m) => m.to == Position(1, 1)), isFalse);
    });
  });

  group('Rook', () {
    test('moves horizontally and vertically', () {
      final board = Board(size: 8);
      final rook = Rook(color: PieceColor.white);
      board.setPiece(Position(4, 4), rook);

      final moves = rook.getPseudoLegalMoves(board, Position(4, 4));

      // 7 horizontal + 7 vertical = 14
      expect(moves.length, 14);
      expect(moves.any((m) => m.to == Position(0, 4)), isTrue);
      expect(moves.any((m) => m.to == Position(7, 4)), isTrue);
      expect(moves.any((m) => m.to == Position(4, 0)), isTrue);
      expect(moves.any((m) => m.to == Position(4, 7)), isTrue);
    });
  });

  group('Queen', () {
    test('moves like rook and bishop combined', () {
      final board = Board(size: 8);
      final queen = Queen(color: PieceColor.white);
      board.setPiece(Position(4, 4), queen);

      final moves = queen.getPseudoLegalMoves(board, Position(4, 4));

      // 14 orthogonal + 13 diagonal = 27
      expect(moves.length, 27);
    });
  });

  group('King', () {
    test('moves one square in any direction', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      board.setPiece(Position(4, 4), king);

      final moves = king.getPseudoLegalMoves(board, Position(4, 4));

      expect(moves.length, 8);
    });

    test('can castle kingside', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      final rook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);
      board.setPiece(Position(7, 7), rook);

      final moves = king.getPseudoLegalMoves(board, Position(7, 4));

      expect(moves.any((m) => m.to == Position(7, 6) && m.isCastling), isTrue);
    });

    test('can castle queenside', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      final rook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);
      board.setPiece(Position(7, 0), rook);

      final moves = king.getPseudoLegalMoves(board, Position(7, 4));

      expect(moves.any((m) => m.to == Position(7, 2) && m.isCastling), isTrue);
    });

    test('cannot castle if king has moved', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      king.hasMoved = true;
      final rook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);
      board.setPiece(Position(7, 7), rook);

      final moves = king.getPseudoLegalMoves(board, Position(7, 4));

      expect(moves.any((m) => m.isCastling), isFalse);
    });

    test('cannot castle through pieces', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      final rook = Rook(color: PieceColor.white);
      final blocker = Bishop(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);
      board.setPiece(Position(7, 7), rook);
      board.setPiece(Position(7, 5), blocker);

      final moves = king.getPseudoLegalMoves(board, Position(7, 4));

      expect(moves.any((m) => m.to == Position(7, 6) && m.isCastling), isFalse);
    });
  });

  group('Compound Pieces', () {
    test('Marshal moves like rook or knight', () {
      final board = Board(size: 10);
      final marshal = Marshal(color: PieceColor.white);
      board.setPiece(Position(5, 5), marshal);

      final moves = marshal.getPseudoLegalMoves(board, Position(5, 5));

      // Should have rook moves + knight moves
      expect(moves.length > 18, isTrue);
      // Knight move
      expect(moves.any((m) => m.to == Position(3, 4)), isTrue);
      // Rook move
      expect(moves.any((m) => m.to == Position(0, 5)), isTrue);
    });

    test('Cardinal moves like bishop or knight', () {
      final board = Board(size: 10);
      final cardinal = Cardinal(color: PieceColor.white);
      board.setPiece(Position(5, 5), cardinal);

      final moves = cardinal.getPseudoLegalMoves(board, Position(5, 5));

      // Should have bishop moves + knight moves
      expect(moves.length > 15, isTrue);
      // Knight move
      expect(moves.any((m) => m.to == Position(3, 4)), isTrue);
      // Bishop move
      expect(moves.any((m) => m.to == Position(0, 0)), isTrue);
    });
  });

  group('Legal Moves', () {
    test('filters out moves that leave king in check', () {
      final board = Board(size: 8);
      final whiteKing = King(color: PieceColor.white);
      final whiteRook = Rook(color: PieceColor.white);
      final blackRook = Rook(color: PieceColor.black);

      // White king on e1 (7,4), white rook on e2 (6,4) pinned by black rook on e8 (0,4)
      // The rook is pinned along the e-file
      board.setPiece(Position(7, 4), whiteKing);
      board.setPiece(Position(6, 4), whiteRook);
      board.setPiece(Position(0, 4), blackRook);

      final pseudoLegal = whiteRook.getPseudoLegalMoves(board, Position(6, 4));
      final legal = whiteRook.getLegalMoves(board, Position(6, 4));

      expect(pseudoLegal.length > 0, isTrue);
      // White rook can only move along the e-file (column 4), not horizontally
      // Horizontal moves would expose king to check
      expect(legal.length < pseudoLegal.length, isTrue);
      // All legal moves should be on column 4
      expect(legal.every((m) => m.to.col == 4), isTrue);
    });
  });
}
