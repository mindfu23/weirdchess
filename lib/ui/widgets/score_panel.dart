import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/game_state.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

// ── Brand palette (mirrors home_screen / main.dart theme) ──────────────────
const _kBackground = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2D3542);
const _kTextPrimary = Color(0xFFF5E6D3);
const _kTextMuted = Color(0xFF9B8E85);
const _kAccent = Color(0xFFFF9B8A);

/// Panel showing game status, captured pieces, and controls
class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.watch(gameNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Turn indicator
          _buildTurnIndicator(gameState, notifier.isAIThinking),
          const SizedBox(height: 12),

          // Game result
          if (gameState.isGameOver) ...[
            _buildGameResult(gameState),
            const SizedBox(height: 12),
          ],

          // Captured pieces
          _buildCapturedPieces(gameState),
          const SizedBox(height: 12),

          // Move counter
          Text(
            'Move ${gameState.fullMoveNumber}',
            style: const TextStyle(fontSize: 14, color: _kTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed:
                    gameState.moveHistory.isEmpty ? null : notifier.undoMove,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Undo'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final variant = ref.read(selectedVariantProvider);
                  notifier.newGame(variant);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(GameState gameState, bool isAIThinking) {
    final turnText = gameState.currentTurn == PieceColor.white
        ? 'White to move'
        : 'Black to move';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gameState.currentTurn == PieceColor.white
                ? Colors.white
                : _kBackground,
            border: Border.all(color: _kTextMuted, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAIThinking ? 'AI thinking…' : turnText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kTextPrimary,
          ),
        ),
        if (isAIThinking) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kAccent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGameResult(GameState gameState) {
    String resultText;
    Color resultColor;

    switch (gameState.result) {
      case GameResult.whiteWins:
        resultText = 'White wins by checkmate!';
        resultColor = const Color(0xFF4CAF82);
        break;
      case GameResult.blackWins:
        resultText = 'Black wins by checkmate!';
        resultColor = const Color(0xFFFF6B6B);
        break;
      case GameResult.stalemate:
        resultText = 'Stalemate — Draw!';
        resultColor = _kAccent;
        break;
      case GameResult.draw:
        resultText = 'Draw!';
        resultColor = _kAccent;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: resultColor.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor.withAlpha(128)),
      ),
      child: Text(
        resultText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: resultColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCapturedPieces(GameState gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCapturedRow('White captured:', gameState.blackCaptured),
        const SizedBox(height: 4),
        _buildCapturedRow('Black captured:', gameState.whiteCaptured),
      ],
    );
  }

  Widget _buildCapturedRow(String label, List<Piece> pieces) {
    final sortedPieces = List<Piece>.from(pieces)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _kTextMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 2,
            children: sortedPieces
                .map((p) => Text(
                      p.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        // White pieces shown cream; black pieces slightly muted.
                        color: p.color == PieceColor.white
                            ? _kTextPrimary
                            : _kTextMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
