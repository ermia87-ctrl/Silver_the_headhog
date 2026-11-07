#!/usr/bin/env python3
"""Patch the three visible Sonic 1 HUD labels with Persian pixel lettering.

The original HUD reserves 13 two-tile glyph slots before the numeric counters.
We use 12 of those slots (4 glyphs per label), preserving every counter tile.
"""
from __future__ import annotations
import hashlib, json, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(sys.argv[1])
TOOL = Path(sys.argv[2])
OUT = ROOT / "hud-patch"
CATALOG = ROOT / "translations" / "fa-IR.json"
LABELS = (("score", 0x00), ("rings", 0x08), ("time", 0x10))
TILE_BYTES = 32

def run(args):
    subprocess.run(args, check=True)

def font_path():
    p = Path("/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf")
    if not p.exists():
        raise SystemExit("Noto Naskh Arabic font not installed")
    return str(p)

def encode_tile(tile):
    px = tile.load()
    out = bytearray()
    for y in range(8):
        planes = [0, 0, 0, 0]
        for x in range(8):
            v = 1 if px[x, y] else 0
            for plane in range(4):
                if v & (1 << plane):
                    planes[plane] |= 1 << (7-x)
        out.extend(planes)
    return bytes(out)

def render_label(text, font):
    visual = get_display(arabic_reshaper.reshape(text))
    probe = Image.new("L", (1, 1), 0)
    bbox = ImageDraw.Draw(probe).textbbox((0, 0), visual, font=font)
    w, h = bbox[2]-bbox[0], bbox[3]-bbox[1]
    if w <= 0 or h <= 0:
        raise SystemExit(f"Invalid glyph bounds for {text!r}")
    image = Image.new("L", (32, 16), 0)
    draw = ImageDraw.Draw(image)
    draw.text(((32-w)//2-bbox[0], (16-h)//2-bbox[1]), visual, fill=255, font=font)
    if w > 32 or h > 16:
        scale = min(32 / w, 16 / h)
        resized = Image.new("L", (max(1, round(w*scale)), max(1, round(h*scale))), 0)
        glyph = Image.new("L", (w, h), 0)
        ImageDraw.Draw(glyph).text((-bbox[0], -bbox[1]), visual, fill=255, font=font)
        resized = glyph.resize(resized.size, Image.Resampling.LANCZOS)
        image = Image.new("L", (32,16), 0)
        image.paste(resized, ((32-resized.width)//2, (16-resized.height)//2))
    return image.point(lambda p: 255 if p >= 96 else 0), visual

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    asset = SOURCE / "artnem" / "HUD.nem"
    raw = OUT / "hud.raw"
    patched_raw = OUT / "hud.patched.raw"
    run([str(TOOL), "-d", str(asset), str(raw)])
    original = raw.read_bytes()
    if len(original) < 24*TILE_BYTES:
        raise SystemExit(f"HUD asset too short: {len(original)} bytes")
    patched = bytearray(original)
    font = ImageFont.truetype(font_path(), 13)
    reports = []
    for key, start_tile in LABELS:
        text = catalog["game"][key]
        image, visual = render_label(text, font)
        image.save(OUT / f"{key}-fa.png")
        tile_rows = []
        for ty in range(2):
            for tx in range(4):
                tile_rows.append(encode_tile(image.crop((tx*8, ty*8, tx*8+8, ty*8+8))))
        data = b"".join(tile_rows)
        if len(data) != 8*TILE_BYTES:
            raise SystemExit("Unexpected HUD label tile count")
        start = start_tile*TILE_BYTES
        patched[start:start+len(data)] = data
        reports.append({"key":key,"text":text,"visual_order":visual,"tile_start":start_tile,"tile_count":8})
    patched_raw.write_bytes(patched)
    run([str(TOOL), "-c", str(patched_raw), str(asset)])
    verify = OUT / "hud.verify.raw"
    run([str(TOOL), "-d", str(asset), str(verify)])
    rebuilt = verify.read_bytes()
    if rebuilt != bytes(patched):
        raise SystemExit("HUD Nemesis round-trip mismatch")
    verify.unlink()

    mapping_path = SOURCE / "_maps" / "HUD.asm"
    mapping = mapping_path.read_text(encoding="utf-8")
    old_score = 'spritePiece\t$20, -$80, 4, 2, $18, 0, 0, 0, 1\t; "E" and first three score digits'
    new_score = 'spritePiece\t$20, -$80, 3, 2, $1A, 0, 0, 0, 1\t; first three score digits; Persian label is four glyphs'
    count_score = mapping.count(old_score)
    if count_score != 4:
        raise SystemExit(f"Expected 4 SCORE mappings, found {count_score}")
    mapping = mapping.replace(old_score, new_score)
    ring_lines = mapping.splitlines()
    count_ring = 0
    for index, line in enumerate(ring_lines):
        if "spritePiece" in line and "$20, -$60, 1, 2, 0, 0, 0," in line:
            ring_lines[index] = "; Persian RINGS label uses four glyphs; old separate S tile removed"
            count_ring += 1
    if count_ring != 4:
        raise SystemExit(f"Expected 4 RINGS mappings, found {count_ring}")
    mapping = "\n".join(ring_lines) + "\n"
    mapping_path.write_text(mapping, encoding="utf-8")

    report = {
      "patch":"persian_hud_labels",
      "labels":reports,
      "score_digits_mapping":"preserved; E slot freed and digit block starts at tile $1A",
      "rings_counter_mapping":"preserved; standalone S sprite removed",
      "original_asset_bytes":len(original),
      "patched_asset_bytes":len(patched),
      "original_sha256":hashlib.sha256(original).hexdigest(),
      "patched_sha256":hashlib.sha256(patched).hexdigest(),
      "nemesis_roundtrip":"exact",
      "score_map_replacements":count_score,
      "rings_map_replacements":count_ring
    }
    (OUT/"hud-patch-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__ == "__main__":
    main()
