import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/piece.dart';
import '../../engine/ai_opponent.dart';
import '../../services/game_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_panel.dart';

import '../widgets/commentary_widget.dart';
import '../widgets/pigeon_flash_overlay.dart';

/// Main game screen
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Show side-selection for Horde on first load (covers home-screen nav,
    // hot-reload, and any direct entry to the game screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final variant = ref.read(selectedVariantProvider);
      final wasRestored = ref.read(gameRestoredProvider);
      if (variant.id == 'horde' && !wasRestored) {
        // Clear the pending flag so ref.listen doesn't double-trigger.
        ref.read(pendingHordeSideSelectionProvider.notifier).set(false);
        _showHordeSideDialog();
      }
      // Reset the restored flag so future navigations behave normally.
      ref.read(gameRestoredProvider.notifier).set(false);
    });
  }

  void _showHordeSideDialog() {
    final variant = ref.read(selectedVariantProvider);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D3542),
        title: const Text(
          'Choose Your Side',
          style: TextStyle(
            fontFamily: 'Righteous',
            color: Color(0xFFF5E6D3),
          ),
        ),
        content: const Text(
          'White = the Horde (36 pawns)\nBlack = the defending Army',
          style: TextStyle(color: Color(0xFF9B8E85), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(humanColorProvider.notifier).set(PieceColor.white);
              ref.read(gameNotifierProvider.notifier).newGame(variant);
              Navigator.pop(ctx);
            },
            child: const Text(
              '♙ Play Horde (White)',
              style: TextStyle(color: Color(0xFFF5E6D3)),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref.read(humanColorProvider.notifier).set(PieceColor.black);
              ref.read(gameNotifierProvider.notifier).newGame(variant);
              Navigator.pop(ctx);
            },
            child: const Text('♟ Play Army (Black)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for the pending-dialog flag set by home screen or score panel.
    ref.listen<bool>(pendingHordeSideSelectionProvider, (prev, next) {
      if (next && mounted) {
        ref.read(pendingHordeSideSelectionProvider.notifier).set(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showHordeSideDialog();
        });
      }
    });

    final variant = ref.watch(selectedVariantProvider);
    final difficulty = ref.watch(aiDifficultyProvider);
    final chaosEnabled = ref.watch(chaosModeProvider);
    final pigeonEvent = ref.watch(pigeonEventProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(variant.name),
            Text(
              variant.description,
              style: const TextStyle(
                fontFamily: 'Righteous',
                fontSize: 12,
                color: Color(0xFF9B8E85),
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/?tab=${variant.boardSize == 10 ? 1 : 0}'),
        ),
        actions: [
          // Pigeon chaos toggle — Standard Chess only.
          if (variant.id == 'standard_chess')
            TextButton.icon(
              onPressed: () {
                ref.read(chaosModeProvider.notifier).toggle();
                // Clear stale pigeon event when toggling off so the overlay
                // doesn't re-appear when the user toggles back on.
                if (!ref.read(chaosModeProvider)) {
                  ref.read(pigeonEventProvider.notifier).clear();
                }
              },
              icon: Icon(
                Icons.air,
                size: 18,
                color: chaosEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100),
              ),
              label: Text(
                chaosEnabled ? 'Random pigeon attack on' : 'Random pigeon attack off',
                style: TextStyle(
                  fontSize: 12,
                  color: chaosEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(100),
                ),
              ),
            ),
          // Difficulty selector
          PopupMenuButton<AIDifficulty>(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Difficulty',
            onSelected: (value) {
              ref.read(aiDifficultyProvider.notifier).set(value);
            },
            itemBuilder: (context) => [
              _buildDifficultyItem(AIDifficulty.beginner, 'Beginner', difficulty),
              _buildDifficultyItem(AIDifficulty.easy, 'Easy', difficulty),
              _buildDifficultyItem(AIDifficulty.medium, 'Medium', difficulty),
              _buildDifficultyItem(AIDifficulty.hard, 'Hard', difficulty),
            ],
          ),
          // Rules button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Rules',
            onPressed: () => _showRulesDialog(context, variant),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main game content with commentary above board
            _buildGameContent(context),
            // Pigeon chaos overlay — Standard Chess + chaos enabled only
            if (pigeonEvent != null &&
                variant.id == 'standard_chess' &&
                chaosEnabled)
              Positioned.fill(
                child: PigeonFlashOverlay(event: pigeonEvent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          // Landscape / wide layout
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Speech bubble commentary above the board
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxHeight - 32,
                        ),
                        child: const CommentarySpeechBubble(),
                      ),
                      // Chess board
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxHeight - 32,
                          maxHeight: constraints.maxHeight - 100,
                        ),
                        child: const BoardWidget(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const ScorePanel(),
                ),
              ),
            ],
          );
        } else {
          // Portrait / narrow layout
          return SingleChildScrollView(
            child: Column(
              children: [
                // Speech bubble commentary above the board
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const CommentarySpeechBubble(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: const BoardWidget(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: const ScorePanel(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      },
    );
  }

  PopupMenuItem<AIDifficulty> _buildDifficultyItem(
    AIDifficulty value,
    String label,
    AIDifficulty current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (value == current)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context, variant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${variant.name} Rules'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(variant.rulesSummary),
              const SizedBox(height: 16),
              const Text(
                'Piece Guide:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...variant.pieceInfo.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            e.value.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.value.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                e.value.movementDescription,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
