import 'board.dart';
import 'move.dart';
import 'piece.dart';

/// Possible game results
enum GameResult {
  ongoing,
  whiteWins,
  blackWins,
  draw,
  stalemate,
}

/// Represents a move with captured piece information for undo
class MoveRecord {
  final Move move;
  final Piece? capturedPiece;
  final Position? previousEnPassant;
  final bool pieceHadMoved;

  MoveRecord({
    required this.move,
    this.capturedPiece,
    this.previousEnPassant,
    required this.pieceHadMoved,
  });
}

/// Manages the complete state of a chess game
class GameState {
  final Board board;
  final String variantName;
  PieceColor currentTurn;
  final List<MoveRecord> moveHistory;
  final List<Piece> whiteCaptured;
  final List<Piece> blackCaptured;
  GameResult result;
  int halfMoveClock; // For 50-move rule
  int fullMoveNumber;

  GameState({
    required this.board,
    required this.variantName,
    this.currentTurn = PieceColor.white,
    List<MoveRecord>? moveHistory,
    List<Piece>? whiteCaptured,
    List<Piece>? blackCaptured,
    this.result = GameResult.ongoing,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
  })  : moveHistory = moveHistory ?? [],
        whiteCaptured = whiteCaptured ?? [],
        blackCaptured = blackCaptured ?? [];

  /// Execute a move and update game state
  bool makeMove(Move move) {
    final piece = board.getPiece(move.from);
    if (piece == null || piece.color != currentTurn) return false;

    final legalMoves = piece.getLegalMoves(board, move.from);
    final legalMove = legalMoves.firstWhere(
      (m) => m.to == move.to,
      orElse: () => move,
    );

    if (!legalMoves.any((m) => m.to == move.to)) return false;

    // Record for undo
    final capturedPiece = board.getPiece(move.to);
    final record = MoveRecord(
      move: legalMove,
      capturedPiece: capturedPiece,
      previousEnPassant: board.enPassantTarget,
      pieceHadMoved: piece.hasMoved,
    );

    // Track captured pieces
    if (capturedPiece != null) {
      if (capturedPiece.color == PieceColor.white) {
        whiteCaptured.add(capturedPiece);
      } else {
        blackCaptured.add(capturedPiece);
      }
    }

    // Execute the move
    board.makeMove(legalMove);
    moveHistory.add(record);

    // Update clocks
    if (capturedPiece != null || piece.symbol == 'P') {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }

    if (currentTurn == PieceColor.black) {
      fullMoveNumber++;
    }

    // Switch turn
    currentTurn = currentTurn.opposite;

    // Check game result
    _updateGameResult();

    return true;
  }

  /// Undo the last move
  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    final record = moveHistory.removeLast();
    final move = record.move;

    // Move piece back
    final piece = board.removePiece(move.to);
    if (piece != null) {
      piece.hasMoved = record.pieceHadMoved;
      board.setPiece(move.from, piece);
    }

    // Restore captured piece
    if (record.capturedPiece != null) {
      board.setPiece(move.to, record.capturedPiece);
      if (record.capturedPiece!.color == PieceColor.white) {
        whiteCaptured.removeLast();
      } else {
        blackCaptured.removeLast();
      }
    }

    // Handle en passant undo
    if (move.isEnPassant && record.capturedPiece != null) {
      final capturePos = Position(move.from.row, move.to.col);
      board.setPiece(capturePos, record.capturedPiece);
    }

    // Handle castling undo
    if (move.isCastling) {
      final isKingside = move.to.col > move.from.col;
      final rookFromCol = isKingside ? move.to.col - 1 : move.to.col + 1;
      final rookToCol = isKingside ? board.size - 1 : 0;
      final rook = board.removePiece(Position(move.from.row, rookFromCol));
      if (rook != null) {
        rook.hasMoved = false;
        board.setPiece(Position(move.from.row, rookToCol), rook);
      }
    }

    // Restore en passant target
    board.enPassantTarget = record.previousEnPassant;

    // Switch turn back
    currentTurn = currentTurn.opposite;

    // Update move number
    if (currentTurn == PieceColor.black) {
      fullMoveNumber--;
    }

    result = GameResult.ongoing;

    return true;
  }

  /// Check for checkmate, stalemate, or draws
  void _updateGameResult() {
    final legalMoves = board.getAllLegalMoves(currentTurn);

    if (legalMoves.isEmpty) {
      if (board.isInCheck(currentTurn)) {
        // Checkmate
        result = currentTurn == PieceColor.white
            ? GameResult.blackWins
            : GameResult.whiteWins;
      } else {
        // Stalemate
        result = GameResult.stalemate;
      }
    } else if (halfMoveClock >= 100) {
      // 50-move rule
      result = GameResult.draw;
    } else if (_isInsufficientMaterial()) {
      result = GameResult.draw;
    }
  }

  /// Check for insufficient mating material
  bool _isInsufficientMaterial() {
    final whitePieces = board.getPieces(PieceColor.white);
    final blackPieces = board.getPieces(PieceColor.black);

    // King vs King
    if (whitePieces.length == 1 && blackPieces.length == 1) return true;

    // King + minor piece vs King
    if (whitePieces.length == 1 && blackPieces.length == 2) {
      final piece = blackPieces.firstWhere((p) => p.$2.symbol != 'K').$2;
      if (piece.symbol == 'N' || piece.symbol == 'B') return true;
    }
    if (blackPieces.length == 1 && whitePieces.length == 2) {
      final piece = whitePieces.firstWhere((p) => p.$2.symbol != 'K').$2;
      if (piece.symbol == 'N' || piece.symbol == 'B') return true;
    }

    return false;
  }

  /// Get algebraic notation for move history
  String getMoveHistoryNotation() {
    final buffer = StringBuffer();
    for (int i = 0; i < moveHistory.length; i++) {
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write(moveHistory[i].move.toAlgebraic(board.size));
      buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  /// Create a copy of the game state
  GameState copy() {
    return GameState(
      board: board.copy(),
      variantName: variantName,
      currentTurn: currentTurn,
      moveHistory: List.from(moveHistory),
      whiteCaptured: List.from(whiteCaptured),
      blackCaptured: List.from(blackCaptured),
      result: result,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
    );
  }

  /// Check if the game is over
  bool get isGameOver => result != GameResult.ongoing;

  /// Get the winner color (if any)
  PieceColor? get winner {
    switch (result) {
      case GameResult.whiteWins:
        return PieceColor.white;
      case GameResult.blackWins:
        return PieceColor.black;
      default:
        return null;
    }
  }
}
