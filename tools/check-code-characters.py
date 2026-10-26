#!/usr/bin/env python3
"""Reject characters that look like PowerShell syntax but are not.

Word processors and chat clients silently replace hyphens with en dashes and
straight quotes with curly ones. The result still looks correct in a browser
but fails the moment someone copies it into a console, which defeats the whole
point of a copy-paste one-liner library.

Only fenced ``powershell`` blocks are checked; prose may use real punctuation.

Usage:
    python3 tools/check-code-characters.py [path ...]

Exits 0 when clean, 1 when any offending character is found.
"""

from __future__ import annotations

import pathlib
import re
import sys

# Character -> (name, what it must be replaced with)
FORBIDDEN = {
    "\u2013": ("en dash", "-"),
    "\u2014": ("em dash", "-"),
    "\u2018": ("left single quote", "'"),
    "\u2019": ("right single quote", "'"),
    "\u201c": ("left double quote", '"'),
    "\u201d": ("right double quote", '"'),
    "\u00a0": ("non-breaking space", "a normal space"),
    "\u200b": ("zero-width space", "nothing (delete it)"),
}

FENCE_OPEN = re.compile(r"^\s*```\s*(powershell|ps1)\s*$", re.IGNORECASE)
FENCE_CLOSE = re.compile(r"^\s*```\s*$")


def check_file(path: pathlib.Path) -> list[str]:
    """Return a problem description for each offending character."""
    problems: list[str] = []
    in_block = False

    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not in_block:
            if FENCE_OPEN.match(line):
                in_block = True
            continue

        if FENCE_CLOSE.match(line):
            in_block = False
            continue

        for char, (name, replacement) in FORBIDDEN.items():
            if char in line:
                column = line.index(char) + 1
                problems.append(
                    f"{path}:{number}:{column} {name} — replace with {replacement}\n"
                    f"       {line.strip()[:100]}"
                )

    return problems


def main(argv: list[str]) -> int:
    roots = [pathlib.Path(arg) for arg in argv[1:]] or [pathlib.Path(".")]

    files: list[pathlib.Path] = []
    for root in roots:
        if root.is_file():
            files.append(root)
        else:
            files.extend(p for p in sorted(root.rglob("*.md")) if ".git" not in p.parts)

    problems: list[str] = []
    for path in files:
        problems.extend(check_file(path))

    if problems:
        for problem in problems:
            print(problem)
        print(f"\n{len(problems)} problem(s) found in {len(files)} file(s).")
        return 1

    print(f"Code characters clean in {len(files)} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
