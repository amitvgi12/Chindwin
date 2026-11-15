#!/usr/bin/env python3
"""Fail if anything that needs a licence record is missing from ASSETS.md.

Checked:
  * every file under game/assets/ and marketing/
  * every addon folder directly under game/addons/

A row covers a file when its Path cell equals the file's path, or when the
Path cell ends in "/" and the file sits below that folder.

Usage: python3 tools/check_assets.py     (or: make assets-check)
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEDGER = ROOT / "ASSETS.md"
ASSET_DIRS = [ROOT / "game" / "assets", ROOT / "marketing"]
ADDONS_DIR = ROOT / "game" / "addons"

REQUIRED_COLUMNS = ["Path", "Source", "Author", "Licence", "Placeholder"]
IGNORED_NAMES = {".gitkeep", ".DS_Store"}
IGNORED_SUFFIXES = {".import", ".uid"}  # written by Godot next to the real file


def read_ledger() -> tuple[list[dict[str, str]], list[str]]:
    """Return the table rows of ASSETS.md and any format errors found."""
    rows: list[dict[str, str]] = []
    errors: list[str] = []
    header: list[str] | None = None
    for number, line in enumerate(LEDGER.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if header is None:
            header = cells
            missing = [name for name in REQUIRED_COLUMNS if name not in header]
            if missing:
                errors.append(f"ASSETS.md: table is missing column(s): {', '.join(missing)}")
                return rows, errors
            continue
        if all(set(cell) <= set("-: ") for cell in cells):
            continue  # the |---|---| separator line
        row = dict(zip(header, cells))
        row["Path"] = row.get("Path", "").strip("`")
        for name in REQUIRED_COLUMNS:
            if not row.get(name):
                errors.append(f"ASSETS.md line {number}: '{name}' is empty")
        if row.get("Placeholder", "").lower() not in {"yes", "no"}:
            errors.append(f"ASSETS.md line {number}: Placeholder must be yes or no")
        rows.append(row)
    return rows, errors


def items_needing_a_row() -> list[str]:
    """Repo-relative paths of every asset file and every addon folder."""
    items: list[str] = []
    for assets_dir in ASSET_DIRS:
        if not assets_dir.is_dir():
            continue
        for path in sorted(assets_dir.rglob("*")):
            if not path.is_file():
                continue
            if path.name in IGNORED_NAMES or path.suffix in IGNORED_SUFFIXES:
                continue
            items.append(path.relative_to(ROOT).as_posix())
    if ADDONS_DIR.is_dir():
        for path in sorted(ADDONS_DIR.iterdir()):
            if path.is_dir():
                items.append(path.relative_to(ROOT).as_posix() + "/")
    return items


def is_covered(item: str, ledger_paths: list[str]) -> bool:
    return any(
        item == ledger_path or (ledger_path.endswith("/") and item.startswith(ledger_path))
        for ledger_path in ledger_paths
    )


def main() -> int:
    if not LEDGER.is_file():
        print("error: ASSETS.md not found", file=sys.stderr)
        return 1
    rows, errors = read_ledger()
    ledger_paths = [row["Path"] for row in rows]

    for item in items_needing_a_row():
        if not is_covered(item, ledger_paths):
            errors.append(f"no ASSETS.md row for: {item}")
    for ledger_path in ledger_paths:
        if ledger_path and not (ROOT / ledger_path).exists():
            errors.append(f"ASSETS.md lists a path that does not exist: {ledger_path}")

    if errors:
        print("ASSET LEDGER CHECK FAILED", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"ASSET LEDGER OK: {len(rows)} row(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
