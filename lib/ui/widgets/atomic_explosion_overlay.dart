import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/game_service.dart';

/// Animated mushroom-cloud overlay rendered on top of the chess board.
///
/// Three phases:
///   a) Expanding orange/red circle — the blast cloud (400 ms)
///   b) White flash — the irradiation burst (150 ms overlap)
///   c) Grey ash/smoke settling (200 ms)
///
/// Positioned within the board using fractional coordinates derived from the
/// explosion's [AtomicExplosionEvent.center].
class AtomicExplosionBoardOverlay extends ConsumerStatefulWidget {
  final int boardSize;

  const AtomicExplosionBoardOverlay({
    required this.boardSize,
    super.key,
  });

  @override
  ConsumerState<AtomicExplosionBoardOverlay> createState() =>
      _AtomicExplosionBoardOverlayState();
}

class _AtomicExplosionBoardOverlayState
    extends ConsumerState<AtomicExplosionBoardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  AtomicExplosionEvent? _currentEvent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _currentEvent = null);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AtomicExplosionEvent?>(atomicExplosionEventProvider, (prev, next) {
      if (next != null && mounted && !_controller.isAnimating) {
        setState(() => _currentEvent = next);
        _controller.forward(from: 0);
      }
    });

    if (_currentEvent == null) return const SizedBox.shrink();

    final event = _currentEvent!;
    final bs = widget.boardSize;

    // Fractional position of explosion centre within board (0.0 → 1.0).
    final fx = (event.center.col + 0.5) / bs;
    final fy = (event.center.row + 0.5) / bs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final squareSize = w / bs;
        final cx = fx * w;
        final cy = fy * h;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;

            // Phase a: expanding cloud (t: 0.0 → 0.55)
            final cloudProgress = (t / 0.55).clamp(0.0, 1.0);
            final cloudOpacity = cloudProgress < 0.7
                ? cloudProgress / 0.7
                : (1.0 - (cloudProgress - 0.7) / 0.3);

            // Phase b: white flash (t: 0.30 → 0.55)
            final flashProgress = ((t - 0.30) / 0.25).clamp(0.0, 1.0);
            final flashOpacity = flashProgress < 0.4
                ? flashProgress / 0.4
                : (1.0 - (flashProgress - 0.4) / 0.6);

            // Phase c: ash/smoke (t: 0.55 → 1.0)
            final ashProgress = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
            final ashOpacity = ashProgress < 0.15
                ? ashProgress / 0.15
                : (1.0 - (ashProgress - 0.15) / 0.85);

            final maxRadius = squareSize * 2.2;
            final cloudRadius = cloudProgress * maxRadius;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Mushroom cloud — a glowing radial blast
                if (cloudRadius > 0)
                  Positioned(
                    left: cx - cloudRadius * 1.3,
                    top: cy - cloudRadius * 1.3,
                    child: Opacity(
                      opacity: cloudOpacity.clamp(0.0, 1.0),
                      child: CustomPaint(
                        size: Size(cloudRadius * 2.6, cloudRadius * 2.6),
                        painter: _CloudPainter(
                          progress: cloudProgress,
                          radius: cloudRadius,
                        ),
                      ),
                    ),
                  ),

                // White irradiation flash
                if (flashOpacity > 0.01)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (flashOpacity * 0.70).clamp(0.0, 1.0),
                      child: const ColoredBox(color: Color(0xFFFFFFFF)),
                    ),
                  ),

                // Grey ash residue
                if (ashOpacity > 0.01)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (ashOpacity * 0.40).clamp(0.0, 1.0),
                      child: const ColoredBox(color: Color(0xFF888888)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Paints a two-layer mushroom cloud: a fiery stem circle and a lighter cap.
class _CloudPainter extends CustomPainter {
  final double progress;
  final double radius;

  const _CloudPainter({required this.progress, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;

    final centre = Offset(size.width / 2, size.height / 2);

    // Stem — deep orange-red filled disc
    final stemPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF4500),
          const Color(0xFFFF8C00).withAlpha(180),
          const Color(0xFFFF4500).withAlpha(0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: centre, radius: radius));
    canvas.drawCircle(centre, radius, stemPaint);

    // Cap — gold/orange puff sitting above the stem
    final capRadius = radius * 0.85;
    final capCentre = Offset(centre.dx, centre.dy - radius * 0.5);
    final capPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF6B00).withAlpha(160),
          const Color(0xFFFF4500).withAlpha(0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: capCentre, radius: capRadius));
    canvas.drawCircle(capCentre, capRadius, capPaint);

    // Outer glow ring
    if (progress < 0.75) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12;
      canvas.drawCircle(centre, radius * 1.05, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) =>
      old.progress != progress || old.radius != radius;
}
