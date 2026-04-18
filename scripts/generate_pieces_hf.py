#!/usr/bin/env python3
"""Generate chess pieces via Hugging Face Inference Providers.

Designed for quick model/provider swapping — change MODEL_ID and PROVIDER
at top, or pass --model and --provider. Outputs go to a test directory
so existing assets are never overwritten.

Anchor-reference workflow (FLUX.1-Kontext): feeds an existing piece PNG
as input and asks the model for the same style but a different piece.

Env: HF_TOKEN must be set (or pass --token).
"""

import argparse
import base64
import io
import os
import sys
import time
from pathlib import Path

from huggingface_hub import InferenceClient

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "pieces"
OUT_DIR = ROOT / "assets" / "pieces_hf_test"

ANCHOR_REF = ASSETS / "compound" / "wA.png"  # giraffe / amazon — chosen as anchor style

STYLE_NOTE = (
    "Flat black line illustration of a single chess piece on a plain white background. "
    "Bold clean black outlines, white interior fill, no shadows, no gradients, no 3D. "
    "Mounted on a classic chess piece pedestal base with flared foot. "
    "The figure fills about 80 percent of a square frame, centered. "
    "Match the exact line weight and hand-drawn woodcut feel of the reference image. "
)

# Test targets — pieces currently mismatched with the anchor style
TARGETS = {
    "Ch": "Replace the giraffe figure with a warrior champion: a broad round shield with a bold cross emblem centered on it, held upright atop the chess piece pedestal. Keep the same line weight, pedestal base, and hand-carved feel.",
    "W":  "Replace the giraffe figure with a wizard: a tall pointed wizard hat with a small crescent moon cutout near the tip, rising from the chess piece pedestal. Keep the same line weight, pedestal base, and hand-carved feel.",
    "Hu": "Replace the giraffe figure with a hunter: an upward-pointing arrowhead or spearpoint carved atop the chess piece pedestal, with a slight hourglass taper to the body. Keep the same line weight, pedestal base, and hand-carved feel.",
}


# --- model presets --- #
# Each entry: (model_id, provider, mode)
#   mode = "kontext"       -> image_to_image with reference
#   mode = "text_to_image" -> text-only generation
PRESETS = {
    "flux-kontext": ("black-forest-labs/FLUX.1-Kontext-dev", "fal-ai", "kontext"),
    "flux-schnell": ("black-forest-labs/FLUX.1-schnell", "fal-ai", "text_to_image"),
    "flux-dev":     ("black-forest-labs/FLUX.1-dev", "fal-ai", "text_to_image"),
    "sdxl":         ("stabilityai/stable-diffusion-xl-base-1.0", "hf-inference", "text_to_image"),
    "sd35-large":   ("stabilityai/stable-diffusion-3.5-large", "hf-inference", "text_to_image"),
}


def gen_one(client: InferenceClient, model: str, mode: str, prompt: str, ref_path: Path):
    full_prompt = f"{STYLE_NOTE}{prompt}"
    if mode == "kontext":
        with open(ref_path, "rb") as f:
            ref_bytes = f.read()
        return client.image_to_image(ref_bytes, prompt=full_prompt, model=model)
    return client.text_to_image(full_prompt, model=model)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", default="flux-kontext", choices=list(PRESETS))
    ap.add_argument("--model", help="Override model id (bypasses preset)")
    ap.add_argument("--provider", help="Override provider (bypasses preset)")
    ap.add_argument("--mode", choices=["kontext", "text_to_image"], help="Override mode")
    ap.add_argument("--token", default=os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_API_KEY"))
    ap.add_argument("--ref", default=str(ANCHOR_REF))
    ap.add_argument("--targets", nargs="*", default=list(TARGETS), help="Symbols to generate")
    ap.add_argument("--tag", default=None, help="Suffix tag for output filenames")
    args = ap.parse_args()

    if not args.token:
        sys.exit("ERROR: HF_TOKEN not set. export HF_TOKEN=hf_... or pass --token")

    model_id, provider, mode = PRESETS[args.preset]
    if args.model:    model_id = args.model
    if args.provider: provider = args.provider
    if args.mode:     mode = args.mode
    tag = args.tag or args.preset

    ref = Path(args.ref)
    if mode == "kontext" and not ref.exists():
        sys.exit(f"ERROR: reference image not found: {ref}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    client = InferenceClient(provider=provider, token=args.token)

    print(f"model={model_id} provider={provider} mode={mode}")
    print(f"ref={ref if mode == 'kontext' else '(none)'}  out={OUT_DIR}")

    for sym in args.targets:
        prompt = TARGETS.get(sym)
        if not prompt:
            print(f"  skip {sym}: no prompt defined")
            continue
        out = OUT_DIR / f"w{sym}_{tag}.png"
        if out.exists():
            print(f"  skip {sym}: {out.name} exists")
            continue
        print(f"  gen  {sym} -> {out.name}", flush=True)
        t0 = time.time()
        try:
            img = gen_one(client, model_id, mode, prompt, ref)
            img.save(out)
            print(f"       ok ({time.time()-t0:.1f}s, {out.stat().st_size//1024}KB)")
        except Exception as e:
            print(f"       FAIL: {type(e).__name__}: {e}")
        time.sleep(2)


if __name__ == "__main__":
    main()
