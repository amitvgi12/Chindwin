#!/usr/bin/env bash
# Runs the pinned Godot binary with whatever arguments it is given.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=godot.lock
. "$ROOT/tools/godot.lock"

case "$(uname -s)" in
  Darwin) bin="$ROOT/.tools/godot/Godot.app/Contents/MacOS/Godot" ;;
  *)      bin="$ROOT/.tools/godot/Godot_v${GODOT_VERSION}_linux.x86_64" ;;
esac

if [ ! -x "$bin" ]; then
  echo "error: Godot ${GODOT_VERSION} is not installed here. Run: make setup" >&2
  exit 1
fi
exec "$bin" "$@"
