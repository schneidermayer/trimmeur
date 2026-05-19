<div align="center">
  <img src="docs/assets/trimmeur-icon.svg" width="140" height="140" alt="Trimmeur scissor icon" />
  <h1>Trimmeur</h1>
  <p>A tiny macOS menu-bar agent for pasting clipboard text without indentation.</p>
</div>

The default global shortcut for **Paste Trimmed** is `Option-Command-T`. You can change it in `Preferences...` from the menu-bar icon. The app reads the current text clipboard, removes leading spaces and tabs from every line, temporarily places the trimmed text on the pasteboard, sends `Command-V`, and then restores the original pasteboard contents.

`Preferences...` also includes a `Start on login` toggle.

## Permissions

Trimmeur needs macOS **Accessibility** permission to send the paste keystroke to the currently active app.

On first use, macOS will prompt for the permission. You can also open the prompt from the menu-bar icon: `Request Accessibility Permission...`.

## Development

Run tests:

```bash
./scripts/test.sh
```

Build a local debug app:

```bash
./scripts/build.sh debug
open "dist/debug/Trimmeur.app"
```

The build script always runs the test suite before building.

Debug builds start at `1.0` and always include the number of commits since the latest `v*` tag. For example, 15 commits after `v1.0` builds as `1.0-15`.

The app menu displays the bundle version in the quit item, for example `Quit Trimmeur 1.0` in production and `Quit Trimmeur 1.0-15` in debug builds.

## Production Build

Production builds use the Release configuration, build universal binaries by default, Developer ID sign the app, notarize it, staple the app, and produce a zip archive.

One-time notary profile setup:

```bash
xcrun notarytool store-credentials "emoji-picker-macos-notary" --apple-id "birthy@gmx.at" --team-id "AW7ZNT442J"
```

Apple Developer Program agreements for the signing team must be current; `scripts/build.sh prod` validates notary access before building.

Run a signed and notarized production build:

```bash
VERSION=1.0 ./scripts/build.sh prod
```

Useful overrides:

- `BUNDLE_ID=com.example.trimmeur`
- `TEAM_ID=...`
- `CODESIGN_IDENTITY="Developer ID Application: ..."`
- `NOTARY_PROFILE=...`
- `BUILD_ARCHS="arm64 x86_64"`

Artifacts:

- Debug app: `dist/debug/Trimmeur.app`
- Production app: `dist/prod/Trimmeur.app`
- Production zip: `dist/prod/trimmeur-<version>.zip`

## GitHub Release

Every release must create a matching git tag. Use the release script so the tag, production build, and GitHub release asset stay in sync:

```bash
scripts/release_github.sh 1.0
```

The script requires a clean worktree, builds `dist/prod/trimmeur-1.0.zip`, creates and pushes `v1.0`, and uploads the zip to GitHub Releases as the precompiled macOS app.

## Project Layout

- `Sources/TrimmeurCore`: testable text trimming logic
- `Sources/TrimmeurMacOS`: AppKit menu-bar agent, hotkey registration, paste behavior
- `Tests/TrimmeurCoreTests`: unit tests
- `scripts/test.sh`: test runner
- `scripts/build.sh`: debug/prod app build, signing, notarization
- `scripts/generate_icon.sh`: scissor app icon generation
