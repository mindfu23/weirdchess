# WeirdChess Piece Generation Specs

Target: A piece set that is uniquely weird but immediately recognizable to any
chess player. Merge the organic/quirky silhouette energy of the Midjourney
reference (black silhouettes on orange) with standard chess recognition cues.

See `piece-design-brief.md` for color palette, size constraints, and technical
requirements.

---

## Design Principles

1. **Every piece must pass the "squint test"** — at 40px, rendered as a solid
   silhouette, a chess player should identify it within 1 second.
2. **Recognition cues are sacred** — each piece has 1-2 features that trigger
   instant identification. These cannot be removed or obscured.
3. **Everything else is fair game** — body proportions, curves, textures,
   asymmetry, personality. This is where "weird" lives.
4. **Relative height hierarchy matters** — King > Queen > Bishop ~ Rook > Knight > Pawn.
   Players use relative size as a secondary identification cue.
5. **Consistent design language** — all 6 pieces should look like they belong to
   the same set. If the knight is organic/curvy, the rook shouldn't be rigid/geometric.

---

## Piece-by-Piece Specifications

### King

**Sacred cue:** Cross on top (the single most important identifier in chess).

**Weird direction:** Take the Image 3 cross-topped orb shape (mid-left in reference).
Keep the cross but make it slightly asymmetric or organic — like it grew rather
than was manufactured. Body can be bulbous, tapered, or have unusual proportions.
The cross should be clearly visible even at small sizes.

**Avoid:** Making the cross too small, too ornate, or hidden among other details.

**Reference merge:** Image 3 mid-left silhouette (cross-topped) is the closest
starting point. Enlarge the cross, simplify the body.

---

### Queen

**Sacred cue:** Crown with multiple pointed tips (coronet). Must read differently
from the king's single cross.

**Weird direction:** The Image 3 raised-arms figure (top-2nd) has great energy
and personality. Merge that expressive attitude with a clear multi-pointed crown.
The "arms" could become stylized extensions of the crown's points. Give her
presence — she's the most powerful piece.

**Avoid:** Making her look like a person/figure rather than a chess piece. The
crown must dominate the silhouette, not the body gesture.

**Reference merge:** Top-2nd silhouette's energy, but replace the human-figure
read with a crowned chess piece read.

---

### Rook

**Sacred cue:** Flat crenellated top (castle battlements — the rectangular
teeth pattern). Stocky, solid proportions.

**Weird direction:** The body below the battlements is where weirdness lives.
Can be tapered, curved, have unusual base proportions. Could incorporate organic
curves that contrast with the geometric top. The Image 3 stacked-triangles
shape (mid-4th) has interesting geometry but needs the flat crenellated top
added to be recognizable.

**Avoid:** Pointed tops, round tops, or anything that obscures the characteristic
flat battlement profile.

**Reference merge:** Use Image 3's geometric stacking for the body, but crown it
with clear crenellations.

---

### Bishop

**Sacred cue:** Pointed top (mitre shape), often with a diagonal slit or notch.
Taller and thinner than the rook.

**Weird direction:** The Image 3 bell/bulb shape (top-3rd) has an interesting
organic quality. Give it a clearly pointed top with a visible slit or notch.
The body can lean, curve, or have asymmetric proportions — bishops move
diagonally, so a slight lean actually reinforces the piece's identity.

**Avoid:** Round tops (reads as pawn), flat tops (reads as rook), or multi-pointed
tops (reads as queen).

**Reference merge:** Top-3rd silhouette's bulbous body with a sharpened, pointed
top and added slit.

---

### Knight

**Sacred cue:** Horse head in profile. This is the most distinctive piece in chess
— no other piece looks anything like it.

**Weird direction:** Image 3's horse head (top-left) is already excellent — organic,
characterful, and instantly recognizable. This is the piece that needs the least
change. Push the weirdness into the horse's expression, mane style, or neck
proportions. Can be more serpentine, more angular, more stylized — as long as
it reads "horse head."

**Avoid:** Abstract shapes that lose the horse read. Front-facing horse (must be
profile). Making it look like a seahorse or dragon (too far from chess).

**Reference merge:** Top-left silhouette is nearly ready to use. Minor cleanup
for consistent style with the rest of the set.

---

### Pawn

**Sacred cue:** Simplest piece, smallest, rounded top. Players identify pawns
partly by what they're NOT — not a crown, not a cross, not battlements, not a
horse, not a point.

**Weird direction:** The pawn's weirdness should be subtle — an unusual curve, an
organic base, a slightly off-center top. It's the "foot soldier" and should feel
humble compared to the other pieces. The stippled texture from Image 3 would
work well here as a simple surface treatment.

**Avoid:** Adding distinctive top features (crown, cross, point) that make it
look like a more valuable piece. Making it as tall as other pieces.

**Reference merge:** Create fresh, informed by Image 3's organic style language
but keeping maximum simplicity.

---

## Generation Prompt Template

For use with Gastown imagen agent or Midjourney:

```
Chess piece silhouette: {piece_name}. Flat black silhouette on white background.
Quirky, organic, slightly asymmetric design language — like hand-carved wood
with personality. {piece_specific_direction}. Must be immediately recognizable
as a chess {piece_name} to any chess player. Single piece, centered, no
background elements. Square frame, piece fills ~80% of height.
```

### Piece-specific prompt additions:

- **King**: "Clear cross on top, visible even at small sizes. Bulbous or organic body shape. Tallest piece in the set."
- **Queen**: "Multi-pointed crown/coronet clearly visible at top. Commanding presence. Second tallest piece."
- **Rook**: "Flat top with clear rectangular crenellations (castle battlements). Stocky, solid proportions. Interesting body curves below the battlements."
- **Bishop**: "Pointed mitre top with diagonal slit or notch. Slight lean suggesting diagonal movement. Taller and thinner than the rook."
- **Knight**: "Horse head in profile facing left. Expressive, characterful. Visible mane and eye. Organic neck curves."
- **Pawn**: "Simple rounded top, smallest piece. Humble, minimal detail. Organic base shape."

---

## Review Criteria

After generation, evaluate each piece against:

1. **Identification** (pass/fail): Can you name the piece within 1 second at 40px?
2. **Set cohesion** (1-5): Does it look like it belongs with the other 5 pieces?
3. **Weirdness** (1-5): Does it have personality beyond generic Staunton?
4. **Silhouette clarity** (1-5): Is the outline clean and unambiguous?
5. **Size hierarchy** (pass/fail): Does relative height match expected rank?

All pieces must score: Identification=pass, Set cohesion>=3, Weirdness>=3,
Silhouette clarity>=4, Size hierarchy=pass.

---

## 3-Piece Sample Set

For initial style exploration, generate these 3 pieces first:
- **Pawn** (simplest — tests minimalism)
- **Queen** (most ornate — tests detail handling)
- **Knight** (most distinctive — tests character)

If these 3 work together and pass review criteria, generate the remaining 3.
