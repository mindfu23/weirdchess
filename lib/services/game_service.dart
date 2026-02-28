import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../variants/three_check.dart';
import '../variants/king_of_the_hill.dart';
import '../variants/atomic.dart';
import '../variants/chess960.dart';
import '../variants/horde.dart';
import '../variants/fog_of_war.dart';
import 'llm_service.dart';
import 'auth_service.dart';
import 'scoreboard_service.dart';

/// All available chess variants — 8×8 variants first, then 10×10.
final variantsProvider = Provider<List<ChessVariant>>((ref) {
  return [
    // ── 8×8 variants ──────────────────────────────────────────────────
    StandardChess(),
    AtomicChess(),
    Chess960(),
    ThreeCheckChess(),
    KingOfTheHillChess(),
    HordeChess(),
    FogOfWarChess(),
    // ── 10×10 variants ────────────────────────────────────────────────
    GrandChess(),
    OmegaChess(),
    DecimalChess(),
    HyderabadChess(),
    Jetan(),
  ];
});

/// Selected variant notifier — persists the last-chosen variant across reloads.
class SelectedVariantNotifier extends Notifier<ChessVariant> {
  static const _prefKey = 'selected_variant_id';

  @override
  ChessVariant build() {
    _restoreSaved();
    return StandardChess();
  }

  Future<void> _restoreSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);
    if (savedId == null) return;
    final variants = ref.read(variantsProvider);
    final match = variants.where((v) => v.id == savedId);
    if (match.isNotEmpty) state = match.first;
  }

  void select(ChessVariant variant) {
    state = variant;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefKey, variant.id));
  }
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
  bool build() => true;

  void toggle() => state = !state;
}

final chaosModeProvider =
    NotifierProvider<ChaosModeNotifier, bool>(ChaosModeNotifier.new);

// ── Atomic Chess ──────────────────────────────────────────────────────────────

/// Describes an atomic chess explosion event for the UI to animate.
class AtomicExplosionEvent {
  final Position center;
  final Set<Position> blastSquares;

  const AtomicExplosionEvent({
    required this.center,
    required this.blastSquares,
  });
}

/// Tracks all squares hit by atomic explosions this game. Cleared on new game.
class AtomicCratersNotifier extends Notifier<Set<Position>> {
  @override
  Set<Position> build() => {};

  void clear() => state = {};
  void addAll(Set<Position> positions) => state = {...state, ...positions};
}

final atomicCratersProvider =
    NotifierProvider<AtomicCratersNotifier, Set<Position>>(
        AtomicCratersNotifier.new);

/// Active explosion event; null when no animation is playing.
class AtomicExplosionEventNotifier extends Notifier<AtomicExplosionEvent?> {
  @override
  AtomicExplosionEvent? build() => null;

  void trigger(AtomicExplosionEvent event) => state = event;
  void clear() => state = null;
}

final atomicExplosionEventProvider =
    NotifierProvider<AtomicExplosionEventNotifier, AtomicExplosionEvent?>(
        AtomicExplosionEventNotifier.new);

// ── Human colour / Horde side selection ──────────────────────────────────────

/// Which colour the human player controls. Defaults to white.
/// Only Horde Chess supports changing this; all other variants use white.
class HumanColorNotifier extends Notifier<PieceColor> {
  @override
  PieceColor build() => PieceColor.white;

  void set(PieceColor color) => state = color;
}

final humanColorProvider =
    NotifierProvider<HumanColorNotifier, PieceColor>(HumanColorNotifier.new);

/// Set to true to signal the game screen to show the Horde side-selection dialog.
class PendingHordeSideSelectionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final pendingHordeSideSelectionProvider =
    NotifierProvider<PendingHordeSideSelectionNotifier, bool>(
        PendingHordeSideSelectionNotifier.new);

/// Whether the current game was restored from persistence (skip Horde dialog).
class GameRestoredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final gameRestoredProvider =
    NotifierProvider<GameRestoredNotifier, bool>(GameRestoredNotifier.new);

/// Describes a pigeon chaos teleport event for UI and commentary.
class PigeonEvent {
  final Position from;
  final Position to;
  final PieceColor pieceColor;
  final String pieceName;
  final String fromSquare;
  final String toSquare;
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

// ── Game persistence ────────────────────────────────────────────────────────

/// Persists in-progress game state and last commentary per variant.
class GamePersistenceService {
  static const _prefix = 'weirdchess_saved_game_';

  /// Save the current game + last commentary text + human colour for a variant.
  Future<void> saveGame(
    String variantId,
    GameState gameState,
    String? lastCommentary, {
    PieceColor? humanColor,
  }) async {
    if (gameState.isGameOver) {
      await clearGame(variantId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'gameState': gameState.toJson(),
      'lastCommentary': lastCommentary,
      if (humanColor != null)
        'humanColor': humanColor == PieceColor.white ? 'white' : 'black',
    });
    await prefs.setString('$_prefix$variantId', data);
  }

  /// Save only the commentary text for a variant (used when commentary arrives
  /// after the user has already navigated away).
  Future<void> saveCommentary(String variantId, String commentary) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('$_prefix$variantId');
    if (existing == null) return; // No saved game to attach commentary to
    final map = jsonDecode(existing) as Map<String, dynamic>;
    map['lastCommentary'] = commentary;
    await prefs.setString('$_prefix$variantId', jsonEncode(map));
  }

  /// Load saved game data (returns null if none exists).
  Future<Map<String, dynamic>?> loadGame(String variantId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$variantId');
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Check if a saved game exists for a variant.
  Future<bool> hasSavedGame(String variantId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$variantId');
  }

  /// Clear saved game for a variant.
  Future<void> clearGame(String variantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$variantId');
  }
}

final gamePersistenceProvider = Provider<GamePersistenceService>((ref) {
  return GamePersistenceService();
});

/// Whether a saved (in-progress) game exists for a given variant ID.
final hasSavedGameProvider =
    FutureProvider.family<bool, String>((ref, variantId) async {
  return ref.read(gamePersistenceProvider).hasSavedGame(variantId);
});

/// Game state notifier
class GameNotifier extends Notifier<GameState> {
  Position? _selectedPosition;
  List<Move> _selectedPieceMoves = [];
  bool _isAIThinking = false;

  /// Incremented when the game context changes (new game, build rebuild).
  /// Used to detect and handle stale async commentary responses.
  int _commentaryGeneration = 0;


  @override
  GameState build() {
    final variant = ref.watch(selectedVariantProvider);
    _selectedPosition = null;
    _selectedPieceMoves = [];
    _isAIThinking = false;
    _commentaryGeneration++;
    return variant.createNewGame();
  }

  Position? get selectedPosition => _selectedPosition;
  List<Move> get selectedPieceMoves => _selectedPieceMoves;
  bool get isAIThinking => _isAIThinking;

  /// Returns the set of fogged (non-visible) squares for the current player,
  /// or null when the active variant has no fog (full visibility).
  Set<Position>? get foggedSquares {
    final variant = ref.read(selectedVariantProvider);
    final visibleSquares =
        variant.getVisibleSquares(state.board, state.currentTurn);
    if (visibleSquares == null) return null;

    final all = <Position>{};
    for (int r = 0; r < state.board.size; r++) {
      for (int c = 0; c < state.board.size; c++) {
        all.add(Position(r, c));
      }
    }
    return all.difference(visibleSquares);
  }

  void newGame(ChessVariant variant) {
    _commentaryGeneration++;
    state = variant.createNewGame();
    _selectedPosition = null;
    _selectedPieceMoves = [];
    _isAIThinking = false;

    // Clear saved game — user explicitly started fresh.
    ref.read(gamePersistenceProvider).clearGame(variant.id);
    ref.invalidate(hasSavedGameProvider(variant.id));

    // Clear commentary and visual state for the new game.
    ref.read(commentaryProvider.notifier).clear();
    ref.read(atomicCratersProvider.notifier).clear();
    ref.read(atomicExplosionEventProvider.notifier).clear();

    // Clear any stale pigeon event so it doesn't bleed into the new game/variant.
    ref.read(pigeonEventProvider.notifier).clear();

    // If the AI should move first (human plays a non-first-turn colour), start AI.
    final playingAI = ref.read(playingAgainstAIProvider);
    final humanColor = ref.read(humanColorProvider);
    if (playingAI && !state.isGameOver && state.currentTurn != humanColor) {
      _makeAIMove();
    }
  }

  Future<void> onSquareTap(Position position) async {
    if (state.isGameOver || _isAIThinking) return;

    final playingAI = ref.read(playingAgainstAIProvider);
    final humanColor = ref.read(humanColorProvider);
    if (playingAI && state.currentTurn != humanColor) return;

    final piece = state.board.getPiece(position);
    final variant = ref.read(selectedVariantProvider);

    if (_selectedPosition != null) {
      final move = _selectedPieceMoves.firstWhere(
        (m) => m.to == position,
        orElse: () => Move(from: _selectedPosition!, to: position),
      );

      if (_selectedPieceMoves.any((m) => m.to == position)) {
        await _makeMove(move);
        return;
      }

      // If the king is in check and the user tapped a square that the
      // selected piece could reach but can't because it doesn't resolve
      // check, show a helpful message.
      if (state.board.isInCheck(state.currentTurn)) {
        final selectedPiece = state.board.getPiece(_selectedPosition!);
        if (selectedPiece != null) {
          final pseudoMoves =
              selectedPiece.getPseudoLegalMoves(state.board, _selectedPosition!);
          if (pseudoMoves.any((m) => m.to == position)) {
            ref
                .read(commentaryProvider.notifier)
                .setCommentary("Can't do that. Your king is in check.");
          }
        }
      }
    }

    if (piece != null && piece.color == state.currentTurn) {
      _selectedPosition = position;
      // Use variant-aware legal move generation for UI highlighting.
      _selectedPieceMoves = variant.getLegalMoves(state.board, position, piece);
      state = state.copy();
    } else {
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

      // Handle atomic explosion animation (awaited before AI moves).
      await _handleAtomicExplosion();

      bool pigeonFired = false;
      final variant = ref.read(selectedVariantProvider);
      final chaosEnabled = ref.read(chaosModeProvider);
      if (chaosEnabled &&
          variant.id == 'standard_chess' &&
          state.moveHistory.length >= 5 &&
          state.moveHistory.length % 5 == 0) {
        pigeonFired = _triggerPigeonChaos();
      }

      if (pigeonFired) {
        await Future.delayed(const Duration(seconds: 3));
      }

      _autoSave();

      final playingAI = ref.read(playingAgainstAIProvider);
      final humanColor = ref.read(humanColorProvider);
      if (playingAI && !state.isGameOver && state.currentTurn != humanColor) {
        _makeAIMove();
      }
    }
  }

  /// Detects if the last move triggered an atomic explosion, updates the crater
  /// provider, fires the animation event, and waits for the animation to complete.
  Future<void> _handleAtomicExplosion() async {
    final variant = ref.read(selectedVariantProvider);
    if (variant.id != 'atomic' || state.moveHistory.isEmpty) return;

    final lastRecord = state.moveHistory.last;
    if (lastRecord.capturedPiece == null) return;

    final blastPositions = <Position>{lastRecord.move.to};
    for (final (pos, _) in lastRecord.explosionCasualties) {
      blastPositions.add(pos);
    }

    ref.read(atomicCratersProvider.notifier).addAll(blastPositions);
    ref.read(atomicExplosionEventProvider.notifier).trigger(AtomicExplosionEvent(
      center: lastRecord.move.to,
      blastSquares: blastPositions,
    ));

    await Future.delayed(const Duration(milliseconds: 900));
    ref.read(atomicExplosionEventProvider.notifier).clear();
  }

  bool _triggerPigeonChaos() {
    final board = state.board;
    final random = Random();

    final candidates = <(Position, Piece)>[
      ...board.getPieces(PieceColor.white).where((p) => p.$2.symbol != 'K'),
      ...board.getPieces(PieceColor.black).where((p) => p.$2.symbol != 'K'),
    ];
    if (candidates.isEmpty) return false;

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

      final testBoard = board.copy();
      testBoard.removePiece(fromPos);
      testBoard.setPiece(toPos, piece);

      if (!testBoard.isInCheck(PieceColor.white) &&
          !testBoard.isInCheck(PieceColor.black)) {
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

    return false;
  }

  Future<void> _generatePigeonCommentary(PigeonEvent event) async {
    final auth = ref.read(authProvider);
    final llmConfig = ref.read(llmConfigProvider);
    if (!auth.isAuthenticated && llmConfig.directMode) return;
    if (!llmConfig.enabled) return;

    final variant = ref.read(selectedVariantProvider);
    final variantId = variant.id;
    final llmService = ref.read(llmServiceProvider);
    final commentaryNotifier = ref.read(commentaryProvider.notifier);

    commentaryNotifier.setLoading();

    final generation = _commentaryGeneration;


    final response = await llmService.generatePigeonCommentary(
      pieceName: event.pieceName,
      pieceColorName: event.pieceColor == PieceColor.white ? 'White' : 'Black',
      fromSquare: event.fromSquare,
      toSquare: event.toSquare,
      affectedAIPiece: event.affectedAIPiece,
      authHeader: auth.authHeader,
    );

    // If the user switched games while waiting, save commentary for later.
    if (generation != _commentaryGeneration) {
      if (!response.isError && response.text.isNotEmpty) {
        _saveCommentaryForVariant(variantId, response.text);
      }
      return;
    }

    if (response.isError) {
      commentaryNotifier.setError(response.text);
    } else {
      commentaryNotifier.setCommentary(response.text);
    }
  }

  Future<void> _makeAIMove() async {
    _isAIThinking = true;
    state = state.copy();

    ref.read(commentaryProvider.notifier).clear();

    final ai = ref.read(aiOpponentProvider);
    ai.difficulty = ref.read(aiDifficultyProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    final move = await ai.findBestMove(state);
    if (move != null) {
      final piece = state.board.getPiece(move.from);
      final capturedPiece = state.board.getPiece(move.to);

      final newState = state.copy();
      newState.makeMove(move);
      state = newState;

      // Show explosion animation when AI triggers an atomic capture.
      await _handleAtomicExplosion();

      if (piece != null) {
        _generateCommentary(move, piece, capturedPiece);
      }
    }

    _isAIThinking = false;
    state = state.copy();
    _autoSave();
  }

  Future<void> _generateCommentary(
      Move move, Piece piece, Piece? capturedPiece) async {
    final auth = ref.read(authProvider);
    final llmConfig = ref.read(llmConfigProvider);

    if (!auth.isAuthenticated && llmConfig.directMode) return;
    if (!llmConfig.enabled) return;

    final variant = ref.read(selectedVariantProvider);
    final variantId = variant.id;
    final llmService = ref.read(llmServiceProvider);
    final commentaryNotifier = ref.read(commentaryProvider.notifier);

    commentaryNotifier.setLoading();

    final generation = _commentaryGeneration;


    final response = await llmService.generateCommentary(
      variantId: variantId,
      move: move,
      piece: piece,
      color: PieceColor.black,
      capturedPiece: capturedPiece,
      isCheck: state.board.isInCheck(PieceColor.white),
      isCheckmate: state.result == GameResult.blackWins,
      authHeader: auth.authHeader,
    );

    // If the user switched games while waiting, save commentary for later.
    if (generation != _commentaryGeneration) {
      if (!response.isError && response.text.isNotEmpty) {
        _saveCommentaryForVariant(variantId, response.text);
      }
      return;
    }

    if (response.isError) {
      commentaryNotifier.setError(response.text);
    } else {
      commentaryNotifier.setCommentary(response.text);
    }
  }

  void undoMove() {
    if (state.moveHistory.isEmpty) return;

    final newState = state.copy();
    newState.undoMove();

    final playingAI = ref.read(playingAgainstAIProvider);
    if (playingAI && newState.moveHistory.isNotEmpty) {
      newState.undoMove();
    }

    state = newState;
    _selectedPosition = null;
    _selectedPieceMoves = [];
  }

  void clearSelection() {
    _selectedPosition = null;
    _selectedPieceMoves = [];
    state = state.copy();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  /// Attempt to restore a saved game for the given variant.
  /// Returns true if a game was restored, false if a new game was started.
  Future<bool> restoreGame(ChessVariant variant) async {
    final persistence = ref.read(gamePersistenceProvider);
    final savedData = await persistence.loadGame(variant.id);

    if (savedData == null) {
      newGame(variant);
      return false;
    }

    final gameJson = savedData['gameState'] as String?;
    if (gameJson == null) {
      newGame(variant);
      return false;
    }

    try {
      final restoredState = GameState.fromJson(gameJson, variant);
      // Don't increment _commentaryGeneration — we want to accept any
      // pending commentary for this variant.
      state = restoredState;
      _selectedPosition = null;
      _selectedPieceMoves = [];
      _isAIThinking = false;

      // Restore the human colour that was active when the game was saved.
      final savedColor = savedData['humanColor'] as String?;
      if (savedColor != null) {
        ref.read(humanColorProvider.notifier).set(
              savedColor == 'black' ? PieceColor.black : PieceColor.white,
            );
      }

      // Restore last commentary text if available.
      final lastCommentary = savedData['lastCommentary'] as String?;
      final commentaryNotifier = ref.read(commentaryProvider.notifier);
      if (lastCommentary != null && lastCommentary.isNotEmpty) {
        commentaryNotifier.setCommentary(lastCommentary);
      } else {
        commentaryNotifier.clear();
      }

      // Clear visual state from other variants.
      ref.read(atomicCratersProvider.notifier).clear();
      ref.read(atomicExplosionEventProvider.notifier).clear();
      ref.read(pigeonEventProvider.notifier).clear();

      // If it's the AI's turn, trigger its move.
      final playingAI = ref.read(playingAgainstAIProvider);
      final humanColor = ref.read(humanColorProvider);
      if (playingAI && !state.isGameOver && state.currentTurn != humanColor) {
        _makeAIMove();
      }

      return true;
    } catch (e) {
      // If restoration fails, start a new game and clear bad data.
      await persistence.clearGame(variant.id);
      newGame(variant);
      return false;
    }
  }

  /// Save current game state + commentary after each move.
  /// Records scoreboard result when a game finishes.
  void _autoSave() {
    final variant = ref.read(selectedVariantProvider);
    final persistence = ref.read(gamePersistenceProvider);
    final commentary = ref.read(commentaryProvider);

    if (state.isGameOver) {
      persistence.clearGame(variant.id);

      // Record win/loss/draw on the scoreboard.
      final humanColor = ref.read(humanColorProvider);
      ref.read(scoreboardProvider.notifier).recordResult(
            variant.id,
            state.result,
            humanColor,
          );
    } else {
      final commentaryText =
          (!commentary.isLoading && !commentary.isError && commentary.text.isNotEmpty)
              ? commentary.text
              : null;
      final humanColor = ref.read(humanColorProvider);
      persistence.saveGame(variant.id, state, commentaryText,
          humanColor: humanColor);
    }

    // Invalidate the hasSavedGame cache so UI badges update.
    ref.invalidate(hasSavedGameProvider(variant.id));
  }

  /// Save a late-arriving commentary response to a variant's persistence.
  void _saveCommentaryForVariant(String variantId, String text) {
    ref.read(gamePersistenceProvider).saveCommentary(variantId, text);
  }
}

final gameNotifierProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

final isSelectedProvider = Provider.family<bool, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  return notifier.selectedPosition == position;
});

final isValidMoveProvider = Provider.family<bool, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  return notifier.selectedPieceMoves.any((m) => m.to == position);
});

final moveForPositionProvider =
    Provider.family<Move?, Position>((ref, position) {
  final notifier = ref.watch(gameNotifierProvider.notifier);
  try {
    return notifier.selectedPieceMoves.firstWhere((m) => m.to == position);
  } catch (_) {
    return null;
  }
});
