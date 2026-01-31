import 'package:flutter_test/flutter_test.dart';
import 'package:weirdchess/core/board.dart';
import 'package:weirdchess/core/move.dart';
import 'package:weirdchess/core/piece.dart';
import 'package:weirdchess/pieces/standard/standard_pieces.dart';

void main() {
  group('Board', () {
    test('creates empty board with correct size', () {
      final board = Board(size: 8);
      expect(board.size, 8);

      for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
          expect(board.getPiece(Position(row, col)), isNull);
        }
      }
    });

    test('creates 10x10 board for variants', () {
      final board = Board(size: 10);
      expect(board.size, 10);
    });

    test('setPiece and getPiece work correctly', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);

      expect(board.getPiece(Position(7, 4)), equals(king));
      expect(board.getPiece(Position(0, 0)), isNull);
    });

    test('removePiece removes and returns piece', () {
      final board = Board(size: 8);
      final queen = Queen(color: PieceColor.black);

      board.setPiece(Position(0, 3), queen);
      final removed = board.removePiece(Position(0, 3));

      expect(removed, equals(queen));
      expect(board.getPiece(Position(0, 3)), isNull);
    });

    test('makeMove moves piece correctly', () {
      final board = Board(size: 8);
      final rook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 0), rook);

      final move = Move(from: Position(7, 0), to: Position(5, 0));
      board.makeMove(move);

      expect(board.getPiece(Position(7, 0)), isNull);
      expect(board.getPiece(Position(5, 0)), equals(rook));
      expect(rook.hasMoved, isTrue);
    });

    test('makeMove handles castling', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      final rook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 4), king);
      board.setPiece(Position(7, 7), rook);

      final castlingMove = Move(
        from: Position(7, 4),
        to: Position(7, 6),
        isCastling: true,
      );
      board.makeMove(castlingMove);

      expect(board.getPiece(Position(7, 4)), isNull);
      expect(board.getPiece(Position(7, 6)), equals(king));
      expect(board.getPiece(Position(7, 5))?.symbol, 'R');
      expect(board.getPiece(Position(7, 7)), isNull);
    });

    test('makeMove handles en passant', () {
      final board = Board(size: 8);
      final whitePawn = Pawn(color: PieceColor.white, startRow: 6, promotionRow: 0);
      final blackPawn = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(3, 4), whitePawn);
      board.setPiece(Position(3, 5), blackPawn);
      board.enPassantTarget = Position(2, 5);

      final enPassantMove = Move(
        from: Position(3, 4),
        to: Position(2, 5),
        isEnPassant: true,
      );
      board.makeMove(enPassantMove);

      expect(board.getPiece(Position(2, 5)), equals(whitePawn));
      expect(board.getPiece(Position(3, 4)), isNull);
      expect(board.getPiece(Position(3, 5)), isNull); // Captured pawn removed
    });

    test('findKing returns correct position', () {
      final board = Board(size: 8);
      final whiteKing = King(color: PieceColor.white);
      final blackKing = King(color: PieceColor.black);

      board.setPiece(Position(7, 4), whiteKing);
      board.setPiece(Position(0, 4), blackKing);

      expect(board.findKing(PieceColor.white), Position(7, 4));
      expect(board.findKing(PieceColor.black), Position(0, 4));
    });

    test('isInCheck detects check correctly', () {
      final board = Board(size: 8);
      final blackKing = King(color: PieceColor.black);
      final whiteRook = Rook(color: PieceColor.white);

      board.setPiece(Position(0, 4), blackKing);
      board.setPiece(Position(7, 4), whiteRook);

      expect(board.isInCheck(PieceColor.black), isTrue);
      expect(board.isInCheck(PieceColor.white), isFalse);
    });

    test('isSquareAttacked works correctly', () {
      final board = Board(size: 8);
      final whiteRook = Rook(color: PieceColor.white);

      board.setPiece(Position(7, 0), whiteRook);

      expect(board.isSquareAttacked(Position(0, 0), PieceColor.white), isTrue);
      expect(board.isSquareAttacked(Position(7, 7), PieceColor.white), isTrue);
      expect(board.isSquareAttacked(Position(3, 3), PieceColor.white), isFalse);
    });

    test('getPieces returns all pieces of a color', () {
      final board = Board(size: 8);
      final whiteKing = King(color: PieceColor.white);
      final whiteQueen = Queen(color: PieceColor.white);
      final blackKing = King(color: PieceColor.black);

      board.setPiece(Position(7, 4), whiteKing);
      board.setPiece(Position(7, 3), whiteQueen);
      board.setPiece(Position(0, 4), blackKing);

      final whitePieces = board.getPieces(PieceColor.white);
      final blackPieces = board.getPieces(PieceColor.black);

      expect(whitePieces.length, 2);
      expect(blackPieces.length, 1);
    });

    test('copy creates independent copy', () {
      final board = Board(size: 8);
      final king = King(color: PieceColor.white);
      board.setPiece(Position(7, 4), king);

      final copy = board.copy();
      copy.removePiece(Position(7, 4));

      expect(board.getPiece(Position(7, 4)), isNotNull);
      expect(copy.getPiece(Position(7, 4)), isNull);
    });

    test('clear removes all pieces', () {
      final board = Board(size: 8);
      board.setPiece(Position(0, 0), King(color: PieceColor.white));
      board.setPiece(Position(7, 7), King(color: PieceColor.black));
      board.enPassantTarget = Position(3, 4);

      board.clear();

      expect(board.getPiece(Position(0, 0)), isNull);
      expect(board.getPiece(Position(7, 7)), isNull);
      expect(board.enPassantTarget, isNull);
    });
  });

  group('Position', () {
    test('equality works correctly', () {
      expect(Position(3, 4), Position(3, 4));
      expect(Position(3, 4), isNot(Position(4, 3)));
    });

    test('addition works correctly', () {
      final pos = Position(3, 4) + Position(1, 2);
      expect(pos.row, 4);
      expect(pos.col, 6);
    });

    test('subtraction works correctly', () {
      final pos = Position(5, 5) - Position(2, 1);
      expect(pos.row, 3);
      expect(pos.col, 4);
    });

    test('scalar multiplication works correctly', () {
      final pos = Position(2, 3) * 2;
      expect(pos.row, 4);
      expect(pos.col, 6);
    });

    test('isValid checks bounds correctly', () {
      expect(Position(0, 0).isValid(8), isTrue);
      expect(Position(7, 7).isValid(8), isTrue);
      expect(Position(-1, 0).isValid(8), isFalse);
      expect(Position(8, 0).isValid(8), isFalse);
      expect(Position(0, 8).isValid(8), isFalse);
    });

    test('toAlgebraic converts correctly for 8x8', () {
      expect(Position(7, 0).toAlgebraic(8), 'a1');
      expect(Position(0, 7).toAlgebraic(8), 'h8');
      expect(Position(6, 4).toAlgebraic(8), 'e2');
    });

    test('toAlgebraic converts correctly for 10x10', () {
      expect(Position(9, 0).toAlgebraic(10), 'a1');
      expect(Position(0, 9).toAlgebraic(10), 'j10');
      expect(Position(7, 4).toAlgebraic(10), 'e3');
    });

    test('fromAlgebraic parses correctly', () {
      expect(Position.fromAlgebraic('a1', 8), Position(7, 0));
      expect(Position.fromAlgebraic('h8', 8), Position(0, 7));
      expect(Position.fromAlgebraic('e2', 8), Position(6, 4));
    });
  });

  group('Move', () {
    test('equality works correctly', () {
      final m1 = Move(from: Position(6, 4), to: Position(4, 4));
      final m2 = Move(from: Position(6, 4), to: Position(4, 4));
      expect(m1, m2);
    });

    test('toAlgebraic formats correctly', () {
      final move = Move(from: Position(6, 4), to: Position(4, 4));
      expect(move.toAlgebraic(8), 'e2-e4');

      final capture = Move(from: Position(5, 3), to: Position(4, 4), isCapture: true);
      expect(capture.toAlgebraic(8), 'd3xe4');

      final promotion = Move(
        from: Position(1, 4),
        to: Position(0, 4),
        promotionPiece: 'Q',
      );
      expect(promotion.toAlgebraic(8), 'e7-e8=Q');
    });
  });
}
