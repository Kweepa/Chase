#!/usr/bin/env python3
"""Extract Spectrum Death Chase binary from TAP (Deathchas2 block)."""

from __future__ import annotations

import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TAP_DEFAULT = ROOT / "3D Death Chase (1983)(Micromega)[a].tap"
OUT_BIN = ROOT / "build" / "deathchase.bin"
OUT_MAP = ROOT / "build" / "tape_map.txt"
ENTRY_ADDR = 0x657F
LOAD_ORG = 0x4000


def parse_tap(data: bytes) -> list[bytes]:
    blocks: list[bytes] = []
    pos = 0
    while pos + 2 <= len(data):
        blen = struct.unpack_from("<H", data, pos)[0]
        pos += 2
        blocks.append(data[pos : pos + blen])
        pos += blen
    return blocks


def main() -> int:
    tap_path = Path(sys.argv[1]) if len(sys.argv) > 1 else TAP_DEFAULT
    data = tap_path.read_bytes()
    blocks = parse_tap(data)

    lines = [f"TAP: {tap_path}", f"Blocks: {len(blocks)}", ""]
    for i, block in enumerate(blocks, 1):
        if not block:
            continue
        if block[0] == 0:
            name = block[2:12].decode("ascii", errors="replace").rstrip("\x00")
            length = struct.unpack_from("<H", block, 12)[0]
            addr = struct.unpack_from("<H", block, 14)[0]
            lines.append(
                f"Block {i}: HEADER name={name!r} len={length} addr=0x{addr:04X}"
            )
        elif block[0] == 0xFF:
            dlen = struct.unpack_from("<H", block, 1)[0]
            payload = block[3:-1] if len(block) > 4 else b""
            lines.append(
                f"Block {i}: DATA declared={dlen} payload={len(payload)}"
            )

    # Deathchas2 is block 4 (index 3)
    if len(blocks) < 4:
        print("Expected at least 4 TAP blocks", file=sys.stderr)
        return 1
    code_block = blocks[3]
    if code_block[0] != 0xFF:
        print("Block 4 is not a data block", file=sys.stderr)
        return 1
    payload = code_block[3:-1]
    if len(payload) < 100:
        print(f"Block 4 payload too small: {len(payload)}", file=sys.stderr)
        return 1

    OUT_BIN.parent.mkdir(parents=True, exist_ok=True)
    OUT_BIN.write_bytes(payload)
    OUT_MAP.write_text("\n".join(lines) + "\n", encoding="utf-8")

    entry_off = ENTRY_ADDR - LOAD_ORG
    if entry_off < 0 or entry_off + 4 > len(payload):
        print(f"Entry 0x{ENTRY_ADDR:04X} out of range", file=sys.stderr)
        return 1
    entry_bytes = payload[entry_off : entry_off + 4]
    print(f"Wrote {OUT_BIN} ({len(payload)} bytes, org 0x{LOAD_ORG:04X})")
    print(f"Entry 0x{ENTRY_ADDR:04X}: {entry_bytes.hex()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
