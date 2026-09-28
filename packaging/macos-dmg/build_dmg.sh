#!/bin/bash
#
# build_dmg.sh — pakuje zbudowaną wtyczkę FSVR AU w instalator .dmg,
# razem z pełnym kodem źródłowym (GPL-3), licencją i informacją o autorach.
#
# Buduj wtyczkę AU najpierw (README.md, sekcja "Building it"), potem
# uruchom ten skrypt z korzenia repo:
#
#   ./packaging/macos-dmg/build_dmg.sh
#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"

if [[ "$OSTYPE" != "darwin"* ]]; then
  err "Ten skrypt działa tylko na macOS (potrzebuje hdiutil)."
  exit 1
fi

info "Szukam zbudowanej wtyczki AU..."

AU_COMPONENT=""
for candidate in "bin/AU/FSVR.component" "build/bin/AU/FSVR.component"; do
  if [[ -d "$PROJECT_DIR/$candidate" ]]; then
    AU_COMPONENT="$PROJECT_DIR/$candidate"
    break
  fi
done

if [[ -z "$AU_COMPONENT" ]]; then
  err "Nie znaleziono FSVR.component (szukano w bin/AU/ i build/bin/AU/)."
  info "Uruchom najpierw build_au_macos.sh w tym folderze, a potem spróbuj ponownie."
  exit 1
fi
ok "Znaleziono: $AU_COMPONENT"

if [[ ! -f "$PROJECT_DIR/LICENSE" ]]; then
  err "Nie znaleziono LICENSE w bieżącym folderze — uruchom ten skrypt z"
  echo "  folderu głównego źródeł FSVR (tam gdzie jest CMakeLists.txt, LICENSE, NOTICE.md)."
  exit 1
fi

VERSION="$(grep -oE 'VERSION [0-9]+\.[0-9]+\.[0-9]+' CMakeLists.txt | head -1 | awk '{print $2}')"
VERSION="${VERSION:-0.0.0}"
VOL_NAME="FSVR ${VERSION} AU Installer"
DMG_NAME="FSVR-${VERSION}-AU-macOS.dmg"

info "Wersja wykryta: $VERSION"

STAGING="$(mktemp -d)/dmg-staging"
mkdir -p "$STAGING"

info "Kopiuję wtyczkę AU..."
cp -R "$AU_COMPONENT" "$STAGING/FSVR.component"

info "Kopiuję dokumentację i licencję..."
cp "$PROJECT_DIR/LICENSE" "$STAGING/LICENSE.txt"
cp "$PROJECT_DIR/NOTICE.md" "$STAGING/NOTICE.md"
[[ -f "$PROJECT_DIR/README.md" ]] && cp "$PROJECT_DIR/README.md" "$STAGING/README.md"

# AUTHORS.md i PRZECZYTAJ.txt i skrypt instalujący — z folderu templates/
# obok tego skryptu (dostarczone w pakiecie FSVR-DMG-Kit)
TEMPLATES_DIR=""
for candidate in "$SCRIPT_DIR/templates" "$PROJECT_DIR/templates"; do
  if [[ -d "$candidate" ]]; then TEMPLATES_DIR="$candidate"; break; fi
done

if [[ -z "$TEMPLATES_DIR" ]]; then
  err "Nie znaleziono folderu templates/ (AUTHORS.md, PRZECZYTAJ.txt, skrypt instalujący)."
  echo "  Upewnij się, że skopiowałeś cały folder FSVR-DMG-Kit, nie tylko build_dmg.sh."
  exit 1
fi

cp "$TEMPLATES_DIR/AUTHORS.md" "$STAGING/AUTHORS.md"
cp "$TEMPLATES_DIR/PRZECZYTAJ.txt" "$STAGING/PRZECZYTAJ.txt"
cp "$TEMPLATES_DIR/Zainstaluj_FSVR.command" "$STAGING/Zainstaluj FSVR.command"
chmod +x "$STAGING/Zainstaluj FSVR.command"

info "Pakuję pełny kod źródłowy (wymóg licencji GPL-3)..."
SRC_ZIP="$STAGING/FSVR-${VERSION}-source-code.zip"
( cd "$PROJECT_DIR" && \
  zip -rq "$SRC_ZIP" . \
    -x "build/*" -x "bin/*" -x ".git/*" -x "extern/JUCE/*" \
    -x "extern/clap-juce-extensions/*" -x "*.dmg" )
ok "Kod źródłowy spakowany (bez extern/JUCE — dostępne osobno na"
echo "   https://github.com/juce-framework/JUCE, submoduł w .gitmodules)"

info "Buduję obraz DMG..."
rm -f "$PROJECT_DIR/$DMG_NAME"
hdiutil create -volname "$VOL_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$PROJECT_DIR/$DMG_NAME"

rm -rf "$(dirname "$STAGING")"

ok "Gotowe!"
echo ""
echo "  $PROJECT_DIR/$DMG_NAME"
echo ""
info "Zawartość DMG:"
echo "  • FSVR.component            — wtyczka Audio Units"
echo "  • Zainstaluj FSVR.command   — instalator jednym kliknięciem"
echo "  • PRZECZYTAJ.txt            — instrukcja"
echo "  • AUTHORS.md                — autorzy i pochodzenie kodu"
echo "  • LICENSE.txt                — GNU GPL v3"
echo "  • NOTICE.md                  — szczegóły licencji i danych Yamahy"
echo "  • README.md                  — opis projektu"
echo "  • FSVR-${VERSION}-source-code.zip — pełny kod źródłowy"
