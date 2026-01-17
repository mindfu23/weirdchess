import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/llm_service.dart';
import '../../services/auth_service.dart';

/// Speech bubble widget that displays AI commentary on moves.
/// Positioned above the chess board with a tail pointing downward.
class CommentarySpeechBubble extends ConsumerWidget {
  const CommentarySpeechBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentary = ref.watch(commentaryProvider);
    final auth = ref.watch(authProvider);
    final llmConfig = ref.watch(llmConfigProvider);

    // Show commentary if:
    // - We have a client-side API key (isAuthenticated), OR
    // - We're in Netlify mode (directMode: false) where server has the API key
    final canShowCommentary = auth.isAuthenticated || !llmConfig.directMode;

    if (!canShowCommentary) {
      return const SizedBox.shrink();
    }

    // Don't show if no commentary
    if (commentary.text.isEmpty && !commentary.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: commentary.isLoading
            ? _buildLoadingBubble(context)
            : _buildCommentaryBubble(context, commentary),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return _SpeechBubble(
      key: const ValueKey('loading'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryBubble(BuildContext context, CommentaryState commentary) {
    final isError = commentary.isError;
    final backgroundColor = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer;

    return _SpeechBubble(
      key: ValueKey(commentary.text),
      backgroundColor: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.format_quote,
            size: 20,
            color: isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              commentary.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom speech bubble container with rounded corners and a tail.
class _SpeechBubble extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const _SpeechBubble({
    super.key,
    required this.child,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
        // Speech bubble tail pointing down
        CustomPaint(
          size: const Size(20, 10),
          painter: _BubbleTailPainter(color: backgroundColor),
        ),
      ],
    );
  }
}

/// Paints the triangular tail of the speech bubble.
class _BubbleTailPainter extends CustomPainter {
  final Color color;

  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Legacy widget kept for backwards compatibility
class CommentaryWidget extends CommentarySpeechBubble {
  const CommentaryWidget({super.key});
}

/// Compact version for inline display.
class CommentaryBanner extends ConsumerWidget {
  const CommentaryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentary = ref.watch(commentaryProvider);
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated ||
        (commentary.text.isEmpty && !commentary.isLoading)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: commentary.isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
      child: Row(
        children: [
          if (commentary.isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            Icon(
              commentary.isError ? Icons.error_outline : Icons.format_quote,
              size: 16,
              color: commentary.isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              commentary.isLoading ? 'Thinking...' : commentary.text,
              style: TextStyle(
                fontSize: 13,
                fontStyle: commentary.isLoading ? FontStyle.italic : FontStyle.normal,
                color: commentary.isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
