#!/usr/bin/env python3
"""Inspect a Sega Mega Drive ROM header and report basic revision metadata."""
from pathlib import Path
import hashlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: inspect_rom_header.py ROM")
path = Path(sys.argv[1])
rom = path.read_bytes()
if len(rom) < 0x200:
    raise SystemExit(f"ROM is too small for a Mega Drive header: {len(rom)} bytes")

def field(start, end):
    return rom[start:end].decode("ascii", errors="replace").strip().replace("\x00", "")

stored_checksum = int.from_bytes(rom[0x18E:0x190], "big")
calculated_checksum = sum(
    int.from_bytes(rom[i:i+2], "big")
    for i in range(0x200, len(rom) - ((len(rom) - 0x200) % 2), 2)
) & 0xFFFF
print(f"File: {path}")
print(f"Size: {len(rom)} bytes ({len(rom) / 1024:.1f} KiB)")
print(f"SHA-256: {hashlib.sha256(rom).hexdigest()}")
print(f"Console: {field(0x100, 0x110)}")
print(f"Domestic title: {field(0x120, 0x150)}")
print(f"International title: {field(0x150, 0x180)}")
print(f"Product code: {field(0x180, 0x18E)}")
print(f"Stored checksum: 0x{stored_checksum:04X}")
print(f"Calculated checksum: 0x{calculated_checksum:04X}")
print(f"Checksum match: {stored_checksum == calculated_checksum}")
print(f"ROM start: 0x{int.from_bytes(rom[0x1A0:0x1A4], 'big'):08X}")
print(f"ROM end: 0x{int.from_bytes(rom[0x1A4:0x1A8], 'big'):08X}")
print(f"Region: {field(0x1F0, 0x200)}")
