#!/bin/bash
#
# build_dmg.sh — pakuje zbudowaną wtyczkę FSVR AU w instalator .dmg,
# razem z pełnym kodem źródłowym (GPL-3), licencją i informacją o autorach.
#
# Buduj wtyczkę AU najpierw (README.md, sekcja "Building it"), potem
# uruchom ten skrypt z korzenia repo:
#
#   ./packaging/macos-dmg/build_dmg.sh                    bez podpisu
#   ./packaging/macos-dmg/build_dmg.sh --sign             podpis Developer ID
#   ./packaging/macos-dmg/build_dmg.sh --sign --notarize  podpis + notaryzacja
#
# --sign znajduje w pęku kluczy "Developer ID Application" (wtyczka, DMG)
# i "Developer ID Installer" (.pkg); nadpiszesz je zmiennymi FSVR_SIGN_APP
# i FSVR_SIGN_INSTALLER. --notarize używa profilu notarytool zapisanego raz:
#
#   xcrun notarytool store-credentials "FSVR-notary" --apple-id <e-mail> --team-id <TEAMID>
#
# (inna nazwa profilu: zmienna FSVR_NOTARY_PROFILE).
#
set -e

DO_SIGN=0; DO_NOTARIZE=0
for arg in "$@"; do
  case "$arg" in
    --sign) DO_SIGN=1 ;;
    --notarize) DO_SIGN=1; DO_NOTARIZE=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Nieznana opcja: $arg (dozwolone: --sign, --notarize)"; exit 1 ;;
  esac
done

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
# Fallback: any single .component in bin/AU, in case the product name changes.
if [[ -z "$AU_COMPONENT" ]]; then
  AU_COMPONENT="$(ls -d "$PROJECT_DIR"/bin/AU/*.component 2>/dev/null | head -1)"
fi

if [[ -z "$AU_COMPONENT" ]]; then
  err "Nie znaleziono FSVR.component (szukano w bin/AU/ i build/bin/AU/)."
  info "Zbuduj najpierw wtyczkę (README.md, sekcja \"Building it\"), a potem spróbuj ponownie."
  exit 1
fi
ok "Znaleziono: $AU_COMPONENT"

if [[ ! -f "$PROJECT_DIR/LICENSE" ]]; then
  err "Nie znaleziono LICENSE w bieżącym folderze — uruchom ten skrypt z"
  echo "  folderu głównego źródeł FSVR (tam gdzie jest CMakeLists.txt, LICENSE, NOTICE.md)."
  exit 1
fi

find_identity() {
  security find-identity -v 2>/dev/null | grep "\"$1:" | head -1 | sed -E 's/^[^"]*"(.*)"$/\1/'
}
notarize() {  # $1 = file to submit and staple
  info "Wysyłam $(basename "$1") do notaryzacji Apple (zwykle 1–5 minut)..."
  local out
  out="$(xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)" || true
  echo "$out"
  if ! grep -q "status: Accepted" <<<"$out"; then
    err "Apple nie przyjęło $(basename "$1"). Szczegóły: xcrun notarytool log <id z góry> --keychain-profile \"$NOTARY_PROFILE\""
    exit 1
  fi
  xcrun stapler staple "$1"
  ok "$(basename "$1") znotaryzowany i ostemplowany."
}

if [[ $DO_SIGN == 1 ]]; then
  APP_ID="${FSVR_SIGN_APP:-$(find_identity "Developer ID Application")}"
  INST_ID="${FSVR_SIGN_INSTALLER:-$(find_identity "Developer ID Installer")}"
  if [[ -z "$APP_ID" || -z "$INST_ID" ]]; then
    err "Brak certyfikatu Developer ID Application lub Developer ID Installer w pęku kluczy."
    echo "  Sprawdź: security find-identity -v"
    exit 1
  fi
  info "Podpis wtyczki i DMG: $APP_ID"
  info "Podpis .pkg:          $INST_ID"
  export FSVR_SIGN_INSTALLER="$INST_ID"
  if [[ $DO_NOTARIZE == 1 ]]; then
    NOTARY_PROFILE="${FSVR_NOTARY_PROFILE:-FSVR-notary}"
    export FSVR_NOTARY_PROFILE="$NOTARY_PROFILE"
    info "Profil notaryzacji:   $NOTARY_PROFILE"
  else
    unset FSVR_NOTARY_PROFILE
  fi
else
  unset FSVR_SIGN_INSTALLER FSVR_NOTARY_PROFILE
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

if [[ $DO_SIGN == 1 ]]; then
  # The copy in staging is signed, so bin/ keeps the build as it came out of
  # the compiler. Nested code first, then the bundle; hardened runtime and a
  # secure timestamp are what notarization requires.
  info "Podpisuję wtyczkę (hardened runtime + znacznik czasu Apple)..."
  while IFS= read -r -d '' nested; do
    codesign --force --options runtime --timestamp --sign "$APP_ID" "$nested"
  done < <(find "$STAGING/FSVR.component/Contents" -depth \
             \( -name "*.dylib" -o -name "*.framework" -o -name "*.bundle" -o -name "*.appex" \) -print0)
  codesign --force --options runtime --timestamp --sign "$APP_ID" "$STAGING/FSVR.component"
  codesign --verify --strict --verbose=2 "$STAGING/FSVR.component"
  ok "Wtyczka podpisana."
fi

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

# Classic Installer.app package — welcome/readme/license/conclusion pages,
# built alongside the .command script rather than instead of it, in case
# someone would rather not grant an admin password for a system-wide install.
PKG_BUILDER="$SCRIPT_DIR/../macos-pkg/build_pkg.sh"
if [[ -x "$PKG_BUILDER" ]]; then
  info "Buduję też klasyczny instalator .pkg (kreator z autorami i licencją)..."
  ( cd "$PROJECT_DIR" && "$PKG_BUILDER" "$STAGING/FSVR.component" )
  PKG_FILE="$(ls "$PROJECT_DIR"/FSVR-*-AU-Installer.pkg 2>/dev/null | head -1)"
  if [[ -n "$PKG_FILE" ]]; then
    cp "$PKG_FILE" "$STAGING/"
    rm -f "$PKG_FILE"
    ok "Instalator .pkg dodany do obrazu DMG."
  else
    warn "build_pkg.sh nie zwrócił pliku .pkg — DMG pójdzie bez niego."
  fi
else
  warn "packaging/macos-pkg/build_pkg.sh nie znaleziony — pomijam .pkg."
fi

info "Pakuję pełny kod źródłowy (wymóg licencji GPL-3)..."
SRC_ZIP="$STAGING/FSVR-${VERSION}-source-code.zip"
( cd "$PROJECT_DIR" && \
  zip -rq "$SRC_ZIP" . \
    -x "build/*" -x "bin/*" -x ".git/*" -x "*.dmg" -x "*.pkg" -x ".DS_Store" -x "*/.DS_Store" )
ok "Kod źródłowy spakowany (bez build/ i bin/). Zależności (CLAP SDK, clap-wrapper,"
echo "   Apple AudioUnitSDK, dr_libs, stb) pobiera sam CMake przy pierwszej konfiguracji."

info "Buduję obraz DMG..."
rm -f "$PROJECT_DIR/$DMG_NAME"
hdiutil create -volname "$VOL_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$PROJECT_DIR/$DMG_NAME"

rm -rf "$(dirname "$STAGING")"

if [[ $DO_SIGN == 1 ]]; then
  info "Podpisuję DMG..."
  codesign --force --timestamp --sign "$APP_ID" "$PROJECT_DIR/$DMG_NAME"
  codesign --verify --verbose=2 "$PROJECT_DIR/$DMG_NAME"
fi
if [[ $DO_NOTARIZE == 1 ]]; then
  notarize "$PROJECT_DIR/$DMG_NAME"
  info "Ocena Gatekeepera:"
  spctl --assess --type open --context context:primary-signature -v "$PROJECT_DIR/$DMG_NAME" || true
fi

ok "Gotowe!"
echo ""
echo "  $PROJECT_DIR/$DMG_NAME"
echo ""
info "Zawartość DMG:"
echo "  • FSVR-${VERSION}-AU-Installer.pkg — klasyczny instalator (Kreator Instalacji)"
echo "  • FSVR.component            — wtyczka Audio Units"
echo "  • Zainstaluj FSVR.command   — instalator jednym kliknięciem (bez hasła admina)"
echo "  • PRZECZYTAJ.txt            — instrukcja"
echo "  • AUTHORS.md                — autorzy i pochodzenie kodu"
echo "  • LICENSE.txt                — GNU GPL v3"
echo "  • NOTICE.md                  — szczegóły licencji i danych Yamahy"
echo "  • README.md                  — opis projektu"
echo "  • FSVR-${VERSION}-source-code.zip — pełny kod źródłowy"
