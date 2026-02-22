import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../core/variant_interface.dart';

/// Abstract base class for all chess variants.
/// Implements [ChessVariantInterface] with standard-chess defaults so
/// subclasses only need to override what actually differs.
abstract class ChessVariant implements ChessVariantInterface {
  /// Variant identifier
  String get id;

  /// Display name
  String get name;

  /// Short description
  String get description;

  /// Board size (e.g., 10 for 10x10)
  int get boardSize;

  /// Light square color
  Color get lightSquareColor;

  /// Dark square color
  Color get darkSquareColor;

  /// URL to full rules
  String get rulesUrl;

  /// Create initial board setup
  Board createInitialBoard();

  /// Create a new game state with initial setup, wiring in this variant as
  /// the rule-hook provider.
  GameState createNewGame() {
    return GameState(
      board: createInitialBoard(),
      variantName: id,
      variant: this,
    );
  }

  /// Create a piece by symbol for this variant (used for promotion).
  @override
  Piece createPiece(String symbol, PieceColor color);

  /// Get promotion options for pawns
  List<String> get promotionOptions;

  /// Brief rules summary for display
  String get rulesSummary;

  /// Get piece info including name and movement description
  Map<String, PieceInfo> get pieceInfo;

  // ── ChessVariantInterface default implementations ───────────────────────

  /// Standard check-filtering. Override for Atomic, etc.
  @override
  List<Move> getLegalMoves(Board board, Position pos, Piece piece) {
    return piece.getLegalMoves(board, pos);
  }

  /// No post-capture board effects by default.
  @override
  List<(Position, Piece)> applyPostCaptureEffect(Board board, Move move) {
    return const [];
  }

  /// No variant-specific data to update by default.
  @override
  void updateVariantData(
    Board board,
    Move move,
    PieceColor justMoved,
    Map<String, dynamic> data,
  ) {}

  /// No variant-specific end condition by default.
  @override
  GameResult? checkVariantResult(
    Board board,
    PieceColor currentTurn,
    Map<String, dynamic> data,
  ) =>
      null;

  /// All standard variants require a king.
  @override
  bool requiresKing(PieceColor color) => true;

  /// Full board visibility by default (no fog of war).
  @override
  Set<Position>? getVisibleSquares(Board board, PieceColor color) => null;
}

/// Information about a piece type for the info panel.
class PieceInfo {
  final String name;
  final String symbol;
  final int value;
  final String movementDescription;
  final List<String> movementDiagram;

  const PieceInfo({
    required this.name,
    required this.symbol,
    required this.value,
    required this.movementDescription,
    this.movementDiagram = const [],
  });
}
