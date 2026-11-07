#!/usr/bin/env python3
"""Compress generated Persian Mega Drive 4bpp tiles as Nemesis streams.

The output is a verified compressed asset for later ROM integration. This
script deliberately does not claim to patch the ROM or sprite mappings.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path


def run(args: list[str]) -> None:
    subprocess.run(args, check=True)


def main() -> None:
    source_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "persian-font")
    output_dir = Path(sys.argv[2] if len(sys.argv) > 2 else "persian-font-nemesis")
    tool = Path(sys.argv[3] if len(sys.argv) > 3 else "/usr/local/bin/clownnemesis-tool")
    output_dir.mkdir(parents=True, exist_ok=True)
    report = []

    inputs = sorted(source_dir.glob("*.4bpp"))
    if not inputs:
        raise SystemExit(f"No 4bpp tile files found in {source_dir}")

    for source in inputs:
        raw = source.read_bytes()
        if not raw or len(raw) % 32:
            raise SystemExit(f"{source}: tile data must be non-empty and a multiple of 32 bytes")
        compressed = output_dir / f"{source.stem}.nem"
        restored = output_dir / f"{source.stem}.roundtrip.4bpp"
        run([str(tool), "-c", str(source), str(compressed)])
        run([str(tool), "-d", str(compressed), str(restored)])
        rebuilt = restored.read_bytes()
        if rebuilt != raw:
            raise SystemExit(f"Nemesis round-trip mismatch: {source}")
        restored.unlink()
        report.append({
            "source": source.name,
            "compressed": compressed.name,
            "input_bytes": len(raw),
            "compressed_bytes": compressed.stat().st_size,
            "sha256": hashlib.sha256(raw).hexdigest(),
            "roundtrip": "exact",
        })

    (output_dir / "compression-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
