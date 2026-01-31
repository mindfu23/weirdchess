import 'dart:convert';
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

extension GameResultExtension on GameResult {
  String get pgnResult {
    switch (this) {
      case GameResult.whiteWins:
        return '1-0';
      case GameResult.blackWins:
        return '0-1';
      case GameResult.draw:
      case GameResult.stalemate:
        return '1/2-1/2';
      case GameResult.ongoing:
        return '*';
    }
  }
}

/// Represents a move with captured piece information for undo
class MoveRecord {
  final Move move;
  final Piece? capturedPiece;
  final Position? previousEnPassant;
  final bool pieceHadMoved;
  final String? pieceName;

  MoveRecord({
    required this.move,
    this.capturedPiece,
    this.previousEnPassant,
    required this.pieceHadMoved,
    this.pieceName,
  });

  Map<String, dynamic> toJson() => {
    'from': '${move.from.row},${move.from.col}',
    'to': '${move.to.row},${move.to.col}',
    'isCapture': move.isCapture,
    'isCastling': move.isCastling,
    'isEnPassant': move.isEnPassant,
    'promotionPiece': move.promotionPiece,
    'pieceName': pieceName,
  };
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

  // Game metadata for PGN
  String? event;
  String? site;
  String? date;
  String? whitePlayer;
  String? blackPlayer;

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
    this.event,
    this.site,
    this.date,
    this.whitePlayer,
    this.blackPlayer,
  })  : moveHistory = moveHistory ?? [],
        whiteCaptured = whiteCaptured ?? [],
        blackCaptured = blackCaptured ?? [];

  /// Execute a move and update game state
  bool makeMove(Move move) {
    final piece = board.getPiece(move.from);
    if (piece == null || piece.color != currentTurn) return false;

    final legalMoves = piece.getLegalMoves(board, move.from);
    final legalMove = legalMoves.firstWhere(
      (m) => m.to == move.to && (move.promotionPiece == null || m.promotionPiece == move.promotionPiece),
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
      pieceName: piece.name,
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
        result = currentTurn == PieceColor.white
            ? GameResult.blackWins
            : GameResult.whiteWins;
      } else {
        result = GameResult.stalemate;
      }
    } else if (halfMoveClock >= 100) {
      result = GameResult.draw;
    } else if (_isInsufficientMaterial()) {
      result = GameResult.draw;
    }
  }

  /// Check for insufficient mating material
  bool _isInsufficientMaterial() {
    final whitePieces = board.getPieces(PieceColor.white);
    final blackPieces = board.getPieces(PieceColor.black);

    if (whitePieces.length == 1 && blackPieces.length == 1) return true;

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

  /// Export position to FEN-like notation (extended for 10x10 boards).
  String toFEN() {
    final buffer = StringBuffer();

    // Board position
    for (int row = 0; row < board.size; row++) {
      int emptyCount = 0;
      for (int col = 0; col < board.size; col++) {
        final piece = board.getPiece(Position(row, col));
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          final symbol = piece.color == PieceColor.white
              ? piece.symbol.toUpperCase()
              : piece.symbol.toLowerCase();
          buffer.write(symbol);
        }
      }
      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }
      if (row < board.size - 1) {
        buffer.write('/');
      }
    }

    // Active color
    buffer.write(' ');
    buffer.write(currentTurn == PieceColor.white ? 'w' : 'b');

    // Castling availability (simplified - just check if king/rooks have moved)
    buffer.write(' ');
    String castling = '';
    final whiteKingPos = board.findKing(PieceColor.white);
    if (whiteKingPos != null) {
      final whiteKing = board.getPiece(whiteKingPos);
      if (whiteKing != null && !whiteKing.hasMoved) {
        final kingsideRook = board.getPiece(Position(board.size - 1, board.size - 1));
        final queensideRook = board.getPiece(Position(board.size - 1, 0));
        if (kingsideRook != null && !kingsideRook.hasMoved) castling += 'K';
        if (queensideRook != null && !queensideRook.hasMoved) castling += 'Q';
      }
    }
    final blackKingPos = board.findKing(PieceColor.black);
    if (blackKingPos != null) {
      final blackKing = board.getPiece(blackKingPos);
      if (blackKing != null && !blackKing.hasMoved) {
        final kingsideRook = board.getPiece(Position(0, board.size - 1));
        final queensideRook = board.getPiece(Position(0, 0));
        if (kingsideRook != null && !kingsideRook.hasMoved) castling += 'k';
        if (queensideRook != null && !queensideRook.hasMoved) castling += 'q';
      }
    }
    buffer.write(castling.isEmpty ? '-' : castling);

    // En passant target
    buffer.write(' ');
    if (board.enPassantTarget != null) {
      buffer.write(board.enPassantTarget!.toAlgebraic(board.size));
    } else {
      buffer.write('-');
    }

    // Half-move clock and full-move number
    buffer.write(' $halfMoveClock $fullMoveNumber');

    return buffer.toString();
  }

  /// Export game to PGN format.
  String toPGN() {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('[Event "${event ?? "Casual Game"}"]');
    buffer.writeln('[Site "${site ?? "WeirdChess App"}"]');
    buffer.writeln('[Date "${date ?? _formatDate(DateTime.now())}"]');
    buffer.writeln('[Variant "$variantName"]');
    buffer.writeln('[White "${whitePlayer ?? "Player 1"}"]');
    buffer.writeln('[Black "${blackPlayer ?? "Player 2"}"]');
    buffer.writeln('[Result "${result.pgnResult}"]');
    buffer.writeln('[BoardSize "${board.size}x${board.size}"]');
    buffer.writeln();

    // Moves
    final moves = StringBuffer();
    for (int i = 0; i < moveHistory.length; i++) {
      if (i % 2 == 0) {
        moves.write('${(i ~/ 2) + 1}. ');
      }

      final record = moveHistory[i];
      final move = record.move;

      // Build move notation
      String notation = '';
      if (move.isCastling) {
        notation = move.to.col > move.from.col ? 'O-O' : 'O-O-O';
      } else {
        // Piece symbol (skip for pawns)
        final pieceName = record.pieceName ?? 'Pawn';
        if (pieceName != 'Pawn') {
          notation += pieceName[0];
        }
        // Capture indicator
        if (move.isCapture) {
          if (pieceName == 'Pawn') {
            notation += move.from.toAlgebraic(board.size)[0];
          }
          notation += 'x';
        }
        // Destination
        notation += move.to.toAlgebraic(board.size);
        // Promotion
        if (move.promotionPiece != null) {
          notation += '=${move.promotionPiece}';
        }
      }

      moves.write('$notation ');

      // Line wrap at 80 chars
      if (moves.length > 70 && i % 2 == 1) {
        buffer.writeln(moves.toString().trim());
        moves.clear();
      }
    }

    if (moves.isNotEmpty) {
      buffer.write(moves.toString().trim());
    }

    buffer.write(' ${result.pgnResult}');

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// Serialize game state to JSON for saving.
  String toJson() {
    return jsonEncode({
      'variantName': variantName,
      'boardSize': board.size,
      'currentTurn': currentTurn.name,
      'result': result.name,
      'halfMoveClock': halfMoveClock,
      'fullMoveNumber': fullMoveNumber,
      'fen': toFEN(),
      'moveHistory': moveHistory.map((r) => r.toJson()).toList(),
      'event': event,
      'site': site,
      'date': date,
      'whitePlayer': whitePlayer,
      'blackPlayer': blackPlayer,
      'savedAt': DateTime.now().toIso8601String(),
    });
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
      event: event,
      site: site,
      date: date,
      whitePlayer: whitePlayer,
      blackPlayer: blackPlayer,
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
