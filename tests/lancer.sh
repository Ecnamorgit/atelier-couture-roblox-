#!/usr/bin/env bash
# Lance la simulation complète du jeu hors de Roblox Studio (Linux, macOS, ou Windows via Git Bash).
# Télécharge au premier lancement : Luau 0.650 et les définitions de l'API Roblox (luau-lsp 1.53.0).
set -euo pipefail
ICI="$(cd "$(dirname "$0")" && pwd)"
CACHE="$ICI/.cache"
mkdir -p "$CACHE/sim"
case "$(uname -s)" in
  Linux*) PAQUET=luau-ubuntu.zip; LUAU="$CACHE/luau" ;;
  Darwin*) PAQUET=luau-macos.zip; LUAU="$CACHE/luau" ;;
  MINGW*|MSYS*|CYGWIN*) PAQUET=luau-windows.zip; LUAU="$CACHE/luau.exe" ;;
  *) echo "Système non pris en charge : $(uname -s)" >&2; exit 1 ;;
esac
PYTHON="$(command -v python3 || command -v python)"
if [ ! -f "$LUAU" ]; then
  curl -sSL -o "$CACHE/luau.zip" "https://github.com/luau-lang/luau/releases/download/0.650/$PAQUET"
  unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -f "$CACHE/globalTypes.d.luau" ]; then
  curl -sSL -o "$CACHE/globalTypes.d.luau" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.53.0/scripts/globalTypes.d.luau
fi
cp "$ICI/mock.luau" "$ICI/scenario.luau" "$CACHE/sim/"
"$PYTHON" "$ICI/gen_api.py" "$CACHE" "$ICI/../src"
"$PYTHON" "$ICI/build.py" "$CACHE" "$ICI/../src"
"$LUAU" "$CACHE/sim/run.luau"
