import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_state.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../engine/ai_opponent.dart';
import '../variants/variant_base.dart';
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
  ChessVariant build() => GrandChess();

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
        _makeMove(move);
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

  void _makeMove(Move move) {
    final newState = state.copy();
    if (newState.makeMove(move)) {
      state = newState;
      _selectedPosition = null;
      _selectedPieceMoves = [];

      // AI's turn
      final playingAI = ref.read(playingAgainstAIProvider);
      if (playingAI && !state.isGameOver && state.currentTurn == PieceColor.black) {
        _makeAIMove();
      }
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
    if (!auth.isAuthenticated) return;

    final llmConfig = ref.read(llmConfigProvider);
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
