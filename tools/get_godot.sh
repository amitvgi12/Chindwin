#!/usr/bin/env bash
# Downloads the pinned Godot editor into .tools/ and verifies its checksum.
#
#   tools/get_godot.sh              editor only (about 170 MB on macOS)
#   tools/get_godot.sh --templates  also the Windows export templates (1.3 GB download)
#
# The editor stays inside this repository. The export templates go to the folder
# Godot itself reads them from, which is outside the repository:
#   macOS  ~/Library/Application Support/Godot/export_templates/<version>/
#   Linux  ~/.local/share/godot/export_templates/<version>/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=godot.lock
. "$ROOT/tools/godot.lock"

BASE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"
CACHE="$ROOT/.tools/cache"
DEST="$ROOT/.tools/godot"
mkdir -p "$CACHE" "$DEST"

sha512() {
  if command -v sha512sum >/dev/null 2>&1; then
    sha512sum "$1" | cut -d' ' -f1
  else
    shasum -a 512 "$1" | cut -d' ' -f1
  fi
}

# fetch <file name> <expected sha512>: download into the cache unless already there.
fetch() {
  local name="$1" want="$2" path="$CACHE/$1"
  if [ -f "$path" ] && [ "$(sha512 "$path")" = "$want" ]; then
    echo "cached:      $name"
    return
  fi
  echo "downloading: $name"
  curl -fsSL --http1.1 --retry 5 --retry-all-errors --retry-delay 3 \
    -o "$path.part" "$BASE_URL/$name"
  if [ "$(sha512 "$path.part")" != "$want" ]; then
    rm -f "$path.part"
    echo "error: checksum mismatch for $name" >&2
    exit 1
  fi
  mv "$path.part" "$path"
}

case "$(uname -s)" in
  Darwin)
    editor_zip="Godot_v${GODOT_VERSION}_macos.universal.zip"
    editor_sha="$SHA512_MACOS"
    editor_bin="$DEST/Godot.app/Contents/MacOS/Godot"
    templates_root="$HOME/Library/Application Support/Godot/export_templates"
    ;;
  Linux)
    if [ "$(uname -m)" != "x86_64" ]; then
      echo "error: only x86_64 Linux is pinned in tools/godot.lock" >&2
      exit 1
    fi
    editor_zip="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
    editor_sha="$SHA512_LINUX"
    editor_bin="$DEST/Godot_v${GODOT_VERSION}_linux.x86_64"
    templates_root="$HOME/.local/share/godot/export_templates"
    ;;
  *)
    echo "error: unsupported operating system $(uname -s)" >&2
    exit 1
    ;;
esac

if [ -x "$editor_bin" ] && [ "$(cat "$DEST/VERSION" 2>/dev/null)" = "$GODOT_VERSION" ]; then
  echo "editor:      $GODOT_VERSION already installed"
else
  fetch "$editor_zip" "$editor_sha"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  unzip -q -o "$CACHE/$editor_zip" -d "$DEST"
  echo "$GODOT_VERSION" > "$DEST/VERSION"
  echo "editor:      installed $("$editor_bin" --headless --version)"
fi

if [ "${1:-}" = "--templates" ]; then
  # Godot names the folder 4.7.2.stable where the release tag is 4.7.2-stable.
  templates_dir="$templates_root/${GODOT_VERSION/-/.}"
  if [ -f "$templates_dir/windows_release_x86_64.exe" ]; then
    echo "templates:   Windows templates already installed"
  else
    templates_tpz="Godot_v${GODOT_VERSION}_export_templates.tpz"
    fetch "$templates_tpz" "$SHA512_TEMPLATES"
    mkdir -p "$templates_dir"
    # The archive holds every platform. Only the Windows x86_64 files are needed.
    unzip -q -o -j "$CACHE/$templates_tpz" \
      'templates/windows_*_x86_64*' 'templates/version.txt' -d "$templates_dir"
    echo "templates:   installed to $templates_dir"
  fi
fi
