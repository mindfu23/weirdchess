import 'package:flutter/material.dart';
import '../../core/piece.dart';

/// Widget that displays a chess piece as a simple circle with letter
class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;

  const PieceWidget({
    super.key,
    required this.piece,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isWhite ? Colors.white : Colors.grey[800],
        border: Border.all(
          color: isWhite ? Colors.grey[800]! : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          piece.symbol,
          style: TextStyle(
            color: isWhite ? Colors.grey[800] : Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Generate SVG string for a piece (for future use with flutter_svg)
String generatePieceSvg(Piece piece, {double size = 100}) {
  final isWhite = piece.color == PieceColor.white;
  final fillColor = isWhite ? 'white' : '#333333';
  final strokeColor = isWhite ? '#333333' : 'white';
  final textColor = isWhite ? '#333333' : 'white';

  return '''
<svg viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">
  <circle cx="${size / 2}" cy="${size / 2}" r="${size * 0.45}"
          fill="$fillColor" stroke="$strokeColor" stroke-width="2"/>
  <text x="${size / 2}" y="${size * 0.6}"
        text-anchor="middle" font-size="${size * 0.4}"
        fill="$textColor" font-weight="bold">${piece.symbol}</text>
</svg>
''';
}
