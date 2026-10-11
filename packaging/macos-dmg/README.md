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
  minus `build/`, `bin/` and `.git/`. From 0.5.0 on the plug-in no longer
  uses JUCE or submodules: the first CMake configure downloads the CLAP SDK,
  clap-wrapper, Apple's AudioUnitSDK and the audio decoders (see
  `NOTICE.md`), so the zip needs nothing else beyond network access once

The zipped source is there because a `.dmg` is a binary distribution, and
GPL-3 conditions that on the corresponding source being available with it,
not just linked from a README.

## Signing and notarization

```bash
./packaging/macos-dmg/build_dmg.sh --sign             # Developer ID signatures
./packaging/macos-dmg/build_dmg.sh --sign --notarize  # plus Apple notarization
```

`--sign` finds the "Developer ID Application" (plug-in, DMG) and "Developer
ID Installer" (`.pkg`) identities in the keychain; `FSVR_SIGN_APP` and
`FSVR_SIGN_INSTALLER` override them. The component is signed in the staging
copy with the hardened runtime and a secure timestamp, so `bin/` keeps the
compiler's output. `--notarize` submits the `.pkg` and then the DMG to Apple
with `notarytool` and staples both; it reads a keychain profile, `FSVR-notary`
unless `FSVR_NOTARY_PROFILE` says otherwise, stored once with:

```bash
xcrun notarytool store-credentials "FSVR-notary" --apple-id <e-mail> --team-id <TEAMID>
```

Without either flag the output is unsigned, as before: Gatekeeper warns on any
Mac but the one that built it, and `PRZECZYTAJ.txt` covers the workaround.
