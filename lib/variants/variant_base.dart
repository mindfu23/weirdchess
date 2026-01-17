import 'package:flutter/material.dart';
import '../core/board.dart';
import '../core/game_state.dart';
import '../core/piece.dart';

/// Abstract base class for all chess variants
abstract class ChessVariant {
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

  /// Create a new game state with initial setup
  GameState createNewGame() {
    return GameState(
      board: createInitialBoard(),
      variantName: id,
    );
  }

  /// Create a piece by symbol for this variant
  Piece createPiece(String symbol, PieceColor color);

  /// Get promotion options for pawns
  List<String> get promotionOptions;

  /// Brief rules summary for display
  String get rulesSummary;

  /// Get piece info including name and movement description
  Map<String, PieceInfo> get pieceInfo;
}

/// Information about a piece type
class PieceInfo {
  final String name;
  final String symbol;
  final int value;
  final String movementDescription;
  final List<String> movementDiagram; // ASCII art representation

  const PieceInfo({
    required this.name,
    required this.symbol,
    required this.value,
    required this.movementDescription,
    this.movementDiagram = const [],
  });
}
