import 'dart:convert';
import 'board.dart';
import 'game_result.dart';
import 'move.dart';
import 'piece.dart';
import 'variant_interface.dart';

export 'game_result.dart';

/// Represents a move record for undo support.
class MoveRecord {
  final Move move;
  final Piece? capturedPiece;
  final Position? previousEnPassant;
  final bool pieceHadMoved;
  final String? pieceName;

  /// A copy of the moving piece *before* the move (used to restore promotions
  /// and maintain exact piece state on undo).
  final Piece? originalPiece;

  /// Original rook column for castling undo (supports Chess960).
  final int? rookOriginalCol;

  /// Pieces destroyed by variant post-capture effects (e.g., Atomic explosions).
  /// Restored in [GameState.undoMove].
  final List<(Position, Piece)> explosionCasualties;

  /// Snapshot of variantData before this move — allows undoing Three-Check
  /// counters and any other variant-specific state.
  final Map<String, dynamic>? previousVariantData;

  MoveRecord({
    required this.move,
    this.capturedPiece,
    this.previousEnPassant,
    required this.pieceHadMoved,
    this.pieceName,
    this.originalPiece,
    this.rookOriginalCol,
    this.explosionCasualties = const [],
    this.previousVariantData,
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

/// Manages the complete state of a chess game.
class GameState {
  final Board board;
  final String variantName;
  PieceColor currentTurn;
  final List<MoveRecord> moveHistory;
  final List<Piece> whiteCaptured;
  final List<Piece> blackCaptured;
  GameResult result;
  int halfMoveClock;
  int fullMoveNumber;

  /// Variant-specific rule hooks. Set by [ChessVariant.createNewGame].
  final ChessVariantInterface? variant;

  /// Arbitrary variant-specific state (e.g., Three-Check counters).
  Map<String, dynamic> variantData;

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
    this.variant,
    Map<String, dynamic>? variantData,
    this.event,
    this.site,
    this.date,
    this.whitePlayer,
    this.blackPlayer,
  })  : moveHistory = moveHistory ?? [],
        whiteCaptured = whiteCaptured ?? [],
        blackCaptured = blackCaptured ?? [],
        variantData = variantData ?? {};

  /// Returns all legal moves for [color], using variant-aware move generation.
  List<Move> getAllLegalMoves(PieceColor color) {
    if (variant != null) {
      final moves = <Move>[];
      for (final (pos, piece) in board.getPieces(color)) {
        moves.addAll(variant!.getLegalMoves(board, pos, piece));
      }
      return moves;
    }
    return board.getAllLegalMoves(color);
  }

  /// Execute a move and update game state.
  bool makeMove(Move move) {
    final piece = board.getPiece(move.from);
    if (piece == null || piece.color != currentTurn) return false;

    // Use variant-aware legal move generation for validation.
    final legalMoves = variant != null
        ? variant!.getLegalMoves(board, move.from, piece)
        : piece.getLegalMoves(board, move.from);

    if (!legalMoves.any((m) => m.to == move.to)) return false;

    final legalMove = legalMoves.firstWhere(
      (m) =>
          m.to == move.to &&
          (move.promotionPiece == null ||
              m.promotionPiece == move.promotionPiece),
      orElse: () => legalMoves.firstWhere((m) => m.to == move.to),
    );

    // Snapshot variant data for undo before anything mutates.
    final previousVariantData = Map<String, dynamic>.from(variantData);

    // Record the original piece (before any board change) for promotion undo.
    final originalPiece = piece.copy();

    // Determine captured piece position (en passant has different capture square).
    final capturePos = legalMove.isEnPassant
        ? Position(move.from.row, move.to.col)
        : legalMove.to;
    final capturedPiece = board.getPiece(capturePos);

    // Find rook's original column before the board mutates (for castling undo).
    int? rookOriginalCol;
    if (legalMove.isCastling) {
      final isKingside = legalMove.to.col > legalMove.from.col;
      if (isKingside) {
        for (int col = board.size - 1; col > legalMove.from.col; col--) {
          final p = board.getPiece(Position(legalMove.from.row, col));
          if (p != null &&
              p.symbol == 'R' &&
              p.color == piece.color &&
              !p.hasMoved) {
            rookOriginalCol = col;
            break;
          }
        }
      } else {
        for (int col = 0; col < legalMove.from.col; col++) {
          final p = board.getPiece(Position(legalMove.from.row, col));
          if (p != null &&
              p.symbol == 'R' &&
              p.color == piece.color &&
              !p.hasMoved) {
            rookOriginalCol = col;
          }
        }
      }
      rookOriginalCol ??= legalMove.to.col > legalMove.from.col
          ? board.size - 1
          : 0;
    }

    final record = MoveRecord(
      move: legalMove,
      capturedPiece: capturedPiece,
      previousEnPassant: board.enPassantTarget,
      pieceHadMoved: piece.hasMoved,
      pieceName: piece.name,
      originalPiece: originalPiece,
      rookOriginalCol: rookOriginalCol,
      previousVariantData: previousVariantData,
    );

    // Track captured pieces in the captured lists.
    if (capturedPiece != null) {
      if (capturedPiece.color == PieceColor.white) {
        whiteCaptured.add(capturedPiece);
      } else {
        blackCaptured.add(capturedPiece);
      }
    }

    // Execute the move on the board.
    board.makeMove(legalMove);

    // Handle pawn promotion.
    if (legalMove.promotionPiece != null) {
      final destPiece = board.getPiece(legalMove.to);
      if (destPiece?.symbol == 'P') {
        final promoted = variant?.createPiece(
                legalMove.promotionPiece!, destPiece!.color) ??
            _fallbackCreatePiece(legalMove.promotionPiece!, destPiece!.color);
        promoted.hasMoved = true;
        board.setPiece(legalMove.to, promoted);
      }
    }

    // Apply variant post-capture effects (e.g., Atomic explosions) and record
    // any additional casualties for undo.
    List<(Position, Piece)> explosionCasualties = [];
    if (legalMove.isCapture && variant != null) {
      explosionCasualties = variant!.applyPostCaptureEffect(board, legalMove);
    }

    // Rebuild the record with casualties (Dart records are immutable, so we
    // create a new one and swap it into moveHistory after adding the first).
    moveHistory.add(MoveRecord(
      move: record.move,
      capturedPiece: record.capturedPiece,
      previousEnPassant: record.previousEnPassant,
      pieceHadMoved: record.pieceHadMoved,
      pieceName: record.pieceName,
      originalPiece: record.originalPiece,
      rookOriginalCol: record.rookOriginalCol,
      explosionCasualties: explosionCasualties,
      previousVariantData: record.previousVariantData,
    ));

    // Update clocks.
    if (capturedPiece != null || piece.symbol == 'P') {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }

    if (currentTurn == PieceColor.black) {
      fullMoveNumber++;
    }

    // Let the variant update its own state data (e.g., check counters).
    variant?.updateVariantData(board, legalMove, currentTurn, variantData);

    // Switch turn.
    currentTurn = currentTurn.opposite;

    // Evaluate standard game result then let the variant override.
    _updateGameResult();
    final variantResult =
        variant?.checkVariantResult(board, currentTurn, variantData);
    if (variantResult != null) result = variantResult;

    return true;
  }

  /// Undo the last move.
  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    final record = moveHistory.removeLast();
    final move = record.move;

    // Switch turn back first.
    currentTurn = currentTurn.opposite;
    if (currentTurn == PieceColor.black) {
      fullMoveNumber--;
    }

    // Restore explosion casualties (Atomic chess etc.) before restoring pieces.
    for (final (pos, casualty) in record.explosionCasualties) {
      board.setPiece(pos, casualty);
    }

    // Restore the moving piece using the originalPiece snapshot (handles
    // promotion: the queen at move.to is replaced with the original pawn).
    board.removePiece(move.to);
    final pieceToRestore = record.originalPiece?.copy() ??
        board.getPiece(move.from); // should never be needed
    if (pieceToRestore != null) {
      pieceToRestore.hasMoved = record.pieceHadMoved;
      board.setPiece(move.from, pieceToRestore);
    }

    // Restore captured piece.
    if (record.capturedPiece != null) {
      if (move.isEnPassant) {
        // En passant captured pawn is on a different square than move.to.
        board.setPiece(
            Position(move.from.row, move.to.col), record.capturedPiece);
      } else {
        board.setPiece(move.to, record.capturedPiece);
      }
      if (record.capturedPiece!.color == PieceColor.white) {
        whiteCaptured.removeLast();
      } else {
        blackCaptured.removeLast();
      }
    }

    // Restore castling rook using the stored original column.
    if (move.isCastling) {
      final isKingside = move.to.col > move.from.col;
      final rookCurrentCol =
          isKingside ? move.to.col - 1 : move.to.col + 1;
      final rookOriginalCol =
          record.rookOriginalCol ?? (isKingside ? board.size - 1 : 0);
      final rook =
          board.removePiece(Position(move.from.row, rookCurrentCol));
      if (rook != null) {
        rook.hasMoved = false;
        board.setPiece(Position(move.from.row, rookOriginalCol), rook);
      }
    }

    // Restore en passant target.
    board.enPassantTarget = record.previousEnPassant;

    // Restore variant-specific data.
    if (record.previousVariantData != null) {
      variantData = Map<String, dynamic>.from(record.previousVariantData!);
    }

    result = GameResult.ongoing;
    return true;
  }

  /// Check for checkmate, stalemate, or draws using variant-aware move gen.
  void _updateGameResult() {
    final legalMoves = getAllLegalMoves(currentTurn);

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

  /// Check for insufficient mating material.
  bool _isInsufficientMaterial() {
    final whitePieces = board.getPieces(PieceColor.white);
    final blackPieces = board.getPieces(PieceColor.black);

    // Horde: white has many pawns — not insufficient.
    if (whitePieces.isEmpty || blackPieces.isEmpty) return false;

    if (whitePieces.length == 1 && blackPieces.length == 1) return true;

    if (whitePieces.length == 1 && blackPieces.length == 2) {
      final piece =
          blackPieces.firstWhere((p) => p.$2.symbol != 'K').$2;
      if (piece.symbol == 'N' || piece.symbol == 'B') return true;
    }
    if (blackPieces.length == 1 && whitePieces.length == 2) {
      final piece =
          whitePieces.firstWhere((p) => p.$2.symbol != 'K').$2;
      if (piece.symbol == 'N' || piece.symbol == 'B') return true;
    }

    return false;
  }

  /// Fallback piece creation when no variant is set (standard pieces only).
  Piece _fallbackCreatePiece(String symbol, PieceColor color) {
    // Lazy import via reflection isn't possible; variants always provide this.
    // This path should never be reached in normal gameplay.
    throw StateError(
        'Cannot create piece "$symbol" without a variant. '
        'Ensure createNewGame() sets the variant.');
  }

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

  String toFEN() {
    final buffer = StringBuffer();

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
      if (emptyCount > 0) buffer.write(emptyCount);
      if (row < board.size - 1) buffer.write('/');
    }

    buffer.write(' ');
    buffer.write(currentTurn == PieceColor.white ? 'w' : 'b');

    buffer.write(' ');
    String castling = '';
    final whiteKingPos = board.findKing(PieceColor.white);
    if (whiteKingPos != null) {
      final whiteKing = board.getPiece(whiteKingPos);
      if (whiteKing != null && !whiteKing.hasMoved) {
        final ksr = board.getPiece(Position(board.size - 1, board.size - 1));
        final qsr = board.getPiece(Position(board.size - 1, 0));
        if (ksr != null && !ksr.hasMoved) castling += 'K';
        if (qsr != null && !qsr.hasMoved) castling += 'Q';
      }
    }
    final blackKingPos = board.findKing(PieceColor.black);
    if (blackKingPos != null) {
      final blackKing = board.getPiece(blackKingPos);
      if (blackKing != null && !blackKing.hasMoved) {
        final ksr = board.getPiece(Position(0, board.size - 1));
        final qsr = board.getPiece(Position(0, 0));
        if (ksr != null && !ksr.hasMoved) castling += 'k';
        if (qsr != null && !qsr.hasMoved) castling += 'q';
      }
    }
    buffer.write(castling.isEmpty ? '-' : castling);

    buffer.write(' ');
    if (board.enPassantTarget != null) {
      buffer.write(board.enPassantTarget!.toAlgebraic(board.size));
    } else {
      buffer.write('-');
    }

    buffer.write(' $halfMoveClock $fullMoveNumber');
    return buffer.toString();
  }

  String toPGN() {
    final buffer = StringBuffer();

    buffer.writeln('[Event "${event ?? "Casual Game"}"]');
    buffer.writeln('[Site "${site ?? "WeirdChess App"}"]');
    buffer.writeln('[Date "${date ?? _formatDate(DateTime.now())}"]');
    buffer.writeln('[Variant "$variantName"]');
    buffer.writeln('[White "${whitePlayer ?? "Player 1"}"]');
    buffer.writeln('[Black "${blackPlayer ?? "Player 2"}"]');
    buffer.writeln('[Result "${result.pgnResult}"]');
    buffer.writeln('[BoardSize "${board.size}x${board.size}"]');
    buffer.writeln();

    final moves = StringBuffer();
    for (int i = 0; i < moveHistory.length; i++) {
      if (i % 2 == 0) {
        moves.write('${(i ~/ 2) + 1}. ');
      }

      final record = moveHistory[i];
      final move = record.move;

      String notation = '';
      if (move.isCastling) {
        notation = move.to.col > move.from.col ? 'O-O' : 'O-O-O';
      } else {
        final pieceName = record.pieceName ?? 'Pawn';
        if (pieceName != 'Pawn') notation += pieceName[0];
        if (move.isCapture) {
          if (pieceName == 'Pawn') notation += move.from.toAlgebraic(board.size)[0];
          notation += 'x';
        }
        notation += move.to.toAlgebraic(board.size);
        if (move.promotionPiece != null) notation += '=${move.promotionPiece}';
      }

      moves.write('$notation ');

      if (moves.length > 70 && i % 2 == 1) {
        buffer.writeln(moves.toString().trim());
        moves.clear();
      }
    }

    if (moves.isNotEmpty) buffer.write(moves.toString().trim());
    buffer.write(' ${result.pgnResult}');
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// Restore a [GameState] from JSON produced by [toJson].
  ///
  /// Reconstructs the board from the embedded FEN string using the variant's
  /// [ChessVariantInterface.createPiece] to instantiate the correct piece types.
  /// Move history is NOT restored — undo will not work for pre-save moves.
  static GameState fromJson(String json, ChessVariantInterface variant) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final fen = map['fen'] as String;
    final boardSize = map['boardSize'] as int? ?? 8;
    final turnName = map['currentTurn'] as String? ?? 'white';
    final resultName = map['result'] as String? ?? 'ongoing';
    final halfMoveClock = map['halfMoveClock'] as int? ?? 0;
    final fullMoveNumber = map['fullMoveNumber'] as int? ?? 1;
    final variantData =
        (map['variantData'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final variantName = map['variantName'] as String? ?? '';

    // Parse FEN
    final parts = fen.split(' ');
    final boardStr = parts[0];

    final board = Board(size: boardSize);
    final rows = boardStr.split('/');
    for (int row = 0; row < rows.length && row < boardSize; row++) {
      int col = 0;
      for (int i = 0; i < rows[row].length && col < boardSize; i++) {
        final ch = rows[row][i];
        if (RegExp(r'\d').hasMatch(ch)) {
          // Handle multi-digit numbers for 10x10 boards
          String numStr = ch;
          while (i + 1 < rows[row].length &&
              RegExp(r'\d').hasMatch(rows[row][i + 1])) {
            i++;
            numStr += rows[row][i];
          }
          col += int.parse(numStr);
        } else {
          final color =
              ch == ch.toUpperCase() ? PieceColor.white : PieceColor.black;
          final symbol = ch.toUpperCase();
          try {
            final piece = variant.createPiece(symbol, color);
            piece.hasMoved = true; // Default: assume moved
            board.setPiece(Position(row, col), piece);
          } catch (_) {
            // Unknown piece symbol — skip
          }
          col++;
        }
      }
    }

    // Restore castling rights from FEN
    if (parts.length > 2 && parts[2] != '-') {
      final castling = parts[2];
      if (castling.contains('K') || castling.contains('Q')) {
        final kingPos = board.findKing(PieceColor.white);
        if (kingPos != null) {
          board.getPiece(kingPos)?.hasMoved = false;
        }
        if (castling.contains('K')) {
          final rook =
              board.getPiece(Position(boardSize - 1, boardSize - 1));
          if (rook != null) rook.hasMoved = false;
        }
        if (castling.contains('Q')) {
          final rook = board.getPiece(Position(boardSize - 1, 0));
          if (rook != null) rook.hasMoved = false;
        }
      }
      if (castling.contains('k') || castling.contains('q')) {
        final kingPos = board.findKing(PieceColor.black);
        if (kingPos != null) {
          board.getPiece(kingPos)?.hasMoved = false;
        }
        if (castling.contains('k')) {
          final rook = board.getPiece(Position(0, boardSize - 1));
          if (rook != null) rook.hasMoved = false;
        }
        if (castling.contains('q')) {
          final rook = board.getPiece(Position(0, 0));
          if (rook != null) rook.hasMoved = false;
        }
      }
    }

    // Restore en passant target
    if (parts.length > 3 && parts[3] != '-') {
      board.enPassantTarget = Position.fromAlgebraic(parts[3], boardSize);
    }

    final turn =
        turnName == 'black' ? PieceColor.black : PieceColor.white;

    final result = GameResult.values.firstWhere(
      (r) => r.name == resultName,
      orElse: () => GameResult.ongoing,
    );

    // Let the variant synchronize piece state with restored variantData
    // (e.g., Jetan Princess escape availability).
    variant.postRestoreBoard(board, variantData);

    return GameState(
      board: board,
      variantName: variantName,
      currentTurn: turn,
      result: result,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      variant: variant,
      variantData: Map<String, dynamic>.from(variantData),
    );
  }

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
      'variantData': variantData,
      'event': event,
      'site': site,
      'date': date,
      'whitePlayer': whitePlayer,
      'blackPlayer': blackPlayer,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

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
      variant: variant,
      variantData: Map<String, dynamic>.from(variantData),
      event: event,
      site: site,
      date: date,
      whitePlayer: whitePlayer,
      blackPlayer: blackPlayer,
    );
  }

  bool get isGameOver => result != GameResult.ongoing;

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
