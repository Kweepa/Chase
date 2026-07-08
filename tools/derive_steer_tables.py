#!/usr/bin/env python3
"""Re-derive scroll_tab_left/right from scroll_tab_forward in scroll.asm."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCROLL_ASM = ROOT / "scroll.asm"
STEER_SHIFT = 1


def shift_steer_offset(value: int, delta: int) -> int:
    if value == 0:
        return 0
    shifted = value + delta
    if shifted < 1 or shifted > 127:
        return 0
    return shifted


def parse_forward_rows(text: str) -> list[tuple[int, str, list[int]]]:
    block = re.search(
        r"scroll_tab_forward\n((?:.*\n)*?)\n; --- left",
        text,
        re.MULTILINE,
    )
    if not block:
        raise SystemExit("scroll_tab_forward block not found")
    rows: list[tuple[int, str, list[int]]] = []
    for line in block.group(1).strip().split("\n"):
        m = re.search(r"!byte (.+?)    ; row (\d+)(.*)$", line)
        if not m:
            continue
        vals = [int(x.strip().replace("$", ""), 16) for x in m.group(1).split(",")]
        suffix = m.group(3).rstrip()
        rows.append((int(m.group(2)), suffix, vals))
    return rows


def fmt_row(vals: list[int], row: int, suffix: str) -> str:
    hexes = ", ".join(f"${b & 0xFF:02x}" for b in vals)
    tail = suffix if suffix.startswith(" ") else f" {suffix}"
    return f"    !byte {hexes}    ; row {row}{tail}"


def main() -> int:
    text = SCROLL_ASM.read_text(encoding="utf-8")
    rows = parse_forward_rows(text)
    if not rows:
        raise SystemExit("no forward rows parsed")

    left_lines = ["; --- left steer — forward - 1 ---", "scroll_tab_left"]
    right_lines = ["; --- right steer — forward + 1 ---", "scroll_tab_right"]

    for row_num, suffix, fwd in rows:
        left = [shift_steer_offset(v, -STEER_SHIFT) for v in fwd]
        right = [shift_steer_offset(v, STEER_SHIFT) for v in fwd]
        left_lines.append(fmt_row(left, row_num, suffix))
        right_lines.append(fmt_row(right, row_num, suffix))

    left_lines.append("")
    right_lines.append("")

    new_block = "\n".join(left_lines + right_lines).rstrip() + "\n"

    updated, n = re.subn(
        r"; --- left steer.*\Z",
        new_block,
        text,
        count=1,
        flags=re.DOTALL,
    )
    if n != 1:
        raise SystemExit("failed to replace left/right block")

    SCROLL_ASM.write_text(updated, encoding="utf-8")
    print(f"Updated {SCROLL_ASM} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
