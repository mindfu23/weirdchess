import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/piece.dart';

/// Maps single-letter piece symbols to CBurnett SVG filenames.
/// Compound and Jetan pieces (multi-letter symbols) fall back to circle+letter.
const _svgPieceFiles = {
  'K': 'king',
  'Q': 'queen',
  'R': 'rook',
  'B': 'bishop',
  'N': 'knight',
  'P': 'pawn',
};

/// Returns the asset path for a piece's SVG, or null if no SVG exists.
String? _svgAssetPath(Piece piece, {String set = 'standard'}) {
  final pieceName = _svgPieceFiles[piece.symbol];
  if (pieceName == null) return null;
  final colorPrefix = piece.color == PieceColor.white ? 'w' : 'b';
  return 'assets/pieces/$set/$colorPrefix${piece.symbol}.svg';
}

/// Widget that displays a chess piece — SVG when available, circle+letter fallback.
class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final String pieceSet;

  const PieceWidget({
    super.key,
    required this.piece,
    this.size = 40,
    this.pieceSet = 'standard',
  });

  @override
  Widget build(BuildContext context) {
    final svgPath = _svgAssetPath(piece, set: pieceSet);

    if (svgPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          svgPath,
          width: size,
          height: size,
        ),
      );
    }

    // Fallback: circle + letter for pieces without SVGs
    return _CircleLetterPiece(piece: piece, size: size);
  }
}

/// Original circle+letter rendering, used as fallback for compound/Jetan pieces.
class _CircleLetterPiece extends StatelessWidget {
  final Piece piece;
  final double size;

  const _CircleLetterPiece({required this.piece, required this.size});

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
