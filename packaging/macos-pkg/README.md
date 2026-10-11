# macOS Installer.app package

Builds a classic `.pkg` installer for the AU plugin using `pkgbuild` and
`productbuild`: a welcome page, a readme naming the original authors and
where the build came from, the GPL-3 license to accept, and a conclusion
page, then a system-wide install to `/Library/Audio/Plug-Ins/Components`
(asks for an admin password).

## Use

Build the AU plugin first (repo `README.md`, "Building it"), then from the
repo root:

```bash
./packaging/macos-pkg/build_pkg.sh
```

Writes `FSVR-<version>-AU-Installer.pkg` in the repo root. Called
automatically by `packaging/macos-dmg/build_dmg.sh` if this script is
present, so it normally doesn't need running by hand — it's here mainly so
the `.pkg` can be rebuilt or inspected on its own.

## Files

- `build_pkg.sh` — the script
- `distribution.xml.in` — the installer's page/choice layout, with
  `@VERSION@`/`@IDENTIFIER@` filled in at build time
- `resources/welcome.html`, `resources/readme.html`,
  `resources/conclusion.html` — the wizard pages; `@VERSION@` filled in at
  build time. `resources/license.txt` isn't checked in — the script copies
  the repo's own `LICENSE` there on every build, so the license page can
  never drift from the actual license file.

## Signing

`build_pkg.sh [path/to/FSVR.component]` signs the package when
`FSVR_SIGN_INSTALLER` names a "Developer ID Installer" identity, and notarizes
and staples it when `FSVR_NOTARY_PROFILE` names a `notarytool` keychain profile.
`build_dmg.sh --sign/--notarize` sets both and passes it the signed component;
see `packaging/macos-dmg/README.md`.
