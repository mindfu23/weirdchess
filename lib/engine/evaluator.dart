import '../core/board.dart';
import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';

/// Position evaluation for the AI
class Evaluator {
  // Piece-square tables for 8x8 boards (standard chess)
  static const List<List<double>> pawnTable8 = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
    [0.1, 0.1, 0.2, 0.3, 0.3, 0.2, 0.1, 0.1],
    [0.05, 0.05, 0.1, 0.25, 0.25, 0.1, 0.05, 0.05],
    [0.0, 0.0, 0.0, 0.2, 0.2, 0.0, 0.0, 0.0],
    [0.05, -0.05, -0.1, 0.0, 0.0, -0.1, -0.05, 0.05],
    [0.05, 0.1, 0.1, -0.2, -0.2, 0.1, 0.1, 0.05],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  ];

  static const List<List<double>> knightTable8 = [
    [-0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5],
    [-0.4, -0.2, 0.0, 0.0, 0.0, 0.0, -0.2, -0.4],
    [-0.3, 0.0, 0.1, 0.15, 0.15, 0.1, 0.0, -0.3],
    [-0.3, 0.05, 0.15, 0.2, 0.2, 0.15, 0.05, -0.3],
    [-0.3, 0.0, 0.15, 0.2, 0.2, 0.15, 0.0, -0.3],
    [-0.3, 0.05, 0.1, 0.15, 0.15, 0.1, 0.05, -0.3],
    [-0.4, -0.2, 0.0, 0.05, 0.05, 0.0, -0.2, -0.4],
    [-0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5],
  ];

  static const List<List<double>> bishopTable8 = [
    [-0.2, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.2],
    [-0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.1, 0.0, 0.05, 0.1, 0.1, 0.05, 0.0, -0.1],
    [-0.1, 0.05, 0.05, 0.1, 0.1, 0.05, 0.05, -0.1],
    [-0.1, 0.0, 0.1, 0.1, 0.1, 0.1, 0.0, -0.1],
    [-0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, -0.1],
    [-0.1, 0.05, 0.0, 0.0, 0.0, 0.0, 0.05, -0.1],
    [-0.2, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.2],
  ];

  static const List<List<double>> rookTable8 = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.05, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.05],
    [-0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.05],
    [-0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.05],
    [-0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.05],
    [-0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.05],
    [-0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.05],
    [0.0, 0.0, 0.0, 0.05, 0.05, 0.0, 0.0, 0.0],
  ];

  static const List<List<double>> queenTable8 = [
    [-0.2, -0.1, -0.1, -0.05, -0.05, -0.1, -0.1, -0.2],
    [-0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.1, 0.0, 0.05, 0.05, 0.05, 0.05, 0.0, -0.1],
    [-0.05, 0.0, 0.05, 0.05, 0.05, 0.05, 0.0, -0.05],
    [0.0, 0.0, 0.05, 0.05, 0.05, 0.05, 0.0, -0.05],
    [-0.1, 0.05, 0.05, 0.05, 0.05, 0.05, 0.0, -0.1],
    [-0.1, 0.0, 0.05, 0.0, 0.0, 0.0, 0.0, -0.1],
    [-0.2, -0.1, -0.1, -0.05, -0.05, -0.1, -0.1, -0.2],
  ];

  static const List<List<double>> kingMiddleGameTable8 = [
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.3, -0.4, -0.4, -0.5, -0.5, -0.4, -0.4, -0.3],
    [-0.2, -0.3, -0.3, -0.4, -0.4, -0.3, -0.3, -0.2],
    [-0.1, -0.2, -0.2, -0.2, -0.2, -0.2, -0.2, -0.1],
    [0.2, 0.2, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2],
    [0.2, 0.3, 0.1, 0.0, 0.0, 0.1, 0.3, 0.2],
  ];

  // Piece-square tables for 10x10 boards (variants)
  static const List<List<double>> pawnTable10 = [
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

  static const List<List<double>> knightTable10 = [
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

  static const List<List<double>> bishopTable10 = [
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

  static const List<List<double>> kingMiddleGameTable10 = [
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
    final is8x8 = board.size == 8;

    // Add positional bonus
    final row = color == PieceColor.white ? pos.row : (board.size - 1 - pos.row);
    final col = pos.col;

    // Clamp indices for safety
    final maxIdx = board.size - 1;
    final safeRow = row.clamp(0, maxIdx);
    final safeCol = col.clamp(0, maxIdx);

    switch (piece.symbol) {
      case 'P':
        score += is8x8
            ? pawnTable8[safeRow][safeCol]
            : pawnTable10[safeRow][safeCol];
        break;
      case 'N':
        score += is8x8
            ? knightTable8[safeRow][safeCol]
            : knightTable10[safeRow][safeCol];
        break;
      case 'B':
        score += is8x8
            ? bishopTable8[safeRow][safeCol]
            : bishopTable10[safeRow][safeCol];
        break;
      case 'R':
        if (is8x8) score += rookTable8[safeRow][safeCol];
        break;
      case 'Q':
        if (is8x8) score += queenTable8[safeRow][safeCol];
        break;
      case 'K':
        score += is8x8
            ? kingMiddleGameTable8[safeRow][safeCol]
            : kingMiddleGameTable10[safeRow][safeCol];
        break;
      case 'M': // Marshal - encourage central placement
        final knightT = is8x8 ? knightTable8 : knightTable10;
        score += knightT[safeRow][safeCol] * 0.5;
        break;
      case 'C': // Cardinal - encourage central placement
        final bishopT = is8x8 ? bishopTable8 : bishopTable10;
        score += bishopT[safeRow][safeCol] * 0.5;
        break;
      case 'A': // Amazon (Zurafa)
        final knightT = is8x8 ? knightTable8 : knightTable10;
        score += knightT[safeRow][safeCol] * 0.3;
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
