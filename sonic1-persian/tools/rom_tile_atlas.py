#!/usr/bin/env python3
"""Create indexed tile atlases from the supplied Mega Drive ROM for localization review.
Mega Drive 4bpp tiles are 8x8 pixels, 32 bytes each, with four bitplanes per row.
This is an inspection tool only: it never modifies the source ROM.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import sys

src = Path(sys.argv[1])
out = Path(sys.argv[2])
data = src.read_bytes()
tile_size = 32
tiles = len(data) // tile_size
page_tiles = 256
cell_w, cell_h = 72, 58
cols, rows = 16, 16
out.mkdir(parents=True, exist_ok=True)

def decode(chunk):
    im = Image.new("L", (8, 8), 0)
    px = im.load()
    for y in range(8):
        row = chunk[y * 4:y * 4 + 4]
        for x in range(8):
            bit = 7 - x
            value = sum(((row[p] >> bit) & 1) << p for p in range(4))
            px[x, y] = value * 17
    return im

for page_start in range(0, tiles, page_tiles):
    page = Image.new("RGB", (cols * cell_w, rows * cell_h), (32, 32, 32))
    draw = ImageDraw.Draw(page)
    for local in range(min(page_tiles, tiles - page_start)):
        idx = page_start + local
        x, y = (local % cols) * cell_w, (local // cols) * cell_h
        tile = decode(data[idx * tile_size:(idx + 1) * tile_size]).resize((32, 32))
        page.paste(tile.convert("RGB"), (x + 20, y + 2))
        draw.text((x + 2, y + 39), f"{idx:05d}", fill=(255, 255, 255))
    page.save(out / f"tiles_{page_start:05d}_{page_start + page_tiles - 1:05d}.png")
(out / "README.txt").write_text(
    f"ROM bytes: {len(data)}\\nDecoded 8x8 tiles: {tiles}\\n"
    "Atlas is a raw byte-aligned tile scan, not yet a map of in-game text. "
    "The original ROM was not modified.\\n", encoding="utf-8")
print(f"Created atlases for {tiles} tiles")
