import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/game_state.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import '../../variants/three_check.dart';
import '../../variants/variant_base.dart';

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
    final variant = ref.watch(selectedVariantProvider);

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

          // Three-Check counter
          if (variant.id == 'three_check') ...[
            _buildCheckCounter(gameState),
            const SizedBox(height: 12),
          ],

          // 10×10 non-standard piece guide
          if (variant.boardSize == 10) ...[
            _buildPieceGuide(variant),
            const SizedBox(height: 12),
          ],

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
                  final v = ref.read(selectedVariantProvider);
                  if (v.id == 'horde') {
                    ref
                        .read(pendingHordeSideSelectionProvider.notifier)
                        .set(true);
                  } else {
                    notifier.newGame(v);
                  }
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

  Widget _buildCheckCounter(GameState gameState) {
    final (whiteChecks, blackChecks) =
        ThreeCheckChess.getCheckCounts(gameState.variantData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Checks Given',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTextMuted,
          ),
        ),
        const SizedBox(height: 6),
        _buildCheckRow('White', whiteChecks),
        const SizedBox(height: 4),
        _buildCheckRow('Black', blackChecks),
        const Divider(height: 1, color: Color(0xFF4A5568)),
      ],
    );
  }

  Widget _buildCheckRow(String label, int count) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kTextMuted),
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? _kAccent : Colors.transparent,
              border: Border.all(
                color: i < count ? _kAccent : _kTextMuted,
                width: 1.5,
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 4),
        ],
        const SizedBox(width: 8),
        Text(
          '$count / 3',
          style: TextStyle(
            fontSize: 11,
            color: count >= 3 ? _kAccent : _kTextMuted,
            fontWeight: count >= 3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static const _standardSymbols = {'K', 'Q', 'R', 'B', 'N', 'P'};

  Widget _buildPieceGuide(ChessVariant variant) {
    final nonStandard = variant.pieceInfo.entries
        .where((e) => !_standardSymbols.contains(e.key))
        .toList();

    if (nonStandard.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PIECE GUIDE',
          style: TextStyle(
            fontFamily: 'Righteous',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kAccent,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: nonStandard.map((e) {
                final info = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          info.symbol,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary,
                              ),
                            ),
                            Text(
                              info.movementDescription,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF4A5568)),
      ],
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
