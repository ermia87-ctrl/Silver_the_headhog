#!/usr/bin/env python3
"""Inspect a Mega Drive ROM header and list printable ASCII runs; read-only."""
from pathlib import Path
import sys

p = Path(sys.argv[1])
data = p.read_bytes()
if len(data) < 0x200:
    raise SystemExit("ERROR: file is smaller than a Mega Drive ROM header")

def field(a, b):
    return data[a:b].decode("ascii", errors="replace").strip()

checksum = int.from_bytes(data[0x18E:0x190], "big")
serial = field(0x180, 0x18E)
title = field(0x120, 0x150)
print(f"ROM file: {p.name}")
print(f"Size: {len(data)} bytes ({len(data) / 1024:.1f} KiB)")
print(f"Console: {field(0x100, 0x110)}")
print(f"Title: {title}")
print(f"Serial: {serial}")
print(f"Header checksum: 0x{checksum:04X}")
if len(data) == 524288 and checksum == 0x264A:
    print("Revision match: Sonic 1 USA/EU REV00 (expected checksum 0x264A)")
elif len(data) == 524288 and checksum == 0xAFC7:
    print("Revision match: Sonic 1 REV01 (expected checksum 0xAFC7)")
else:
    print("Revision match: unconfirmed; compare header and checksum with the intended ROM revision")

runs = []
start = None
for i, b in enumerate(data):
    ok = 32 <= b <= 126
    if ok and start is None:
        start = i
    elif not ok and start is not None:
        if i - start >= 4:
            s = data[start:i].decode("ascii", errors="replace")
            if any(c.isalpha() for c in s):
                runs.append((start, s))
        start = None
if start is not None and len(data) - start >= 4:
    runs.append((start, data[start:].decode("ascii", errors="replace")))
print("\nPrintable ASCII runs (these do not include tile-based lettering):")
for off, s in runs[:100]:
    print(f"0x{off:06X}: {s}")
print("\nNote: most visible Sonic 1 menu/HUD lettering is graphics, not ASCII text.")
