#!/usr/bin/env bash
# Builds the Windows release into build/windows/ and checks that a real
# Windows executable came out. Needs the export templates: make setup-templates
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/build/windows"
EXE="$OUT_DIR/BeyondTheChindwin.exe"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
"$ROOT/tools/godot.sh" --headless --path "$ROOT/game" \
  --export-release "Windows Desktop" "$EXE"

# Godot can report success without writing a file, so check the result itself.
if [ ! -s "$EXE" ] || [ "$(head -c 2 "$EXE")" != "MZ" ]; then
  echo "error: export did not produce a Windows executable at $EXE" >&2
  exit 1
fi
if [ ! -s "$OUT_DIR/BeyondTheChindwin.pck" ]; then
  echo "error: export did not produce the game data file (.pck)" >&2
  exit 1
fi
echo "exported:"
ls -lh "$OUT_DIR"
