#!/usr/bin/env python3
"""Render the checked-in fa-IR catalog as Mega Drive 4bpp glyph tiles.

This connects translations/fa-IR.json to the graphics-generation stage.
It does NOT insert the graphics into the ROM: Nemesis streams and in-game
sprite mappings still require a verified ROM patch.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "translations" / "fa-IR.json"
KEY_MAP = {
    "press_start": "press_start_button",
    "score": "score",
    "time": "time",
    "rings": "rings",
    "try_again": "try_again",
    "level_select": "level_select",
    "team_presents": "sonic_team_presents",
}


def find_font() -> str:
    candidates = [
        "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return path
    try:
        path = subprocess.check_output(
            ["fc-match", "-f", "%{file}", "Noto Naskh Arabic"], text=True
        ).strip()
        if path and Path(path).exists():
            return path
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
        out.extend(planes)
    return bytes(out)


def main() -> None:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "persian-font")
    out.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    source = catalog["game"]
    labels = {key: source[value] for key, value in KEY_MAP.items()}
    font_path = find_font()
    font = ImageFont.truetype(font_path, 13)
    manifest = {
        "locale": catalog.get("locale", "fa-IR"),
        "direction": catalog.get("direction", "rtl"),
        "font": font_path,
        "format": "Mega Drive 4bpp, 8x8 tiles",
        "catalog": "translations/fa-IR.json",
        "labels": {},
    }

    for key, text in labels.items():
        shaped = get_display(arabic_reshaper.reshape(text))
        probe = Image.new("L", (1, 1), 0)
        bbox = ImageDraw.Draw(probe).textbbox((0, 0), shaped, font=font)
        width = max(8, bbox[2] - bbox[0] + 4)
        height = max(8, bbox[3] - bbox[1] + 2)
        image = Image.new("L", (width, height), 0)
        ImageDraw.Draw(image).text(
            (2 - bbox[0], 1 - bbox[1]), shaped, fill=255, font=font
        )
        padded_w = (image.width + 7) // 8 * 8
        padded_h = (image.height + 7) // 8 * 8
        padded = Image.new("L", (padded_w, padded_h), 0)
        padded.paste(image, (0, 0))
        mono = padded.point(lambda p: 255 if p >= 96 else 0)
        mono.save(out / f"{key}.png")

        raw = bytearray()
        for ty in range(0, padded_h, 8):
            for tx in range(0, padded_w, 8):
                raw.extend(encode_tile_4bpp(mono.crop((tx, ty, tx + 8, ty + 8))))
        (out / f"{key}.4bpp").write_bytes(raw)
        manifest["labels"][key] = {
            "persian": text,
            "shaped": shaped,
            "width_px": padded_w,
            "height_px": padded_h,
            "tile_count": len(raw) // 32,
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
