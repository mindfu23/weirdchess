import 'package:flutter_test/flutter_test.dart';
import 'package:weirdchess/core/board.dart';
import 'package:weirdchess/core/game_state.dart';
import 'package:weirdchess/core/move.dart';
import 'package:weirdchess/core/piece.dart';
import 'package:weirdchess/pieces/standard/standard_pieces.dart';
import 'package:weirdchess/variants/standard_chess.dart';
import 'package:weirdchess/variants/grand_chess.dart';

void main() {
  group('GameState', () {
    test('creates with initial board', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      expect(state.currentTurn, PieceColor.white);
      expect(state.result, GameResult.ongoing);
      expect(state.moveHistory.isEmpty, isTrue);
      expect(state.fullMoveNumber, 1);
      expect(state.halfMoveClock, 0);
    });

    test('makeMove updates turn', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      final move = Move(from: Position(6, 4), to: Position(4, 4));
      final success = state.makeMove(move);

      expect(success, isTrue);
      expect(state.currentTurn, PieceColor.black);
    });

    test('makeMove rejects illegal moves', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      // Try to move rook on first move (blocked by pawn)
      final move = Move(from: Position(7, 0), to: Position(5, 0));
      final success = state.makeMove(move);

      expect(success, isFalse);
      expect(state.currentTurn, PieceColor.white);
    });

    test('makeMove tracks captured pieces', () {
      final board = Board(size: 8);
      final whiteKing = King(color: PieceColor.white);
      final whiteQueen = Queen(color: PieceColor.white);
      final blackKing = King(color: PieceColor.black);
      final blackPawn = Pawn(color: PieceColor.black, startRow: 1, promotionRow: 7);

      board.setPiece(Position(7, 4), whiteKing);
      board.setPiece(Position(4, 4), whiteQueen);
      board.setPiece(Position(0, 4), blackKing);
      board.setPiece(Position(3, 5), blackPawn);

      final state = GameState(board: board, variantName: 'test');

      final capture = Move(from: Position(4, 4), to: Position(3, 5), isCapture: true);
      state.makeMove(capture);

      expect(state.blackCaptured.length, 1);
      expect(state.blackCaptured.first.symbol, 'P');
    });

    test('undoMove restores previous state', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      final move = Move(from: Position(6, 4), to: Position(4, 4));
      state.makeMove(move);

      expect(state.currentTurn, PieceColor.black);
      expect(state.moveHistory.length, 1);

      state.undoMove();

      expect(state.currentTurn, PieceColor.white);
      expect(state.moveHistory.isEmpty, isTrue);
      expect(state.board.getPiece(Position(6, 4))?.symbol, 'P');
      expect(state.board.getPiece(Position(4, 4)), isNull);
    });

    test('detects checkmate', () {
      final board = Board(size: 8);
      final blackKing = King(color: PieceColor.black);
      final whiteKing = King(color: PieceColor.white);
      final whiteQueen = Queen(color: PieceColor.white);
      final whiteRook = Rook(color: PieceColor.white);

      // Fool's mate position
      board.setPiece(Position(0, 4), blackKing);
      board.setPiece(Position(7, 4), whiteKing);
      board.setPiece(Position(0, 7), whiteQueen);
      board.setPiece(Position(1, 7), whiteRook);

      final state = GameState(
        board: board,
        variantName: 'test',
        currentTurn: PieceColor.black,
      );

      // Trigger game result check
      state.makeMove(Move(from: Position(0, 4), to: Position(0, 3)));

      // Actually test a proper checkmate
      final board2 = Board(size: 8);
      board2.setPiece(Position(0, 0), King(color: PieceColor.black));
      board2.setPiece(Position(7, 7), King(color: PieceColor.white));
      board2.setPiece(Position(0, 7), Rook(color: PieceColor.white));
      board2.setPiece(Position(1, 7), Rook(color: PieceColor.white));

      final state2 = GameState(
        board: board2,
        variantName: 'test',
        currentTurn: PieceColor.black,
      );

      expect(state2.board.isInCheck(PieceColor.black), isTrue);
      expect(state2.board.getAllLegalMoves(PieceColor.black).isEmpty, isTrue);
    });

    test('detects stalemate', () {
      final board = Board(size: 8);
      final blackKing = King(color: PieceColor.black);
      final whiteKing = King(color: PieceColor.white);
      final whiteQueen = Queen(color: PieceColor.white);

      // Stalemate position: black king in corner, not in check but no legal moves
      board.setPiece(Position(0, 0), blackKing);
      board.setPiece(Position(2, 1), whiteQueen);
      board.setPiece(Position(2, 2), whiteKing);

      final state = GameState(
        board: board,
        variantName: 'test',
        currentTurn: PieceColor.black,
      );

      expect(state.board.isInCheck(PieceColor.black), isFalse);
      expect(state.board.getAllLegalMoves(PieceColor.black).isEmpty, isTrue);
    });

    test('tracks half-move clock', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      // Pawn move resets clock
      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));
      expect(state.halfMoveClock, 0);

      // Knight move doesn't reset
      state.makeMove(Move(from: Position(0, 1), to: Position(2, 0)));
      expect(state.halfMoveClock, 1);

      state.makeMove(Move(from: Position(7, 1), to: Position(5, 2)));
      expect(state.halfMoveClock, 2);
    });

    test('tracks full move number', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      expect(state.fullMoveNumber, 1);

      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));
      expect(state.fullMoveNumber, 1);

      state.makeMove(Move(from: Position(1, 4), to: Position(3, 4)));
      expect(state.fullMoveNumber, 2);
    });

    test('copy creates independent state', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));

      final copy = state.copy();
      copy.makeMove(Move(from: Position(1, 4), to: Position(3, 4)));

      expect(state.currentTurn, PieceColor.black);
      expect(copy.currentTurn, PieceColor.white);
      expect(state.moveHistory.length, 1);
      expect(copy.moveHistory.length, 2);
    });

    test('getMoveHistoryNotation formats correctly', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));
      state.makeMove(Move(from: Position(1, 4), to: Position(3, 4)));

      final notation = state.getMoveHistoryNotation();

      expect(notation.contains('1.'), isTrue);
      expect(notation.contains('e2-e4'), isTrue);
      expect(notation.contains('e7-e5'), isTrue);
    });
  });

  group('FEN Export', () {
    test('toFEN generates correct format', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      final fen = state.toFEN();

      expect(fen.contains(' w '), isTrue); // White to move
      expect(fen.contains(' 0 1'), isTrue); // halfmove clock, fullmove number
    });

    test('toFEN reflects board state after moves', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));

      final fen = state.toFEN();

      expect(fen.contains(' b '), isTrue); // Black to move after white's move
    });
  });

  group('PGN Export', () {
    test('toPGN includes headers', () {
      final variant = StandardChess();
      final state = variant.createNewGame();
      state.whitePlayer = 'Alice';
      state.blackPlayer = 'Bob';

      final pgn = state.toPGN();

      expect(pgn.contains('[White "Alice"]'), isTrue);
      expect(pgn.contains('[Black "Bob"]'), isTrue);
      expect(pgn.contains('[Variant "standard_chess"]'), isTrue);
    });

    test('toPGN includes moves', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      state.makeMove(Move(from: Position(6, 4), to: Position(4, 4)));
      state.makeMove(Move(from: Position(1, 4), to: Position(3, 4)));

      final pgn = state.toPGN();

      expect(pgn.contains('1.'), isTrue);
      expect(pgn.contains('*'), isTrue); // Ongoing game result
    });
  });

  group('Variants', () {
    test('StandardChess creates 8x8 board', () {
      final variant = StandardChess();
      final state = variant.createNewGame();

      expect(state.board.size, 8);
      expect(state.board.getPiece(Position(7, 4))?.symbol, 'K');
      expect(state.board.getPiece(Position(6, 0))?.symbol, 'P');
    });

    test('GrandChess creates 10x10 board', () {
      final variant = GrandChess();
      final state = variant.createNewGame();

      expect(state.board.size, 10);
      expect(state.board.getPiece(Position(8, 5))?.symbol, 'K');
    });

    test('Variants have correct piece info', () {
      final standard = StandardChess();
      expect(standard.pieceInfo['K']?.name, 'King');
      expect(standard.pieceInfo['Q']?.name, 'Queen');

      final grand = GrandChess();
      expect(grand.pieceInfo['M']?.name, 'Marshal');
      expect(grand.pieceInfo['C']?.name, 'Cardinal');
    });
  });
}
