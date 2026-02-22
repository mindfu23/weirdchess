import 'package:flutter/material.dart';
import '../../core/piece.dart';
import '../../services/game_service.dart';

/// Full-board overlay that flashes when a pigeon disrupts the chessboard.
///
/// The overlay fades in quickly, holds briefly to display the message,
/// then fades out. The [PigeonEventNotifier] controls when this fires.
///
/// TODO: Pigeon animation — replace the static emoji with a sprite or
/// Lottie animation of a pigeon flying across the board from a random
/// edge. Suggested approach:
///   1. Add a `lottie` package dependency to pubspec.yaml.
///   2. Place a pigeon Lottie JSON in assets/animations/pigeon.json.
///   3. Swap the Text('🕊️') below for a Lottie.asset() widget with a
///      translate animation that moves from off-screen left to right.
class PigeonFlashOverlay extends StatefulWidget {
  final PigeonEvent event;

  const PigeonFlashOverlay({super.key, required this.event});

  @override
  State<PigeonFlashOverlay> createState() => _PigeonFlashOverlayState();
}

class _PigeonFlashOverlayState extends State<PigeonFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Flash in fast, hold at peak, then fade out slowly.
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
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorName =
        widget.event.pieceColor == PieceColor.white ? 'White' : 'Black';

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        if (_opacity.value == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: _opacity.value,
          child: Container(
            color: Colors.amber.shade100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TODO: Replace with animated pigeon (see class doc above).
                  const Text('🕊️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
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
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
