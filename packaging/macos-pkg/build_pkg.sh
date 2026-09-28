#!/bin/bash
#
# build_pkg.sh — builds a classic macOS Installer.app package (.pkg) for the
# FSVR Audio Unit: a welcome page, a readme naming the original authors and
# where this build came from, the GPL-3 license to accept, and a conclusion
# page — then installs FSVR.component into
# /Library/Audio/Plug-Ins/Components (system-wide, needs an admin password).
#
# Run from the repo root, after building the plugin (README.md, section
# "Building it"):
#
#   ./packaging/macos-pkg/build_pkg.sh
#
# Called automatically by build_dmg.sh if this script is present next to it.
#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"

if [[ "$OSTYPE" != "darwin"* ]]; then
  err "Ten skrypt działa tylko na macOS (potrzebuje pkgbuild/productbuild)."
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
  info "Zbuduj wtyczkę najpierw (README.md, sekcja \"Building it\")."
  exit 1
fi
ok "Znaleziono: $AU_COMPONENT"

if [[ ! -f "$PROJECT_DIR/LICENSE" ]]; then
  err "Nie znaleziono LICENSE — uruchom ten skrypt z korzenia repo."
  exit 1
fi

VERSION="$(grep -oE 'VERSION [0-9]+\.[0-9]+\.[0-9]+' CMakeLists.txt | head -1 | awk '{print $2}')"
VERSION="${VERSION:-0.0.0}"
info "Wersja wykryta: $VERSION"

IDENTIFIER="studio.musica.fsvr.au"
WORKDIR="$(mktemp -d)"
PAYLOAD="$WORKDIR/payload"
RESOURCES="$WORKDIR/resources"
mkdir -p "$PAYLOAD" "$RESOURCES"

info "Przygotowuję zawartość pakietu..."
cp -R "$AU_COMPONENT" "$PAYLOAD/FSVR.component"

for tpl in welcome readme conclusion; do
  sed "s/@VERSION@/$VERSION/g" "$SCRIPT_DIR/resources/${tpl}.html" > "$RESOURCES/${tpl}.html"
done
cp "$PROJECT_DIR/LICENSE" "$RESOURCES/license.txt"

info "Buduję komponent instalacyjny (pkgbuild)..."
COMPONENT_PKG="$WORKDIR/fsvr-au-component.pkg"
pkgbuild --root "$PAYLOAD" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --install-location "/Library/Audio/Plug-Ins/Components" \
  "$COMPONENT_PKG"

info "Składam kreator instalacji (productbuild)..."
DIST_XML="$WORKDIR/distribution.xml"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@IDENTIFIER@/$IDENTIFIER/g" \
  "$SCRIPT_DIR/distribution.xml.in" > "$DIST_XML"

OUT_PKG="$PROJECT_DIR/FSVR-${VERSION}-AU-Installer.pkg"
rm -f "$OUT_PKG"
productbuild --distribution "$DIST_XML" \
  --resources "$RESOURCES" \
  --package-path "$WORKDIR" \
  "$OUT_PKG"

rm -rf "$WORKDIR"

ok "Gotowe!"
echo ""
echo "  $OUT_PKG"
echo ""
info "Dwuklik otwiera zwykły kreator Instalatora macOS: strona powitalna,"
info "informacja o wersji i autorach, licencja GPL-3 do zaakceptowania, i"
info "instalacja do /Library/Audio/Plug-Ins/Components (poprosi o hasło"
info "administratora — instaluje dla wszystkich kont na tym Macu)."
