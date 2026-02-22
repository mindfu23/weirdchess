import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../engine/ai_opponent.dart';
import '../variants/variant_base.dart';
import '../variants/standard_chess.dart';
import '../variants/grand_chess.dart';
import '../variants/hyderabad_chess.dart';
import '../variants/jetan.dart';
import '../variants/omega_chess.dart';
import '../variants/decimal_chess.dart';
import 'llm_service.dart';
import 'auth_service.dart';

/// Available variants
final variantsProvider = Provider<List<ChessVariant>>((ref) {
  return [
    StandardChess(),
    GrandChess(),
    OmegaChess(),
    DecimalChess(),
    HyderabadChess(),
    Jetan(),
  ];
});

/// Selected variant notifier
class SelectedVariantNotifier extends Notifier<ChessVariant> {
  @override
  ChessVariant build() => StandardChess();

  void select(ChessVariant variant) => state = variant;
}

final selectedVariantProvider =
    NotifierProvider<SelectedVariantNotifier, ChessVariant>(
        SelectedVariantNotifier.new);

/// AI opponent
final aiOpponentProvider = Provider<AIOpponent>((ref) {
  return AIOpponent(difficulty: AIDifficulty.easy);
});

/// AI difficulty notifier
class AIDifficultyNotifier extends Notifier<AIDifficulty> {
  @override
  AIDifficulty build() => AIDifficulty.easy;

  void set(AIDifficulty difficulty) => state = difficulty;
}

final aiDifficultyProvider =
    NotifierProvider<AIDifficultyNotifier, AIDifficulty>(
        AIDifficultyNotifier.new);

/// Playing against AI notifier
class PlayingAgainstAINotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final playingAgainstAIProvider =
    NotifierProvider<PlayingAgainstAINotifier, bool>(
        PlayingAgainstAINotifier.new);

/// Chaos (pigeon) mode toggle — Standard Chess only
class ChaosModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final chaosModeProvider =
    NotifierProvider<ChaosModeNotifier, bool>(ChaosModeNotifier.new);

/// Describes a pigeon chaos teleport event for UI and commentary.
class PigeonEvent {
  final Position from;
  final Position to;
  final PieceColor pieceColor;
  final String pieceName;
  final String fromSquare;
  final String toSquare;

  /// True when the teleported piece belonged to the AI (Black).
  final bool affectedAIPiece;

  const PigeonEvent({
    required this.from,
    required this.to,
    required this.pieceColor,
    required this.pieceName,
    required this.fromSquare,
    required this.toSquare,
    required this.affectedAIPiece,
  });
}

/// Holds the active pigeon event; null when no event is in progress.
class PigeonEventNotifier extends Notifier<PigeonEvent?> {
  @override
  PigeonEvent? build() => null;

  void trigger(PigeonEvent event) => state = event;
  void clear() => state = null;
}

final pigeonEventProvider =
    NotifierProvider<PigeonEventNotifier, PigeonEvent?>(
        PigeonEventNotifier.new);

/// Game state notifier
class GameNotifier extends Notifier<GameState> {
  Position? _selectedPosition;
  List<Move> _selectedPieceMoves = [];
  bool _isAIThinking = false;

  @override
  GameState build() {
    final variant = ref.watch(selectedVariantProvider);
    // Reset selection state when variant changes
    _selectedPosition = null;
    _selectedPieceMoves = [];
    _isAIThinking = false;
    return variant.createNewGame();
  }

  Position? get selectedPosition => _selectedPosition;
  List<Move> get selectedPieceMoves => _selectedPieceMoves;
  bool get isAIThinking => _isAIThinking;

  /// Start a new game with the given variant
  void newGame(ChessVariant variant) {
    state = variant.createNewGame();
    _selectedPosition = null;
    _selectedPieceMoves = [];
    _isAIThinking = false;
  }

  /// Handle square tap
  Future<void> onSquareTap(Position position) async {
    if (state.isGameOver || _isAIThinking) return;

    final playingAI = ref.read(playingAgainstAIProvider);
    if (playingAI && state.currentTurn == PieceColor.black) return;

    final piece = state.board.getPiece(position);

    // If a piece is already selected
    if (_selectedPosition != null) {
      // Check if this is a valid move destination
      final move = _selectedPieceMoves.firstWhere(
        (m) => m.to == position,
        orElse: () => Move(from: _selectedPosition!, to: position),
      );

      if (_selectedPieceMoves.any((m) => m.to == position)) {
        // Make the move
        await _makeMove(move);
        return;
      }
    }

    // Select a new piece if it belongs to current player
    if (piece != null && piece.color == state.currentTurn) {
      _selectedPosition = position;
      _selectedPieceMoves = piece.getLegalMoves(state.board, position);
      state = state.copy(); // Trigger rebuild
    } else {
      // Deselect
      _selectedPosition = null;
      _selectedPieceMoves = [];
      state = state.copy();
    }
  }

  Future<void> _makeMove(Move move) async {
    final newState = state.copy();
    if (newState.makeMove(move)) {
      state = newState;
      _selectedPosition = null;
      _selectedPieceMoves = [];

      // Check for pigeon chaos event (Standard Chess only, every 5 half-moves)
      bool pigeonFired = false;
      final variant = ref.read(selectedVariantProvider);
      final chaosEnabled = ref.read(chaosModeProvider);
      if (chaosEnabled &&
          variant.id == 'standard_chess' &&
          state.moveHistory.length % 5 == 0) {
        pigeonFired = _triggerPigeonChaos();
      }

      // If a pigeon fired, delay the AI response so the flash and
      // commentary have time to be seen before the AI starts thinking.
      if (pigeonFired) {
        await Future.delayed(const Duration(seconds: 3));
      }

      // AI's turn
      final playingAI = ref.read(playingAgainstAIProvider);
      if (playingAI && !state.isGameOver && state.currentTurn == PieceColor.black) {
        _makeAIMove();
      }
    }
  }

  /// Teleport a random non-king piece to a random empty square.
  /// Retries up to 10 times to avoid leaving either king in check.
  /// Returns true if the event fired successfully.
  bool _triggerPigeonChaos() {
    final board = state.board;
    final random = Random();

    // All non-king pieces from both sides are candidates
    final candidates = <(Position, Piece)>[
      ...board.getPieces(PieceColor.white).where((p) => p.$2.symbol != 'K'),
      ...board.getPieces(PieceColor.black).where((p) => p.$2.symbol != 'K'),
    ];
    if (candidates.isEmpty) return false;

    // Collect all empty squares
    final emptySquares = <Position>[];
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        final pos = Position(row, col);
        if (board.getPiece(pos) == null) emptySquares.add(pos);
      }
    }
    if (emptySquares.isEmpty) return false;

    const maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final (fromPos, piece) = candidates[random.nextInt(candidates.length)];
      final toPos = emptySquares[random.nextInt(emptySquares.length)];

      if (fromPos == toPos) continue;

      // Verify this doesn't leave either king in check
      final testBoard = board.copy();
      testBoard.removePiece(fromPos);
      testBoard.setPiece(toPos, piece);

      if (!testBoard.isInCheck(PieceColor.white) &&
          !testBoard.isInCheck(PieceColor.black)) {
        // Apply the teleport
        final newState = state.copy();
        newState.board.removePiece(fromPos);
        newState.board.setPiece(toPos, piece);
        state = newState;

        final event = PigeonEvent(
          from: fromPos,
          to: toPos,
          pieceColor: piece.color,
          pieceName: piece.name,
          fromSquare: fromPos.toAlgebraic(board.size),
          toSquare: toPos.toAlgebraic(board.size),
          affectedAIPiece: piece.color == PieceColor.black,
        );

        ref.read(pigeonEventProvider.notifier).trigger(event);
        _generatePigeonCommentary(event);
        return true;
      }
    }

    return false; // Couldn't find a safe teleport — skip this time
  }

  /// Ask the LLM to comment on the pigeon disruption.
  Future<void> _generatePigeonCommentary(PigeonEvent event) async {
    final auth = ref.read(authProvider);
    final llmConfig = ref.read(llmConfigProvider);
    if (!auth.isAuthenticated && llmConfig.directMode) return;
    if (!llmConfig.enabled) return;

    final llmService = ref.read(llmServiceProvider);
    final commentaryNotifier = ref.read(commentaryProvider.notifier);

    commentaryNotifier.setLoading();

    final response = await llmService.generatePigeonCommentary(
      pieceName: event.pieceName,
      pieceColorName: event.pieceColor == PieceColor.white ? 'White' : 'Black',
      fromSquare: event.fromSquare,
      toSquare: event.toSquare,
      affectedAIPiece: event.affectedAIPiece,
      authHeader: auth.authHeader,
    );

    if (response.isError) {
      commentaryNotifier.setError(response.text);
    } else {
      commentaryNotifier.setCommentary(response.text);
    }
  }

  Future<void> _makeAIMove() async {
    _isAIThinking = true;
    state = state.copy(); // Trigger rebuild to show thinking indicator

    // Clear previous commentary
    ref.read(commentaryProvider.notifier).clear();

    final ai = ref.read(aiOpponentProvider);
    ai.difficulty = ref.read(aiDifficultyProvider);

    // Small delay so UI can update
    await Future.delayed(const Duration(milliseconds: 100));

    final move = await ai.findBestMove(state);
    if (move != null) {
      // Get piece and capture info before making move
      final piece = state.board.getPiece(move.from);
      final capturedPiece = state.board.getPiece(move.to);

      final newState = state.copy();
      newState.makeMove(move);
      state = newState;

      // Generate AI commentary
      if (piece != null) {
        _generateCommentary(move, piece, capturedPiece);
      }
    }

    _isAIThinking = false;
    state = state.copy();
  }

  /// Generate LLM commentary for a move.
  Future<void> _generateCommentary(Move move, Piece piece, Piece? capturedPiece) async {
    final auth = ref.read(authProvider);
    final llmConfig = ref.read(llmConfigProvider);

    // Allow commentary if:
    // - We have a client-side API key (isAuthenticated), OR
    // - We're in Netlify mode (directMode: false) where server has the API key
    if (!auth.isAuthenticated && llmConfig.directMode) return;

    if (!llmConfig.enabled) return;

    final variant = ref.read(selectedVariantProvider);
    final llmService = ref.read(llmServiceProvider);
    final commentaryNotifier = ref.read(commentaryProvider.notifier);

    commentaryNotifier.setLoading();

    final response = await llmService.generateCommentary(
      variantId: variant.id,
      move: move,
      piece: piece,
      color: PieceColor.black, // AI is always black
      capturedPiece: capturedPiece,
      isCheck: state.board.isInCheck(PieceColor.white),
      isCheckmate: state.result == GameResult.blackWins,
      authHeader: auth.authHeader,
    );

    if (response.isError) {
      commentaryNotifier.setError(response.text);
    } else {
      commentaryNotifier.setCommentary(response.text);
    }
  }

  /// Undo last move
  void undoMove() {
    if (state.moveHistory.isEmpty) return;

    final newState = state.copy();
    newState.undoMove();

    // If playing against AI, undo AI's move too
    final playingAI = ref.read(playingAgainstAIProvider);
    if (playingAI && newState.moveHistory.isNotEmpty) {
      newState.undoMove();
    }

    state = newState;
    _selectedPosition = null;
    _selectedPieceMoves = [];
  }

  /// Clear selection
  void clearSelection() {
    _selectedPosition = null;
    _selectedPieceMoves = [];
    state = state.copy();
  }
}

/// Provider for game state
final gameNotifierProvider = NotifierProvider<GameNotifier, GameState>(
    GameNotifier.new);

/// Whether a position is selected
final isSelectedProvider = Provider.family<bool, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  return notifier.selectedPosition == position;
});

/// Whether a position is a valid move destination
final isValidMoveProvider = Provider.family<bool, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  return notifier.selectedPieceMoves.any((m) => m.to == position);
});

/// Get move for a destination (for highlighting captures)
final moveForPositionProvider = Provider.family<Move?, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  try {
    return notifier.selectedPieceMoves.firstWhere((m) => m.to == position);
  } catch (_) {
    return null;
  }
});
