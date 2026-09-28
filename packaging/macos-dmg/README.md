# macOS DMG packaging

Packages a built AU plugin (`bin/AU/FSVR.component`) into a distributable
`.dmg`, with the full GPL-3 source tree, `LICENSE`, `NOTICE.md` and author
attribution bundled alongside a one-click installer script. Not part of the
CMake build; a standalone step for anyone who wants a shareable installer
rather than the raw `.component`.

## Use

Build the AU plugin first (see the repo `README.md`'s "Building it"), then
from the repo root:

```bash
./packaging/macos-dmg/build_dmg.sh
```

It looks for `bin/AU/FSVR.component` (or `build/bin/AU/FSVR.component`),
reads the version out of `CMakeLists.txt`, and writes
`FSVR-<version>-AU-macOS.dmg` in the repo root.

## What goes in the DMG

- `FSVR-<version>-AU-Installer.pkg` — a classic Installer.app package built
  by `packaging/macos-pkg/build_pkg.sh` (see that folder's own notes): a
  welcome page, a readme naming the original authors and where the build
  came from, the GPL-3 license to accept, and a conclusion page, installing
  system-wide to `/Library/Audio/Plug-Ins/Components` (asks for an admin
  password). Built automatically as part of this script if
  `packaging/macos-pkg/build_pkg.sh` is present; skipped with a warning
  otherwise.
- `FSVR.component` — the plugin, unpackaged
- `Zainstaluj FSVR.command` — installer script, copies to
  `~/Library/Audio/Plug-Ins/Components/` (per-user, no admin password)
- `PRZECZYTAJ.txt` — install instructions (Polish), covers both
- `AUTHORS.md` — jameshansen and rgwan, and a link to the upstream repo
- `LICENSE.txt`, `NOTICE.md`, `README.md` — as in the repo root
- `FSVR-<version>-source-code.zip` — the full source tree at build time,
  minus `build/`, `bin/`, `.git/` and the JUCE and clap-juce-extensions
  submodules (those keep their own licences and are fetched separately per
  `.gitmodules`)

The zipped source is there because a `.dmg` is a binary distribution, and
GPL-3 conditions that on the corresponding source being available with it,
not just linked from a README.

## Signing

`hdiutil` produces an unsigned image. On any Mac other than the one that
built it, Gatekeeper will warn on first launch of the installer script;
`PRZECZYTAJ.txt` covers the right-click-Open workaround. Signing and
notarizing needs an Apple Developer ID and `codesign`/`notarytool`, not set
up here.
