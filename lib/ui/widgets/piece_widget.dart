import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/piece.dart';

/// Standard piece symbols that have dedicated asset files.
const _standardSymbols = {'K', 'Q', 'R', 'B', 'N', 'P'};

/// Jetan pieces that map to standard equivalents for display.
/// Custom Jetan/compound art saved in assets/pieces/jetan/ and compound/ for future use.
const _jetanToStandard = {
  'Cf': 'K',  // Chief → King (leader, capture = loss)
  'Pr': 'Q',  // Princess → Queen (royal)
  'Fl': 'B',  // Flier → Bishop (diagonal)
  'Dw': 'R',  // Dwar → Rook (orthogonal)
  'Th': 'N',  // Thoat → Knight (has knight leap)
  'Pa': 'P',  // Panthan → Pawn (foot soldier)
};

/// Jetan pieces with custom art in assets/pieces/jetan/.
const _jetanCustomSymbols = {'Wa', 'Pd'};

/// Compound pieces with custom art in assets/pieces/compound/.
const _compoundCustomSymbols = {'Ch', 'W'};

/// Returns the asset path for a piece, trying SVG first then PNG.
/// Maps Jetan pieces to standard equivalents, or custom jetan/ art.
String? _pieceAssetPath(Piece piece, {String set = 'standard'}) {
  final colorPrefix = piece.color == PieceColor.white ? 'w' : 'b';
  final sym = piece.symbol;

  // Custom Jetan art (Warrior, Padwar)
  if (_jetanCustomSymbols.contains(sym)) {
    return 'assets/pieces/jetan/$colorPrefix$sym';
  }

  // Custom compound art (Champion)
  if (_compoundCustomSymbols.contains(sym)) {
    return 'assets/pieces/compound/$colorPrefix$sym';
  }

  // Map other Jetan pieces to standard equivalents
  final mapped = _jetanToStandard[sym] ?? sym;
  if (!_standardSymbols.contains(mapped)) return null;
  final base = 'assets/pieces/$set/$colorPrefix$mapped';
  return base; // caller will try .svg then .png
}

/// Cache which asset paths exist and in which format.
final Map<String, String?> _assetFormatCache = {};

/// Check if an asset exists, with caching.
Future<String?> _resolveAssetFormat(String basePath) async {
  if (_assetFormatCache.containsKey(basePath)) {
    return _assetFormatCache[basePath];
  }
  // Try SVG first, then PNG
  for (final ext in ['.svg', '.png']) {
    try {
      await rootBundle.load('$basePath$ext');
      _assetFormatCache[basePath] = '$basePath$ext';
      return '$basePath$ext';
    } catch (_) {
      // Asset doesn't exist in this format
    }
  }
  _assetFormatCache[basePath] = null;
  return null;
}

/// Widget that displays a chess piece — SVG or PNG when available, circle+letter fallback.
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
    final basePath = _pieceAssetPath(piece, set: pieceSet);

    if (basePath == null) {
      return _CircleLetterPiece(piece: piece, size: size);
    }

    return FutureBuilder<String?>(
      future: _resolveAssetFormat(basePath),
      builder: (context, snapshot) {
        final resolvedPath = snapshot.data;

        if (resolvedPath == null) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _CircleLetterPiece(piece: piece, size: size);
          }
          // Still loading — show empty box to avoid flicker
          return SizedBox(width: size, height: size);
        }

        final Widget pieceImage;
        if (resolvedPath.endsWith('.svg')) {
          pieceImage = SvgPicture.asset(resolvedPath, width: size, height: size);
        } else {
          pieceImage = Image.asset(resolvedPath, width: size, height: size, fit: BoxFit.contain);
        }

        // Black pieces get a white outline that follows the piece silhouette
        if (piece.color == PieceColor.black) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // White blurred copies behind = silhouette outline
                // Stacked twice for a more solid edge
                for (final _ in [0, 1])
                  ImageFiltered(
                    imageFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcATop,
                    ),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                      child: pieceImage,
                    ),
                  ),
                // Original piece on top
                pieceImage,
              ],
            ),
          );
        }

        return SizedBox(width: size, height: size, child: pieceImage);
      },
    );
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
