import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';
import 'evaluator.dart';

/// Result of a minimax search
class SearchResult {
  final Move? bestMove;
  final double score;
  final int nodesSearched;

  SearchResult({
    this.bestMove,
    required this.score,
    required this.nodesSearched,
  });
}

/// Minimax search with alpha-beta pruning
class MinimaxEngine {
  final Evaluator evaluator;
  int _nodesSearched = 0;

  MinimaxEngine({Evaluator? evaluator}) : evaluator = evaluator ?? Evaluator();

  /// Find the best move using minimax with alpha-beta pruning
  SearchResult search(GameState state, int depth) {
    _nodesSearched = 0;
    final isMaximizing = state.currentTurn == PieceColor.white;

    final result = _alphaBeta(
      state,
      depth,
      double.negativeInfinity,
      double.infinity,
      isMaximizing,
    );

    return SearchResult(
      bestMove: result.$2,
      score: result.$1,
      nodesSearched: _nodesSearched,
    );
  }

  /// Alpha-beta pruning search
  (double, Move?) _alphaBeta(
    GameState state,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
  ) {
    _nodesSearched++;

    // Terminal conditions
    if (depth == 0 || state.isGameOver) {
      return (evaluator.evaluate(state), null);
    }

    final moves = state.board.getAllLegalMoves(state.currentTurn);
    if (moves.isEmpty) {
      return (evaluator.evaluate(state), null);
    }

    // Sort moves for better pruning (captures first)
    moves.sort((a, b) {
      final scoreA = evaluator.evaluateMove(a, state.board);
      final scoreB = evaluator.evaluateMove(b, state.board);
      return scoreB.compareTo(scoreA);
    });

    Move? bestMove = moves.first;

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;

      for (final move in moves) {
        final testState = state.copy();
        testState.makeMove(move);

        final (eval, _) = _alphaBeta(testState, depth - 1, alpha, beta, false);

        if (eval > maxEval) {
          maxEval = eval;
          bestMove = move;
        }

        alpha = alpha > eval ? alpha : eval;
        if (beta <= alpha) break; // Beta cutoff
      }

      return (maxEval, bestMove);
    } else {
      double minEval = double.infinity;

      for (final move in moves) {
        final testState = state.copy();
        testState.makeMove(move);

        final (eval, _) = _alphaBeta(testState, depth - 1, alpha, beta, true);

        if (eval < minEval) {
          minEval = eval;
          bestMove = move;
        }

        beta = beta < eval ? beta : eval;
        if (beta <= alpha) break; // Alpha cutoff
      }

      return (minEval, bestMove);
    }
  }

  /// Iterative deepening search with time limit
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
}
