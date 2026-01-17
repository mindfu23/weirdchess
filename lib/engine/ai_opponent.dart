import 'dart:math';
import '../core/game_state.dart';
import '../core/move.dart';
import 'minimax.dart';

/// Difficulty levels for the AI
enum AIDifficulty {
  beginner, // Depth 1, random element
  easy, // Depth 2
  medium, // Depth 3
  hard, // Depth 4
}

/// AI opponent that plays chess using minimax
class AIOpponent {
  final MinimaxEngine engine;
  final Random _random;
  AIDifficulty difficulty;

  AIOpponent({
    AIDifficulty? difficulty,
    MinimaxEngine? engine,
    Random? random,
  })  : difficulty = difficulty ?? AIDifficulty.easy,
        engine = engine ?? MinimaxEngine(),
        _random = random ?? Random();

  /// Get the search depth for current difficulty
  int get searchDepth {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 1;
      case AIDifficulty.easy:
        return 2;
      case AIDifficulty.medium:
        return 3;
      case AIDifficulty.hard:
        return 4;
    }
  }

  /// Find the best move for the current position
  Future<Move?> findBestMove(GameState state) async {
    if (state.isGameOver) return null;

    final legalMoves = state.board.getAllLegalMoves(state.currentTurn);
    if (legalMoves.isEmpty) return null;

    // Beginner mode: sometimes make random moves
    if (difficulty == AIDifficulty.beginner && _random.nextDouble() < 0.3) {
      return legalMoves[_random.nextInt(legalMoves.length)];
    }

    // Run minimax search
    final result = engine.search(state, searchDepth);

    // Add some randomness for beginner/easy modes
    if (difficulty == AIDifficulty.beginner ||
        difficulty == AIDifficulty.easy) {
      // Sometimes pick a suboptimal move
      if (_random.nextDouble() < 0.1 && legalMoves.length > 1) {
        final otherMoves =
            legalMoves.where((m) => m != result.bestMove).toList();
        if (otherMoves.isNotEmpty) {
          return otherMoves[_random.nextInt(otherMoves.length)];
        }
      }
    }

    return result.bestMove ?? legalMoves.first;
  }

  /// Get a description of the AI's evaluation
  String getEvaluationComment(double score) {
    if (score > 5) return 'White has a winning advantage';
    if (score > 2) return 'White is clearly better';
    if (score > 0.5) return 'White is slightly better';
    if (score < -5) return 'Black has a winning advantage';
    if (score < -2) return 'Black is clearly better';
    if (score < -0.5) return 'Black is slightly better';
    return 'Position is roughly equal';
  }
}
