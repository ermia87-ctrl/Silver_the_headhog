#!/usr/bin/env python3
"""Create a compact 8x8 Persian title prompt and patch the Sonic 1 source ROM.

Only the original PRESS START BUTTON art tiles are replaced. Gameplay data,
music, level art, physics, and all other original assets remain untouched.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "translations" / "fa-IR.json"
SOURCE_ROOT = Path(sys.argv[1])
NEMESIS_TOOL = Path(sys.argv[2])
OUT = ROOT / "title-patch"
TEXT = "press_start_button"
TILE_START = 0xF0
TILE_COUNT = 14
TILE_BYTES = TILE_COUNT * 32
WIDTH, HEIGHT = TILE_COUNT * 8, 8


def run(args: list[str]) -> None:
    subprocess.run(args, check=True)


def find_font() -> str:
    for p in (
        "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if Path(p).exists():
            return p
    raise SystemExit("Noto Arabic font not found")


def encode_tile(tile: Image.Image) -> bytes:
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
    OUT.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    persian = catalog["game"][TEXT]
    visual = get_display(arabic_reshaper.reshape(persian))
    font = ImageFont.truetype(find_font(), 8)

    probe = Image.new("L", (1, 1), 0)
    bbox = ImageDraw.Draw(probe).textbbox((0, 0), visual, font=font)
    glyph_w, glyph_h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    if glyph_w > WIDTH or glyph_h > HEIGHT:
        raise SystemExit(
            f"Persian title text does not fit original 14-tile slot: "
            f"{glyph_w}x{glyph_h}px > {WIDTH}x{HEIGHT}px"
        )

    image = Image.new("L", (WIDTH, HEIGHT), 0)
    draw = ImageDraw.Draw(image)
    x = (WIDTH - glyph_w) // 2 - bbox[0]
    y = (HEIGHT - glyph_h) // 2 - bbox[1]
    draw.text((x, y), visual, fill=255, font=font)
    image = image.point(lambda p: 255 if p >= 96 else 0)
    image.save(OUT / "press-start-persian.png")

    tile_data = bytearray()
    for tx in range(0, WIDTH, 8):
        tile_data.extend(encode_tile(image.crop((tx, 0, tx + 8, 8))))
    if len(tile_data) != TILE_BYTES:
        raise SystemExit("Unexpected Persian title tile data size")
    (OUT / "press-start-persian.4bpp").write_bytes(tile_data)

    source_asset = SOURCE_ROOT / "artnem" / "Title Screen Foreground.nem"
    raw = OUT / "title-foreground.raw"
    patched_raw = OUT / "title-foreground.patched.raw"
    compressed = source_asset
    run([str(NEMESIS_TOOL), "-d", str(source_asset), str(raw)])
    original = raw.read_bytes()
    start = TILE_START * 32
    end = start + TILE_BYTES
    if len(original) < end:
        raise SystemExit(
            f"Title foreground only has {len(original)//32} tiles; "
            f"cannot safely replace reserved tile range {TILE_START:#x}-{TILE_START+TILE_COUNT-1:#x}"
        )

    patched = bytearray(original)
    patched[start:end] = tile_data
    patched_raw.write_bytes(patched)
    run([str(NEMESIS_TOOL), "-c", str(patched_raw), str(compressed)])
    verify = OUT / "title-foreground.verify.raw"
    run([str(NEMESIS_TOOL), "-d", str(compressed), str(verify)])
    rebuilt = verify.read_bytes()
    if rebuilt != bytes(patched):
        raise SystemExit("Nemesis compressed title asset failed exact round-trip")
    verify.unlink()

    map_file = SOURCE_ROOT / "_maps" / "Press Start and TM.asm"
    mapping = map_file.read_text(encoding="utf-8")
    old = """\tspritePiece\t0, 0, 4, 1, $F0, 0, 0, 0, 0\t; \"PRESS START BUTTON\"
\tspritePiece\t$20, 0, 1, 1, $F3, 0, 0, 0, 0
\tspritePiece\t$30, 0, 1, 1, $F3, 0, 0, 0, 0
\tspritePiece\t$38, 0, 4, 1, $F4, 0, 0, 0, 0
\tspritePiece\t$60, 0, 3, 1, $F8, 0, 0, 0, 0
\tspritePiece\t$78, 0, 3, 1, $FB, 0, 0, 0, 0"""
    new = """\tspritePiece\t0, 0, 4, 1, $F0, 0, 0, 0, 0\t; Persian: \"برای شروع دکمه‌ای بزنید\"
\tspritePiece\t$20, 0, 4, 1, $F4, 0, 0, 0, 0
\tspritePiece\t$40, 0, 4, 1, $F8, 0, 0, 0, 0
\tspritePiece\t$60, 0, 2, 1, $FC, 0, 0, 0, 0"""
    if old not in mapping:
        raise SystemExit("Original PRESS START sprite mapping did not match expected REV00 source")
    map_file.write_text(mapping.replace(old, new), encoding="utf-8")

    report = {
        "patch": "title_press_start_only",
        "persian_text": persian,
        "visual_order": visual,
        "image_size": [WIDTH, HEIGHT],
        "tile_start": TILE_START,
        "tile_count": TILE_COUNT,
        "original_asset_bytes": len(original),
        "patched_asset_bytes": len(patched),
        "original_asset_sha256": hashlib.sha256(original).hexdigest(),
        "patched_asset_sha256": hashlib.sha256(patched).hexdigest(),
        "roundtrip": "exact",
        "map_updated": True,
        "scope": "Only title PRESS START BUTTON text graphics and sprite mapping",
    }
    (OUT / "patch-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
