import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/ai_opponent.dart';
import '../../services/game_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_panel.dart';
import '../widgets/piece_info_panel.dart';
import '../widgets/commentary_widget.dart';

/// Main game screen
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(selectedVariantProvider);
    final difficulty = ref.watch(aiDifficultyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(variant.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
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
            // Piece info panel - positioned bottom right
            // To relocate: change the Positioned parameters below
            const Positioned(
              right: 16,
              bottom: 16,
              child: PieceInfoPanel(),
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
                // Add space at bottom for piece info panel overlay
                const SizedBox(height: 120),
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
