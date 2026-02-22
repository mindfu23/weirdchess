import 'package:flutter/material.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

/// Full-board overlay that flashes when a pigeon disrupts the chessboard.
///
/// The overlay fades in quickly, holds briefly to display the message,
/// then fades out. The pigeon emoji sweeps across the screen from left to
/// right with a gentle bobbing arc to simulate flight.
class PigeonFlashOverlay extends StatefulWidget {
  final PigeonEvent event;

  const PigeonFlashOverlay({super.key, required this.event});

  @override
  State<PigeonFlashOverlay> createState() => _PigeonFlashOverlayState();
}

class _PigeonFlashOverlayState extends State<PigeonFlashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _flyController;
  late final Animation<double> _opacity;
  late final Animation<double> _flyX;
  late final Animation<double> _flyY;

  @override
  void initState() {
    super.initState();

    // Overall fade: in fast, hold, then fade out.
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.88),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 32,
      ),
    ]).animate(_fadeController);

    // Pigeon flies left-to-right across the overlay in 1400ms (starts after
    // a brief delay so it's visible once the background fades in).
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Horizontal: -0.15 (just off-screen left) → 1.15 (just off-screen right),
    // as a fraction of the total overlay width.
    _flyX = Tween<double>(begin: -0.15, end: 1.15)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_flyController);

    // Vertical: oscillates to simulate wing-beat arc. Values are fractions of
    // overlay height — negative = upward.
    _flyY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -0.06)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: -0.06, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -0.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: -0.05, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_flyController);

    _fadeController.forward();
    // Small delay before pigeon flies so the amber background is visible first.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _flyController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorName =
        widget.event.pieceColor == PieceColor.white ? 'White' : 'Black';

    return AnimatedBuilder(
      animation: Listenable.merge([_opacity, _flyX, _flyY]),
      builder: (context, _) {
        if (_opacity.value == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: _opacity.value,
          child: Container(
            color: Colors.amber.shade100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                // Pigeon sits at ~35% from the top, bobbing up from there.
                final baseY = h * 0.35;
                final pigeonX = _flyX.value * w;
                final pigeonY = baseY + _flyY.value * h;

                return Stack(
                  children: [
                    // Flying pigeon
                    Positioned(
                      left: pigeonX,
                      top: pigeonY,
                      child: const Text(
                        '🕊️',
                        style: TextStyle(fontSize: 72),
                      ),
                    ),

                    // Message — centered in lower half
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0, 0.4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'A pigeon hit the chessboard.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "$colorName's ${widget.event.pieceName} was knocked\n"
                              'from ${widget.event.fromSquare} to ${widget.event.toSquare}!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
