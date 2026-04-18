import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/board.dart';
import '../../core/game_state.dart';
import '../../core/move.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';
import '../../variants/three_check.dart';
import '../../variants/variant_base.dart';
import 'piece_info_panel.dart';
import 'piece_widget.dart';

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

    // Fixed-at-top: turn indicator, check counter, full piece guide.
    final topChildren = <Widget>[
      _buildTurnIndicator(gameState, notifier.isAIThinking),
      const SizedBox(height: 12),
      if (variant.id == 'three_check') ...[
        _buildCheckCounter(gameState),
        const SizedBox(height: 12),
      ],
      if (variant.boardSize == 10) ...[
        _buildPieceGuide(variant),
        const SizedBox(height: 12),
      ],
    ];

    // Scrollable-if-overflow: everything below the piece guide.
    final bottomChildren = <Widget>[
      if (gameState.isGameOver) ...[
        _buildGameResult(gameState),
        const SizedBox(height: 12),
      ],
      _buildCapturedPieces(gameState),
      const SizedBox(height: 12),
      Text(
        'Move ${gameState.fullMoveNumber}',
        style: const TextStyle(fontSize: 14, color: _kTextMuted),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 8),
      _buildColorToggle(ref, notifier, variant),
      if (variant.id == 'jetan') ...[
        const SizedBox(height: 8),
        _buildJetanRulesInfo(gameState),
      ],
      const PieceInfoPanel(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      // LayoutBuilder lets us detect the landscape (bounded) vs portrait
      // (unbounded — inside an outer SingleChildScrollView) case.
      // Landscape splits top-fixed / bottom-scrollable so the full piece
      // guide is always visible; portrait lets the outer scroll handle it.
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.hasBoundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...topChildren,
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bottomChildren,
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...topChildren, ...bottomChildren],
          );
        },
      ),
    );
  }

  Widget _buildJetanRulesInfo(GameState gameState) {
    final whiteUsed =
        gameState.variantData['princessEscapeUsed_white'] == true;
    final blackUsed =
        gameState.variantData['princessEscapeUsed_black'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JETAN RULES',
          style: TextStyle(
            fontFamily: 'Righteous',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kAccent,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '\u2022 Panthans do not promote',
          style: TextStyle(fontSize: 11, color: _kTextMuted),
        ),
        const SizedBox(height: 4),
        const Text(
          '\u2022 Princess Escape: Once per game, jump to any unoccupied, unthreatened square',
          style: TextStyle(fontSize: 11, color: _kTextMuted),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 10),
            Text(
              'White: ${whiteUsed ? "Used" : "Available"}',
              style: TextStyle(
                fontSize: 10,
                color: whiteUsed ? _kTextMuted : _kAccent,
                fontWeight:
                    whiteUsed ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Black: ${blackUsed ? "Used" : "Available"}',
              style: TextStyle(
                fontSize: 10,
                color: blackUsed ? _kTextMuted : _kAccent,
                fontWeight:
                    blackUsed ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: Color(0xFF4A5568)),
      ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: nonStandard.map((e) {
            final info = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 2),
                    child: PieceWidget(
                      piece: _DisplayPiece(
                        symbol: e.key, // Use map key (actual piece symbol), not display symbol
                        color: PieceColor.white,
                      ),
                      size: 24,
                      pieceSet: variant.pieceSet,
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

  Widget _buildColorToggle(
      WidgetRef ref, dynamic notifier, ChessVariant variant) {
    final humanColor = ref.watch(humanColorProvider);
    final colorChosen = ref.watch(colorChosenProvider);

    void selectColor(PieceColor color) {
      if (colorChosen) return; // locked after first pick
      ref.read(humanColorProvider.notifier).set(color);
      ref.read(colorChosenProvider.notifier).set(true);
      if (color != PieceColor.white) {
        // Restart so the AI takes the first move.
        if (variant.id == 'horde') {
          ref
              .read(pendingHordeSideSelectionProvider.notifier)
              .set(true);
        } else {
          notifier.newGame(variant);
          // Re-lock — newGame resets colorChosen, so set it again.
          ref.read(colorChosenProvider.notifier).set(true);
        }
      }
    }

    Widget radioOption(PieceColor color) {
      final isSelected = colorChosen && humanColor == color;
      final label = color == PieceColor.white ? 'White' : 'Black';
      final dotColor =
          color == PieceColor.white ? Colors.white : _kBackground;

      return GestureDetector(
        onTap: colorChosen ? null : () => selectColor(color),
        child: Opacity(
          opacity: colorChosen && !isSelected ? 0.4 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? dotColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _kAccent : _kTextMuted,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _kTextPrimary : _kTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Play as:',
          style: TextStyle(
            fontSize: 13,
            color: colorChosen ? _kTextMuted : _kAccent,
            fontWeight:
                colorChosen ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        radioOption(PieceColor.white),
        const SizedBox(width: 16),
        radioOption(PieceColor.black),
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

/// Lightweight Piece subclass for display-only purposes (piece guide thumbnails).
class _DisplayPiece extends Piece {
  _DisplayPiece({required super.symbol, required super.color})
      : super(name: '', value: 0);

  @override
  List<Move> getPseudoLegalMoves(Board board, Position position) => [];

  @override
  Piece copy() => _DisplayPiece(symbol: symbol, color: color);
}
