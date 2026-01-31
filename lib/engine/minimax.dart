import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';
import 'evaluator.dart';
import 'transposition_table.dart';

/// Result of a minimax search
class SearchResult {
  final Move? bestMove;
  final double score;
  final int nodesSearched;
  final int ttHits;

  SearchResult({
    this.bestMove,
    required this.score,
    required this.nodesSearched,
    this.ttHits = 0,
  });
}

/// Minimax search with alpha-beta pruning and transposition table.
class MinimaxEngine {
  final Evaluator evaluator;
  final TranspositionTable _tt;
  int _nodesSearched = 0;
  int _ttHits = 0;

  MinimaxEngine({
    Evaluator? evaluator,
    TranspositionTable? transpositionTable,
  })  : evaluator = evaluator ?? Evaluator(),
        _tt = transpositionTable ?? TranspositionTable();

  /// Find the best move using minimax with alpha-beta pruning.
  SearchResult search(GameState state, int depth) {
    _nodesSearched = 0;
    _ttHits = 0;
    _tt.newSearch();

    final isMaximizing = state.currentTurn == PieceColor.white;
    final hash = _computeHash(state);

    final result = _alphaBeta(
      state,
      depth,
      double.negativeInfinity,
      double.infinity,
      isMaximizing,
      hash,
    );

    return SearchResult(
      bestMove: result.$2,
      score: result.$1,
      nodesSearched: _nodesSearched,
      ttHits: _ttHits,
    );
  }

  /// Alpha-beta pruning search with transposition table.
  (double, Move?) _alphaBeta(
    GameState state,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
    int hash,
  ) {
    _nodesSearched++;

    // Check transposition table
    final ttEntry = _tt.probe(hash, depth);
    if (ttEntry != null) {
      _ttHits++;
      switch (ttEntry.type) {
        case TTEntryType.exact:
          return (ttEntry.score, ttEntry.bestMove);
        case TTEntryType.lowerBound:
          if (ttEntry.score >= beta) {
            return (ttEntry.score, ttEntry.bestMove);
          }
          alpha = alpha > ttEntry.score ? alpha : ttEntry.score;
        case TTEntryType.upperBound:
          if (ttEntry.score <= alpha) {
            return (ttEntry.score, ttEntry.bestMove);
          }
          beta = beta < ttEntry.score ? beta : ttEntry.score;
      }
    }

    // Terminal conditions
    if (depth == 0 || state.isGameOver) {
      final score = evaluator.evaluate(state);
      _tt.store(
        hash: hash,
        depth: depth,
        score: score,
        type: TTEntryType.exact,
      );
      return (score, null);
    }

    final moves = state.board.getAllLegalMoves(state.currentTurn);
    if (moves.isEmpty) {
      final score = evaluator.evaluate(state);
      _tt.store(
        hash: hash,
        depth: depth,
        score: score,
        type: TTEntryType.exact,
      );
      return (score, null);
    }

    // Move ordering: TT best move first, then captures
    final ttBestMove = _tt.getBestMove(hash);
    _orderMoves(moves, state, ttBestMove);

    Move? bestMove = moves.first;
    final originalAlpha = alpha;

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;

      for (final move in moves) {
        final testState = state.copy();
        testState.makeMove(move);
        final newHash = _computeHash(testState);

        final (eval, _) = _alphaBeta(testState, depth - 1, alpha, beta, false, newHash);

        if (eval > maxEval) {
          maxEval = eval;
          bestMove = move;
        }

        alpha = alpha > eval ? alpha : eval;
        if (beta <= alpha) break; // Beta cutoff
      }

      // Store in TT
      final ttType = maxEval <= originalAlpha
          ? TTEntryType.upperBound
          : maxEval >= beta
              ? TTEntryType.lowerBound
              : TTEntryType.exact;

      _tt.store(
        hash: hash,
        depth: depth,
        score: maxEval,
        type: ttType,
        bestMove: bestMove,
      );

      return (maxEval, bestMove);
    } else {
      double minEval = double.infinity;

      for (final move in moves) {
        final testState = state.copy();
        testState.makeMove(move);
        final newHash = _computeHash(testState);

        final (eval, _) = _alphaBeta(testState, depth - 1, alpha, beta, true, newHash);

        if (eval < minEval) {
          minEval = eval;
          bestMove = move;
        }

        beta = beta < eval ? beta : eval;
        if (beta <= alpha) break; // Alpha cutoff
      }

      // Store in TT
      final ttType = minEval >= beta
          ? TTEntryType.lowerBound
          : minEval <= originalAlpha
              ? TTEntryType.upperBound
              : TTEntryType.exact;

      _tt.store(
        hash: hash,
        depth: depth,
        score: minEval,
        type: ttType,
        bestMove: bestMove,
      );

      return (minEval, bestMove);
    }
  }

  /// Order moves for better pruning.
  void _orderMoves(List<Move> moves, GameState state, Move? ttBestMove) {
    moves.sort((a, b) {
      // TT best move first
      if (ttBestMove != null) {
        if (a == ttBestMove) return -1;
        if (b == ttBestMove) return 1;
      }

      // Then sort by move evaluation
      final scoreA = evaluator.evaluateMove(a, state.board);
      final scoreB = evaluator.evaluateMove(b, state.board);
      return scoreB.compareTo(scoreA);
    });
  }

  /// Compute a hash for the current game state.
  int _computeHash(GameState state) {
    int hash = 0;

    // Hash pieces on board
    for (int row = 0; row < state.board.size; row++) {
      for (int col = 0; col < state.board.size; col++) {
        final piece = state.board.getPiece(Position(row, col));
        if (piece != null) {
          final colorIndex = piece.color == PieceColor.white ? 0 : 1;
          final pieceIndex = _pieceTypeIndex(piece.symbol);
          hash ^= ZobristHash.pieceHash(colorIndex, pieceIndex, row, col);
        }
      }
    }

    // Hash side to move
    if (state.currentTurn == PieceColor.black) {
      hash ^= ZobristHash.blackToMoveHash;
    }

    // Hash en passant
    if (state.board.enPassantTarget != null) {
      hash ^= ZobristHash.enPassantHash(state.board.enPassantTarget!.col);
    }

    return hash;
  }

  /// Get piece type index for hashing.
  int _pieceTypeIndex(String symbol) {
    const pieces = ['K', 'Q', 'R', 'B', 'N', 'P', 'M', 'C', 'A', 'W', 'H', 'F'];
    final index = pieces.indexOf(symbol);
    return index >= 0 ? index : 0;
  }

  /// Iterative deepening search with time limit.
  SearchResult searchWithTimeLimit(
    GameState state,
    Duration timeLimit, {
    int maxDepth = 10,
  }) {
    final stopwatch = Stopwatch()..start();
    SearchResult? lastResult;

    for (int depth = 1; depth <= maxDepth; depth++) {
      if (stopwatch.elapsed >= timeLimit) break;

      final result = search(state, depth);
      lastResult = result;

      // If we found a forced mate, stop searching
      if (result.score.abs() > 9000) break;
    }

    return lastResult ?? search(state, 1);
  }

  /// Clear the transposition table.
  void clearCache() {
    _tt.clear();
  }

  /// Get transposition table statistics.
  Map<String, dynamic> get cacheStats => _tt.stats;
}
