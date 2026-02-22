# WeirdChess

A Flutter chess app with 12 playable variants — 7 on a standard 8×8 board and 5 on an expanded 10×10 board — plus AI opposition, LLM-powered commentary, and variant-specific visual effects.

**Live:** [weirdchess.netlify.app](https://weirdchess.netlify.app)

---

## Variants

### 8×8

| Variant | Description |
|---------|-------------|
| **Standard Chess** | Classic rules with optional random pigeon attack chaos mode |
| **Atomic Chess** | Captures trigger explosions that destroy all adjacent non-pawn pieces |
| **Chess 960** | Fischer Random — back rank pieces shuffled, 960 possible starting positions |
| **Three-Check** | Win by putting the opponent in check 3 times |
| **King of the Hill** | Win by moving your king to one of the 4 central squares |
| **Horde Chess** | 36 white pawns vs a standard black army — asymmetric battle |
| **Fog of War** | Each player can only see squares visible to their own pieces |

### 10×10

| Variant | Description |
|---------|-------------|
| **Grand Chess** | Adds Marshal (Rook + Knight) and Cardinal (Bishop + Knight) pieces |
| **Omega Chess** | Adds Champion (1–2 orthogonal or 2-square diagonal leap) and Wizard (diagonal or camel leap) |
| **Decimal Chess** | Adds Falcon (diagonal forward, orthogonal back/side) and Hunter (orthogonal forward, diagonal back) |
| **Hyderabad Chess** | Adds Zurafa (Queen + Knight), Wazir (Bishop + Knight), and Dabbaba (Rook + Knight) |
| **Jetan** | Edgar Rice Burroughs' Martian chess — 8 unique piece types with Barsoomian names |

---

## Features

### Gameplay
- **AI opponent** with four difficulty levels (Beginner, Easy, Medium, Hard)
- **Undo move** — steps back two half-moves (human + AI) at once
- **New Game** button — starts a fresh game in the current variant
- **Rules dialog** — per-variant rules summary and piece guide accessible from the AppBar

### Variant-specific effects
- **King of the Hill** — central 4 squares highlighted with a golden border during play
- **Atomic Chess** — 3-phase mushroom-cloud explosion animation (expanding blast, white flash, grey ash) on every capture; persistent scorch-mark craters accumulate on affected squares for the rest of the game and clear on New Game
- **Three-Check** — live pip counter in the score panel showing checks delivered per player (○○○ → ●●●)
- **Horde Chess** — side-selection dialog on game start: play as the White Horde (36 pawns) or the Black standard Army; board flips when playing Black; AI moves first when human plays Black

### Pigeon Chaos Mode (Standard Chess only)
- Toggled on/off from the AppBar
- Every 5 human moves, a pigeon randomly teleports a non-king piece to an empty square
- Animated pigeon emoji sweeps left-to-right across the screen with a bobbing arc
- LLM commentary reacts with exasperation appropriate to a classical chess commentator
- Isolated to Standard Chess — switching variants clears any pending pigeon event

### 10×10 Piece Guide
- When playing a 10×10 variant, the score panel shows a scrollable guide listing each non-standard piece's name and movement description

### LLM Commentary
- AI moves trigger a 1–2 sentence speech bubble comment from a variant-specific personality (Grand Master, Omega Observer, Court Chronicler, Barsoomian Warrior, etc.)
- Supports Anthropic (Claude), OpenAI, and Google Gemini APIs
- Configurable via Settings — API key, provider, model, and enable/disable toggle
- Default model: `claude-3-haiku-20240307` (~$0.006 per 40-move game at standard pricing)

### Navigation
- Home screen with separate **8×8 Variants** and **10×10 Variants** tabs
- Back button from the game screen returns to the correct tab (8×8 or 10×10) based on the active variant

### App icon & branding
- Custom face-and-crown mascot icon across web favicon, Android launcher, and iOS App Store icons
- Righteous typeface throughout; dark palette (charcoal `#1A1A1A`, slate `#2D3542`, salmon accent `#FF9B8A`)

---

## Tech stack

- **Flutter** (Dart) — cross-platform UI, targeting web/iOS/Android
- **Riverpod 3.x** — state management (`NotifierProvider` throughout)
- **go_router** — declarative routing with query-param tab state
- **flutter_svg** — SVG mascot rendering
- **shared_preferences** — persists selected variant across sessions
- **http** — LLM API calls (direct-to-provider or via Netlify function)
- **Netlify** — static hosting from `build/web/`

---

## Project structure

```
lib/
  core/           Board, piece, move, and game-state primitives
  engine/         Alpha-beta AI opponent
  pieces/         Piece movement implementations (standard + variant-specific)
  variants/       One file per variant (variant_base.dart defines the interface)
  services/       game_service.dart (Riverpod providers), llm_service.dart, auth_service.dart
  ui/
    screens/      home_screen.dart, game_screen.dart, settings_screen.dart
    widgets/      board_widget.dart, score_panel.dart, piece_widget.dart,
                  atomic_explosion_overlay.dart, pigeon_flash_overlay.dart, …
assets/
  images/         mascot.svg, icon_1024.png
  fonts/          Righteous-Regular.ttf
  config.json     API endpoint configuration
```

---

## Building & deploying

```bash
# Web (Netlify)
flutter build web --release
# Commit build/web/ and push — Netlify serves it directly (no build command configured)

# Regenerate launcher icons after changing assets/images/icon_1024.png
dart run flutter_launcher_icons
```
