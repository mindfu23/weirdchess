import '../core/board.dart';
import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';

/// Position evaluation for the AI
class Evaluator {
  // Piece-square tables for positional bonuses (10x10 board)
  // Values are from white's perspective, flip for black

  static const List<List<double>> pawnTable = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
    [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
    [0.3, 0.3, 0.3, 0.4, 0.4, 0.4, 0.4, 0.3, 0.3, 0.3],
    [0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.3, 0.2, 0.2, 0.2],
    [0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.1, 0.1],
    [0.1, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.1],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  ];

  static const List<List<double>> knightTable = [
    [-0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5],
    [-0.4, -0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, -0.4],
    [-0.3, 0.0, 0.1, 0.15, 0.15, 0.15, 0.15, 0.1, 0.0, -0.3],
    [-0.3, 0.05, 0.15, 0.2, 0.2, 0.2, 0.2, 0.15, 0.05, -0.3],
    [-0.3, 0.0, 0.15, 0.2, 0.2, 0.2, 0.2, 0.15, 0.0, -0.3],
    [-0.3, 0.05, 0.1, 0.15, 0.15, 0.15, 0.15, 0.1, 0.05, -0.3],
    [-0.3, 0.0, 0.05, 0.1, 0.1, 0.1, 0.1, 0.05, 0.0, -0.3],
    [-0.3, 0.0, 0.0, 0.05, 0.05, 0.05, 0.05, 0.0, 0.0, -0.3],
    [-0.4, -0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, -0.4],
    [-0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5],
  ];

  static const List<List<double>> bishopTable = [
    [-0.2, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.2],
    [-0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.1, 0.0, 0.05, 0.1, 0.1, 0.1, 0.1, 0.05, 0.0, -0.1],
    [-0.1, 0.05, 0.05, 0.1, 0.1, 0.1, 0.1, 0.05, 0.05, -0.1],
    [-0.1, 0.0, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.0, -0.1],
    [-0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, -0.1],
    [-0.1, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, -0.1],
    [-0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.2, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.2],
  ];

  static const List<List<double>> kingMiddleGameTable = [
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.2, -0.3, -0.3, -0.4, -0.4, -0.4, -0.4, -0.3, -0.3, -0.2],
    [-0.1, -0.2, -0.2, -0.2, -0.2, -0.2, -0.2, -0.2, -0.2, -0.1],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.1, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1],
    [0.2, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0, 0.1, 0.2, 0.2],
    [0.2, 0.3, 0.1, 0.0, 0.0, 0.0, 0.0, 0.1, 0.3, 0.2],
  ];

  /// Evaluate the current position
  /// Positive = white advantage, Negative = black advantage
  double evaluate(GameState state) {
    if (state.result == GameResult.whiteWins) return 10000.0;
    if (state.result == GameResult.blackWins) return -10000.0;
    if (state.result == GameResult.draw ||
        state.result == GameResult.stalemate) {
      return 0.0;
    }

    double score = 0.0;

    // Material and positional evaluation
    for (final (pos, piece) in state.board.getPieces(PieceColor.white)) {
      score += _evaluatePiece(piece, pos, PieceColor.white, state.board);
    }

    for (final (pos, piece) in state.board.getPieces(PieceColor.black)) {
      score -= _evaluatePiece(piece, pos, PieceColor.black, state.board);
    }

    // Mobility bonus
    final whiteMobility = state.board.getAllLegalMoves(PieceColor.white).length;
    final blackMobility = state.board.getAllLegalMoves(PieceColor.black).length;
    score += (whiteMobility - blackMobility) * 0.1;

    // Check bonus
    if (state.board.isInCheck(PieceColor.black)) score += 0.5;
    if (state.board.isInCheck(PieceColor.white)) score -= 0.5;

    return score;
  }

  double _evaluatePiece(Piece piece, Position pos, PieceColor color, Board board) {
    double score = piece.value.toDouble();

    // Add positional bonus
    final row = color == PieceColor.white ? pos.row : (board.size - 1 - pos.row);
    final col = pos.col;

    // Clamp indices for safety
    final safeRow = row.clamp(0, 9);
    final safeCol = col.clamp(0, 9);

    switch (piece.symbol) {
      case 'P':
        score += pawnTable[safeRow][safeCol];
        break;
      case 'N':
        score += knightTable[safeRow][safeCol];
        break;
      case 'B':
        score += bishopTable[safeRow][safeCol];
        break;
      case 'K':
        score += kingMiddleGameTable[safeRow][safeCol];
        break;
      case 'M': // Marshal - encourage central placement
        score += knightTable[safeRow][safeCol] * 0.5;
        break;
      case 'C': // Cardinal - encourage central placement
        score += bishopTable[safeRow][safeCol] * 0.5;
        break;
    }

    return score;
  }

  /// Quick evaluation for move ordering
  double evaluateMove(Move move, Board board) {
    double score = 0.0;

    // Captures are generally good
    if (move.isCapture) {
      final captured = board.getPiece(move.to);
      final attacker = board.getPiece(move.from);
      if (captured != null && attacker != null) {
        // MVV-LVA: Most Valuable Victim - Least Valuable Attacker
        score += captured.value * 10 - attacker.value;
      }
    }

    // Promotions are very good
    if (move.promotionPiece != null) {
      score += 8.0;
    }

    return score;
  }
}
