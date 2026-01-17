import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/game_state.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
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
            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                : Colors.grey[800],
            border: Border.all(color: Colors.grey[600]!, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAIThinking ? 'AI thinking...' : turnText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isAIThinking) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
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
        resultColor = Colors.green;
        break;
      case GameResult.blackWins:
        resultText = 'Black wins by checkmate!';
        resultColor = Colors.red;
        break;
      case GameResult.stalemate:
        resultText = 'Stalemate - Draw!';
        resultColor = Colors.orange;
        break;
      case GameResult.draw:
        resultText = 'Draw!';
        resultColor = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: resultColor.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor),
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        color: p.color == PieceColor.white
                            ? Colors.grey[600]
                            : Colors.grey[800],
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
