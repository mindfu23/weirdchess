# WeirdChess Piece Design Brief

Reference document for generating chess piece graphics. Any agent, model, or human
working on piece art should use this as the style constraint.

---

## App Visual Identity

WeirdChess is a dark-mode-only Flutter app (Material Design 3) with a warm,
playful-but-not-cartoonish personality.

### Brand Palette

| Role            | Color     | Name          |
|-----------------|-----------|---------------|
| Primary accent  | `#FF9B8A` | Warm coral    |
| Background      | `#1A1A1A` | Charcoal      |
| Surface/cards   | `#2D3542` | Blue-gray     |
| Primary text    | `#F5E6D3` | Warm cream    |
| Muted text      | `#9B8E85` | Gray-brown    |
| Success         | `#4CAF82` | Green         |
| Error/loss      | `#FF6B6B` | Red           |
| Highlight       | `#FFD700` | Gold          |

### Typography

- Display font: **Righteous** (rounded, bold, slightly retro)
- Body: System default (Material)

### UI Style

- Flat/modern with minimal shadows
- Rounded corners (14px cards, 8px buttons, 20px speech bubbles)
- No skeuomorphism or heavy textures
- Subtle drop shadows only where needed for depth

---

## Board Environments

Pieces must work across 12 variant-specific board palettes. These range widely,
so pieces cannot depend on a single background color for contrast.

| Variant           | Light Square | Dark Square  | Character          |
|-------------------|--------------|--------------|--------------------|
| Standard          | `#F0D9B5`   | `#B58863`    | Classic wood       |
| Atomic            | `#F5DEB3`   | `#CD853F`    | Warm earth         |
| Chess960          | `#F0E68C`   | `#556B2F`    | Yellow-green       |
| Three-Check       | `#E8D5B7`   | `#9B7355`    | Muted tan          |
| King of the Hill  | `#DEB887`   | `#8B4513`    | Rich wood          |
| Horde             | `#F5F5DC`   | `#8B6914`    | Beige-olive        |
| Fog of War        | `#B8D4E3`   | `#2C3E50`    | Cool blue          |
| Grand Chess       | `#F0D9B5`   | `#B58863`    | Classic wood       |
| Omega Chess       | `#E8E8E8`   | `#4A4A4A`    | Gray monochrome    |
| Decimal Chess     | `#FFF8DC`   | `#2F4F4F`    | High contrast      |
| Hyderabad Chess   | `#F5DEB3`   | `#8B4513`    | Earth tones        |
| Jetan             | `#FF8C00`   | `#1A1A1A`    | Orange-black       |

### Key implication

White pieces appear on light AND dark squares. Black pieces appear on light AND
dark squares. Both colors of piece must be readable on every board palette above.

---

## Piece Rendering Constraints

### Size and readability

- Pieces render at approximately **40-60px** on mobile, up to ~80px on desktop
- Pieces occupy **80% of the square** they sit on
- At 40px, only silhouette and major shape features are visible
- **Silhouette must be the primary identifier** — if you squint, you should still
  know which piece it is

### Current rendering (to be replaced)

- White pieces: white circle, `#424242` border (2px), dark text
- Black pieces: `#424242` circle, white border (2px), white text
- Drop shadow: black at 30% opacity, 4px blur, offset (2, 2)

### New pieces should have

- **Defined edges**: A visible border, outline, or contrast edge so pieces pop off
  any board color. ~2px stroke or equivalent visual weight.
- **Subtle shadow**: Consistent with the current drop shadow style (soft, not harsh)
- **Clear white/black distinction**: The two color variants of each piece must be
  immediately distinguishable. Use fill color as the primary differentiator, not
  detail changes.

### Color guidance for pieces

- **White pieces**: Cream/off-white fill (`#F5E6D3` to `#FFFFFF` range), with a
  darker outline (`#424242` to `#2D3542`)
- **Black pieces**: Dark fill (`#1A1A1A` to `#2D3542` range), with a lighter
  outline (`#F5E6D3` to `#FFFFFF`)
- Avoid pure white (`#FFFFFF`) fill — use a warm tint to match the app's cream palette
- Accent color (`#FF9B8A` coral) may be used sparingly for special pieces (kings, queens)
  but should not dominate

---

## Style Direction

### Do

- Flat or semi-flat illustration style (consistent with Material 3 aesthetic)
- Slight warmth — the app uses warm corals and creams, not cold blues/grays
- Playful personality appropriate for "Weird Chess" branding
- Consistent line weight and level of detail across all pieces in a set
- Geometric simplification where it aids readability at small sizes

### Don't

- Photorealistic or heavily rendered 3D
- Overly detailed — fine detail disappears at 40px
- Cold/clinical/corporate
- Inconsistent styles within a set (e.g., some pieces detailed, others minimal)
- Heavy textures or gradients that muddy at small sizes

### Silhouette test

Every piece must pass: "Rendered as a solid black shape at 40px, can a chess
player identify it?" Standard pieces should be instantly recognizable. Compound
and Jetan pieces have more freedom but must still be distinct from each other
and from standard pieces.

---

## Piece Inventory

### Standard (6 types)

| Piece  | Symbol | Key silhouette features                    |
|--------|--------|--------------------------------------------|
| King   | K      | Cross on top, tallest piece                |
| Queen  | Q      | Crown/coronet, second tallest              |
| Rook   | R      | Crenellated top (castle battlements)       |
| Bishop | B      | Pointed mitre with slit                    |
| Knight | N      | Horse head profile                         |
| Pawn   | P      | Simple rounded top, smallest piece         |

### Compound / Fairy (7 types)

These need original designs. Each combines move sets of standard pieces,
so the silhouette can hint at the combination.

| Piece    | Symbol | Combines          | Design hint                          |
|----------|--------|-------------------|--------------------------------------|
| Amazon   | A      | Queen + Knight    | Crown + horse element                |
| Cardinal | C      | Bishop + Knight   | Mitre + horse element                |
| Marshal  | M      | Rook + Knight     | Battlement + horse element           |
| Champion | Ch     | King-move + 2-leap| Shield or medallion shape            |
| Wizard   | W      | Diagonal 1 + 3-leap | Pointed hat or star                |
| Falcon   | Fa     | Forward diagonal slider | Wing/bird silhouette            |
| Hunter   | Hu     | Forward rook + backward bishop | Arrow or directional shape  |

### Jetan / Barsoomian (8 types)

Martian chess from Edgar Rice Burroughs. These should feel cohesive as their own
set while still fitting the app's overall style. Can lean into sci-fi/alien aesthetic.

| Piece    | Symbol | Role equivalent    | Design hint                         |
|----------|--------|--------------------|-------------------------------------|
| Chief    | Cf     | King               | Helmet or command insignia          |
| Princess | Pr     | Queen              | Tiara or Barsoomian ornament        |
| Flier    | Fl     | Bishop-like        | Airship or wing                     |
| Dwar     | Dw     | Rook-like          | Warrior with weapon                 |
| Padwar   | Pd     | Knight-like        | Officer rank insignia               |
| Warrior  | Wa     | Minor piece        | Sword or spear silhouette           |
| Thoat    | Th     | Cavalry            | Alien mount (8-legged beast)        |
| Panthan  | Pa     | Pawn               | Simple foot soldier                 |

---

## Board-Specific Piece Sets

Each of the 12 board variants may have its own piece set with a distinct flavor,
while maintaining the constraints above. All sets share the same silhouette
language so a King is always recognizable as a King, but surface treatment
(fill patterns, accent colors, decorative details) can vary per board.

### Recommended per-board flavor

| Variant           | Piece set flavor                                        |
|-------------------|---------------------------------------------------------|
| Standard          | Clean, classic — the "default" set                      |
| Atomic            | Slightly rougher edges, hazard/radiation motif           |
| Chess960          | Randomized feel — asymmetric details                    |
| Three-Check       | Aggressive/sharp angles                                 |
| King of the Hill  | Royal/golden accents                                    |
| Horde             | Horde side: simplified/uniform; defender side: standard  |
| Fog of War        | Muted/ghostly, works against blue palette               |
| Grand Chess       | Ornate — more detail since 10x10 means larger squares   |
| Omega Chess       | Modernist/geometric — matches gray monochrome board     |
| Decimal Chess     | High contrast, bold outlines                            |
| Hyderabad Chess   | South Asian decorative motifs                           |
| Jetan             | Barsoomian/alien sci-fi — uses Jetan piece set          |

---

## File Format and Technical Requirements

### Target format: SVG

- Clean, optimized SVG paths
- ViewBox: `0 0 100 100` (square, scalable)
- No embedded raster images
- No external dependencies (fonts, links)
- Minimal path complexity (keep file size under 5KB per piece)

### File naming convention

```
assets/pieces/{set-name}/{color}_{piece}.svg

Examples:
assets/pieces/standard/white_king.svg
assets/pieces/standard/black_queen.svg
assets/pieces/atomic/white_pawn.svg
assets/pieces/jetan/white_chief.svg
```

### Fallback

If SVG generation quality is insufficient for any piece, high-resolution
transparent PNG (512x512) is acceptable as an intermediate format that can
be manually traced to SVG later.

---

## Generation Workflow

### Phase 1: Style exploration (per board variant)

1. Provide seed images and/or text description of desired style
2. Generate **4 variant takes**, each showing 3 representative pieces:
   **Pawn, Queen, Knight** (covers simple, ornate, and distinctive silhouettes)
3. Review and select preferred take, or request another round of 4
4. On selection, generate remaining pieces in that style

### Phase 2: Board integration review

1. Composite generated pieces onto a screenshot of the actual game board
2. Review for: contrast, readability at target size, style cohesion
3. Iterate on any pieces that don't pass

### Phase 3: Final production

1. Generate final SVG files
2. Archive all generation inputs (seed images, prompts, selected variants)
   in `docs/piece-generation-archive/{set-name}/` for future reference
3. Integrate into Flutter app

---

## Reference Screenshot

For board integration review, use a screenshot of the actual game showing:
- A mid-game position (not starting position — pieces should be scattered)
- The specific variant's board colors
- Both white and black pieces visible
- At representative screen size (mobile and desktop)

Screenshots should be saved to `docs/piece-generation-archive/board-screenshots/`
for agent reference during review.
