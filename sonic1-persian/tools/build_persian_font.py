#!/usr/bin/env python3
"""Render Persian Sonic 1 labels into Mega Drive 4bpp tile data.

This produces graphics assets only. It deliberately does not patch the ROM:
the game's compressed-art pointers and sprite mappings must be updated and
verified before these tiles can safely be inserted.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

LABELS = {
    "press_start": "برای شروع دکمه‌ای بزنید",
    "score": "امتیاز",
    "time": "زمان",
    "rings": "حلقه‌ها",
    "try_again": "دوباره تلاش کن",
    "level_select": "انتخاب مرحله",
    "team_presents": "تیم سونیک تقدیم می‌کند",
}

def find_font() -> str:
    candidates = [
        "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for p in candidates:
        if Path(p).exists():
            return p
    try:
        p = subprocess.check_output(
            ["fc-match", "-f", "%{file}", "Noto Naskh Arabic"],
            text=True,
        ).strip()
        if p and Path(p).exists():
            return p
    except (OSError, subprocess.CalledProcessError):
        pass
    raise SystemExit("No Arabic-capable font found. Install fonts-noto-core.")

def encode_tile_4bpp(tile: Image.Image) -> bytes:
    px = tile.load()
    out = bytearray()
    for y in range(8):
        planes = [0, 0, 0, 0]
        for x in range(8):
            value = 1 if px[x, y] else 0
            bit = 7 - x
            for plane in range(4):
                if value & (1 << plane):
                    planes[plane] |= 1 << bit
        for plane in range(4):
            out.extend((planes[plane], 0))
    return bytes(out)

def main() -> None:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "persian-font")
    out.mkdir(parents=True, exist_ok=True)
    font_path = find_font()
    font = ImageFont.truetype(font_path, 13)
    manifest = {"font": font_path, "format": "Mega Drive 4bpp, 8x8 tiles", "labels": {}}

    for key, text in LABELS.items():
        shaped = get_display(arabic_reshaper.reshape(text))
        probe = Image.new("L", (1, 1), 0)
        draw = ImageDraw.Draw(probe)
        bbox = draw.textbbox((0, 0), shaped, font=font, direction="rtl")
        width = max(8, bbox[2] - bbox[0] + 4)
        height = max(8, bbox[3] - bbox[1] + 2)
        image = Image.new("L", (width, height), 0)
        d = ImageDraw.Draw(image)
        d.text((2 - bbox[0], 1 - bbox[1]), shaped, fill=255, font=font, direction="rtl")
        # Pad to complete 8x8 tiles.
        padded_w = (image.width + 7) // 8 * 8
        padded_h = (image.height + 7) // 8 * 8
        padded = Image.new("L", (padded_w, padded_h), 0)
        padded.paste(image, (0, 0))
        mono = padded.point(lambda p: 255 if p >= 96 else 0)
        mono.save(out / f"{key}.png")

        raw = bytearray()
        tile_count = 0
        for ty in range(0, padded_h, 8):
            for tx in range(0, padded_w, 8):
                tile = mono.crop((tx, ty, tx + 8, ty + 8))
                raw.extend(encode_tile_4bpp(tile))
                tile_count += 1
        (out / f"{key}.4bpp").write_bytes(raw)
        manifest["labels"][key] = {
            "persian": text,
            "shaped": shaped,
            "width_px": padded_w,
            "height_px": padded_h,
            "tile_count": tile_count,
            "bytes": len(raw),
            "png": f"{key}.png",
            "tiles": f"{key}.4bpp",
        }

    (out / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(manifest, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
