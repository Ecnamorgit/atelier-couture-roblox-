#!/usr/bin/env bash
# Lance la simulation complète du jeu hors de Roblox Studio (Linux).
# Télécharge au premier lancement : Luau 0.650 et les définitions de l'API Roblox (luau-lsp 1.53.0).
set -euo pipefail
ICI="$(cd "$(dirname "$0")" && pwd)"
CACHE="$ICI/.cache"
mkdir -p "$CACHE/sim"
if [ ! -x "$CACHE/luau" ]; then
  curl -sSL -o "$CACHE/luau.zip" https://github.com/luau-lang/luau/releases/download/0.650/luau-ubuntu.zip
  unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -f "$CACHE/globalTypes.d.luau" ]; then
  curl -sSL -o "$CACHE/globalTypes.d.luau" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.53.0/scripts/globalTypes.d.luau
fi
cp "$ICI/mock.luau" "$ICI/scenario.luau" "$CACHE/sim/"
python3 "$ICI/gen_api.py" "$CACHE" "$ICI/../src"
python3 "$ICI/build.py" "$CACHE" "$ICI/../src"
"$CACHE/luau" "$CACHE/sim/run.luau"
