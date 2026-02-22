import 'board.dart';
import 'game_result.dart';
import 'move.dart';
import 'piece.dart';

/// Thin interface for variant-specific rule hooks.
///
/// Stored in [GameState] to avoid circular imports between
/// game_state.dart and variant_base.dart (which imports GameState).
/// Concrete implementations live in lib/variants/.
abstract class ChessVariantInterface {
  /// Generate legal moves for a piece, applying variant-specific rules.
  /// Default implementation uses standard check-filtering.
  List<Move> getLegalMoves(Board board, Position pos, Piece piece);

  /// Apply board effects after a capture (e.g., Atomic chess explosions).
  /// Returns the list of additionally destroyed (position, piece) pairs so
  /// that [GameState.undoMove] can restore the board correctly.
  List<(Position, Piece)> applyPostCaptureEffect(Board board, Move move);

  /// Update variant-specific data after a move is fully executed.
  /// Called with [justMoved] = the color that made the move (before turn switch).
  /// Example: Three-Check increments the check counter here.
  void updateVariantData(
    Board board,
    Move move,
    PieceColor justMoved,
    Map<String, dynamic> data,
  );

  /// Check variant-specific end conditions after a move is applied.
  /// [currentTurn] is the player about to move (turn has already switched).
  /// Return a [GameResult] to override the standard result, or null to
  /// let the standard checkmate/stalemate logic stand.
  /// NOTE: this always runs even when standard logic already set a result,
  /// so variants can override (e.g., Atomic overrides stalemate when a king
  /// was exploded).
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  );

  /// Whether this color requires a king on the board for check/stalemate rules.
  /// Horde chess: white has no king, so requiresKing(white) == false.
  bool requiresKing(PieceColor color);

  /// Squares visible to [color] under fog-of-war rules.
  /// Returns null for full visibility (standard rules).
  Set<Position>? getVisibleSquares(Board board, PieceColor color);

  /// Create a piece by symbol for promotion or board setup.
  Piece createPiece(String symbol, PieceColor color);
}
