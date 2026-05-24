#!/usr/bin/env python3
"""
Generate a 1024x500 Google Play feature graphic for WeirdChess.

Pulls colors and type from the existing app identity:
  - Charcoal #1A1A1A -> Slate #2D3542 linear gradient
  - Salmon accent #FF9B8A for the tagline
  - Righteous typeface for all text
  - icon_1024.png placed on the left, vertically centered

Usage:
    python3 scripts/make_feature_graphic.py
Output: assets/images/feature_graphic_1024x500.png
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "assets" / "images" / "icon_1024.png"
FONT_PATH = ROOT / "assets" / "fonts" / "Righteous-Regular.ttf"
OUT_PATH = ROOT / "assets" / "images" / "feature_graphic_1024x500.png"

W, H = 1024, 500
CHARCOAL = (26, 26, 26)
SLATE = (45, 53, 66)
SALMON = (255, 155, 138)
WHITE = (255, 255, 255)
SOFT_WHITE = (230, 230, 230)


def make_gradient(size, top_color, bottom_color):
    w, h = size
    img = Image.new("RGB", size, top_color)
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        r = int(top_color[0] * (1 - t) + bottom_color[0] * t)
        g = int(top_color[1] * (1 - t) + bottom_color[1] * t)
        b = int(top_color[2] * (1 - t) + bottom_color[2] * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return img


def main():
    # Background gradient (charcoal top -> slate bottom, subtle)
    bg = make_gradient((W, H), CHARCOAL, SLATE)
    draw = ImageDraw.Draw(bg)

    # Soft vignette glow around icon area
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    cx, cy, r = 235, H // 2, 260
    for i in range(40, 0, -1):
        alpha = int(6 * (i / 40))
        glow_draw.ellipse(
            (cx - r - i, cy - r - i, cx + r + i, cy + r + i),
            fill=(255, 155, 138, alpha),
        )
    bg = Image.alpha_composite(bg.convert("RGBA"), glow)
    draw = ImageDraw.Draw(bg)

    # Icon: resize and paste at left, vertically centered
    icon_size = 360
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
    icon_x = 55
    icon_y = (H - icon_size) // 2
    bg.paste(icon, (icon_x, icon_y), icon)

    # Type block on the right
    title_font = ImageFont.truetype(str(FONT_PATH), 120)
    tagline_font = ImageFont.truetype(str(FONT_PATH), 34)
    sub_font = ImageFont.truetype(str(FONT_PATH), 26)

    text_x = 470

    # Title: "WEIRD" / "CHESS" stacked
    draw.text((text_x, 100), "WEIRD", font=title_font, fill=WHITE)
    draw.text((text_x, 230), "CHESS", font=title_font, fill=SALMON)

    # Tagline
    draw.text(
        (text_x, 375),
        "12 VARIANTS  ·  8×8 + 10×10",
        font=tagline_font,
        fill=SOFT_WHITE,
    )
    draw.text(
        (text_x, 415),
        "AI commentary  ·  pigeon chaos",
        font=sub_font,
        fill=(200, 200, 200),
    )

    # Thin salmon divider between icon and text
    draw.rectangle([(440, 130), (442, 370)], fill=SALMON)

    bg.convert("RGB").save(OUT_PATH, format="PNG", optimize=True)
    print(f"Wrote {OUT_PATH} ({OUT_PATH.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
