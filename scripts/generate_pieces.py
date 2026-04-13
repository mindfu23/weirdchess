#!/usr/bin/env python3
"""Generate chess piece PNGs using Gemini imagen API.

Generates compound pieces (for 10x10 variants) and Jetan pieces
in the classic CBurnett/Staunton style with transparent backgrounds.
"""

import base64
import json
import os
import ssl
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

try:
    import certifi
    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CTX = ssl.create_default_context()

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not set")
    sys.exit(1)

MODEL = "gemini-2.5-flash-image"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "pieces"

# Style preamble for all pieces
STYLE_PREFIX = (
    "A single chess piece in the classic Staunton/CBurnett style. "
    "Clean vector-like illustration with smooth outlines, on a plain white background. "
    "The piece should be centered, viewed from the front, with a standard chess piece base/pedestal. "
    "No shadows, no 3D lighting, no gradients — flat fill with clear black outlines. "
    "The piece should fill about 80% of the frame. Square aspect ratio. "
)

WHITE_STYLE = "The piece is WHITE (light colored) with a white/cream fill and black outlines. "
BLACK_STYLE = "The piece is BLACK (dark colored) with a solid black/dark gray fill and thin light gray outlines. "

# Piece definitions: symbol -> (name, description for prompt)
COMPOUND_PIECES = {
    "M": ("Marshal", "A chess piece called the Marshal that combines a Rook and Knight. The top has a rook-style crenellated castle tower, but with a small knight horse-head shape carved into the front of the tower between the battlements. Standard chess piece pedestal base."),
    "C": ("Cardinal", "A chess piece called the Cardinal that combines a Bishop and Knight. The top has a bishop's tall pointed mitre hat, but the mitre has a small horse-head profile carved into its left side. A slit runs down the mitre center. Standard chess piece pedestal base."),
    "A": ("Amazon", "A chess piece called the Amazon — the most powerful piece on the board. The top has an ornate crown with multiple points like a queen, with a tiny horse head rising from the center point. Taller and more elaborate than a queen. Standard chess piece pedestal base."),
    "Ch": ("Champion", "A chess piece called the Champion. The top is a broad flat disc or shield shape — like a round buckler viewed from the front — with a bold cross/plus emblem embossed on it. Wider and sturdier than other pieces. Standard chess piece pedestal base."),
    "W": ("Wizard", "A chess piece called the Wizard. The top is a tall pointed cone like a wizard's hat, with a small crescent moon cutout near the tip. The body tapers elegantly. Standard chess piece pedestal base."),
    "Fa": ("Falcon", "A chess piece called the Falcon. The top is a stylized bird head in profile — a curved beak pointing right, with a sleek swept-back crest. The silhouette clearly reads as a falcon/hawk. Standard chess piece pedestal base."),
    "Hu": ("Hunter", "A chess piece called the Hunter. The top is an upward-pointing arrowhead or spearpoint — a sharp triangular shape. The body has a slight hourglass taper. Standard chess piece pedestal base."),
}

JETAN_PIECES = {
    "Cf": ("Chief", "A chess piece for the Barsoomian Chief (warlord). It has a bold horned helmet or war crown with two curved horns rising from the sides, imposing and commanding, sitting on a standard chess piece base."),
    "Pr": ("Princess", "A chess piece for the Barsoomian Princess. It has an elegant tiara with a central gemstone shape, graceful curved lines suggesting royalty, sitting on a slender standard chess piece base."),
    "Fl": ("Flier", "A chess piece for the Barsoomian Flier (aerial warrior). It has swept-back wing shapes or a propeller/airship motif at the top, suggesting flight and speed, sitting on a standard chess piece base."),
    "Dw": ("Dwar", "A chess piece for the Barsoomian Dwar (commander). It has a plumed military helmet with a tall central crest or plume, suggesting a high-ranking officer, sitting on a standard chess piece base."),
    "Pd": ("Padwar", "A chess piece for the Barsoomian Padwar (lieutenant). It has a simpler military cap or helm with a small forward-pointing visor, less ornate than the Dwar, sitting on a standard chess piece base."),
    "Wa": ("Warrior", "A chess piece for the Barsoomian Warrior. It has a round shield shape at the top with a small sword or blade crossing behind it, martial and ready for combat, sitting on a standard chess piece base."),
    "Th": ("Thoat", "A chess piece for the Barsoomian Thoat (war mount). It has an animal head shape — like a stylized horse or alien beast with pointed ears and an elongated snout, suggesting a riding beast, sitting on a standard chess piece base."),
    "Pa": ("Panthan", "A chess piece for the Barsoomian Panthan (foot soldier/mercenary). It is the simplest piece — a plain rounded dome top like a pawn but slightly taller, with a single horizontal band around the middle, sitting on a standard chess piece base."),
}


def generate_piece_image(prompt: str) -> bytes | None:
    """Call Gemini imagen API and return PNG bytes."""
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
        },
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(req, timeout=90, context=SSL_CTX) as resp:
            result = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  API error {e.code}: {body[:200]}")
        return None
    except Exception as e:
        print(f"  Request error: {e}")
        return None

    # Extract image from response
    try:
        for candidate in result.get("candidates", []):
            for part in candidate.get("content", {}).get("parts", []):
                if "inlineData" in part:
                    return base64.b64decode(part["inlineData"]["data"])
    except (KeyError, IndexError) as e:
        print(f"  Parse error: {e}")
        print(f"  Response keys: {list(result.keys())}")

    print(f"  No image in response. Keys: {list(result.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].keys()) if result.get('candidates') else 'no candidates'}")
    return None


def remove_white_background(png_bytes: bytes) -> bytes:
    """Remove white/near-white background pixels, making them transparent."""
    try:
        from PIL import Image
        import io

        img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
        pixels = list(img.getdata())
        new_pixels = [
            (255, 255, 255, 0) if r > 230 and g > 230 and b > 230 else (r, g, b, a)
            for r, g, b, a in pixels
        ]
        img.putdata(new_pixels)

        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue()
    except ImportError:
        print("  WARNING: Pillow not installed, skipping background removal")
        return png_bytes


def generate_all_pieces():
    all_pieces = {}
    all_pieces.update({k: ("compound", *v) for k, v in COMPOUND_PIECES.items()})
    all_pieces.update({k: ("jetan", *v) for k, v in JETAN_PIECES.items()})

    total = len(all_pieces) * 2  # white + black
    done = 0

    for symbol, (subdir, name, desc) in all_pieces.items():
        out_dir = OUTPUT_DIR / subdir
        out_dir.mkdir(parents=True, exist_ok=True)

        for color, color_style in [("w", WHITE_STYLE), ("b", BLACK_STYLE)]:
            done += 1
            filename = f"{color}{symbol}.png"
            filepath = out_dir / filename

            if filepath.exists():
                print(f"[{done}/{total}] SKIP {filepath.name} (exists)")
                continue

            prompt = STYLE_PREFIX + color_style + desc
            print(f"[{done}/{total}] Generating {filepath.name} ({name})...")

            png_data = generate_piece_image(prompt)
            if png_data is None:
                print(f"  FAILED to generate {filename}")
                continue

            # Remove white background
            png_data = remove_white_background(png_data)

            filepath.write_bytes(png_data)
            print(f"  Saved {filepath} ({len(png_data)} bytes)")

            # Rate limiting — be gentle with the API
            time.sleep(2)

    print(f"\nDone! Generated {done} pieces.")


if __name__ == "__main__":
    generate_all_pieces()
