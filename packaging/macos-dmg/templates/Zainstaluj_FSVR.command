#!/bin/bash
# Instaluje wtyczkę FSVR.component do folderu Audio Units systemu macOS.
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/Library/Audio/Plug-Ins/Components"

echo "== Instalacja FSVR (Audio Unit) =="

if [ ! -d "$DIR/FSVR.component" ]; then
  echo "Nie znaleziono FSVR.component obok tego skryptu!"
  read -p "Naciśnij Enter, aby zamknąć..."
  exit 1
fi

mkdir -p "$DEST"

if [ -d "$DEST/FSVR.component" ]; then
  echo "Znaleziono istniejącą wtyczkę — tworzę kopię zapasową (FSVR.component.bak)"
  rm -rf "$DEST/FSVR.component.bak"
  mv "$DEST/FSVR.component" "$DEST/FSVR.component.bak"
fi

cp -R "$DIR/FSVR.component" "$DEST/"
xattr -dr com.apple.quarantine "$DEST/FSVR.component" 2>/dev/null || true
chmod -R 755 "$DEST/FSVR.component"

echo ""
echo "Gotowe! Wtyczka zainstalowana w:"
echo "  $DEST/FSVR.component"
echo ""
echo "Zrestartuj swój DAW (Logic Pro / GarageBand / Ableton Live) i"
echo "wykonaj ponowne skanowanie wtyczek, jeśli to konieczne."
echo ""
read -p "Naciśnij Enter, aby zamknąć to okno..."
