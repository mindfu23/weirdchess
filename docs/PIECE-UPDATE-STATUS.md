# WeirdChess Piece Graphics Update — Status

Last updated: 2026-04-12

## Overview

Replacing the original circle+letter piece rendering with custom art generated
via Gastown multi-model pipeline (Gemini 2.5 Flash image generation + iterative
refinement).

## Current Status

### Standard Piece Set (black side) — In Progress

**Style direction established through 12 iterative takes:**
- Flat 2D vector silhouettes, solid black fill, no 3D
- Face/mask negative-space cutouts on King and Queen
- S-curve body with void hole for Bishop
- Spiky triangular mane for Knight
- Gourd/bottle shape for Pawn
- Trapezoidal Rook with smooth silhouette
- Pedestal base style shared across all pieces

**Current best takes per piece:**

| Piece  | Best Take | Key Features | Status |
|--------|-----------|-------------|--------|
| King   | take12    | Crown+cross, face cutouts, skull-like | Needs refinement — still has shaft, want crown-only |
| Queen  | take12    | Multi-pointed coronet, face cutouts | Needs refinement — same shaft issue |
| Rook   | take11    | Crenellations, smooth body, pedestal base | Good |
| Bishop | take11    | S-curve with void, pointed mitre | Good |
| Knight | take11    | Spiky triangular mane, expressive eye | Good |
| Pawn   | take11    | Gourd shape, spherical top | Good |

### White Piece Variants — Not Started

Currently using CBurnett SVGs as placeholder for white pieces.

### Compound/Fairy Pieces (7 types) — Not Started

Amazon, Cardinal, Marshal, Champion, Wizard, Falcon, Hunter. 
These still render as circle+letter. Need original designs.

### Jetan/Barsoomian Pieces (8 types) — Not Started

Chief, Princess, Flier, Dwar, Padwar, Warrior, Thoat, Panthan.
Need sci-fi/alien aesthetic. Still circle+letter.

### Per-Variant Board Sets — Not Started

12 board variants each planned to have unique piece set flavor.
See `piece-design-brief.md` for per-variant style direction.

## Code Changes Made

### PieceWidget (`lib/ui/widgets/piece_widget.dart`)
- Now supports SVG and PNG assets with automatic format detection
- Falls back to circle+letter for pieces without asset files
- Accepts `pieceSet` parameter to load from different asset directories
- Uses `rootBundle.load()` with caching to resolve SVG vs PNG

### Variant Base (`lib/variants/variant_base.dart`)
- Added `pieceSet` getter (defaults to `'standard'`)
- Each variant can override to specify its own piece art directory

### Board Widget (`lib/ui/widgets/board_widget.dart`)
- Passes `variant.pieceSet` through to `PieceWidget` and `MoveAnimationOverlay`

### Move Animation Overlay (`lib/ui/widgets/move_animation_overlay.dart`)
- Added `pieceSet` parameter, forwarded to `PieceWidget` during animations

### Standard Chess Variant (`lib/variants/standard_chess.dart`)
- **TEMPORARY**: `pieceSet` overridden to `'weird'` for testing
- TODO: Revert to `'standard'` or make user-selectable

### pubspec.yaml
- Added `assets/pieces/standard/` and `assets/pieces/weird/` directories

## Asset Directories

```
assets/pieces/
├── standard/          # CBurnett SVGs (GPLv2+) — 12 files (wK.svg, bK.svg, etc.)
│   └── LICENSE        # GPLv2+ attribution
├── weird/             # Custom generated pieces — in progress
│   ├── bK.png         # Black King (take12)
│   ├── bQ.png         # Black Queen (take12)
│   ├── bR.png         # Black Rook (take11)
│   ├── bB.png         # Black Bishop (take11)
│   ├── bN.png         # Black Knight (take11)
│   ├── bP.png         # Black Pawn (take11)
│   └── w*.svg         # White pieces (CBurnett placeholders)
└── compound/          # Empty — for future compound piece assets
```

## Reference Documents

- `docs/piece-design-brief.md` — Full design constraints, app palette, board colors, size requirements
- `docs/piece-generation-specs.md` — Per-piece generation specs, prompt templates, review criteria

## Generation Pipeline

All piece generation runs through the Gastown Mission District fork:
- Pipeline project: `gastown-mission-district/agents/lib/imagen-projects/weirdchess.sh`
- Seed images: `gastown-mission-district/weirdchess-pieces/seed_images/`
- All takes: `gastown-mission-district/weirdchess-pieces/sample/test_styles/`
- Each take has `.png` + `.prompt.txt` files preserved for reproducibility

## Next Steps

1. Resolve king/queen "crown only" design (try programmatic cropping or Staunton reference)
2. Generate white color variants
3. Test on board at mobile game size
4. Generate compound pieces (7 types)
5. Generate Jetan pieces (8 types)
6. Create per-variant themed sets
7. Convert final PNGs → SVG for production
8. Make piece set user-selectable in settings
