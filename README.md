<p align="center">
  <img src="docs/src/assets/logo.svg" alt="" width="128" height="128">
</p>

<h1 align="center">Fenestra</h1>

<p align="center">Windows and Ubuntu-style window snapping for macOS, from the menu bar.<br>
<a href="https://famaridon.github.io/fenestra/">Documentation</a> · <a href="README.fr.md">Français</a></p>

## Features

- Drag snapping: screen edges and corners, translucent preview, original size restored when you unsnap.
- Configurable global keyboard shortcuts (halves, quarters, thirds, full screen, restore, move to another display).
- Shared border: resizing a snapped window adjusts its neighbors.
- Snap Layouts: rest the pointer on a window's green button and pick a zone in a palette of layouts, as on Windows 11.
- Snap Assist: after a snap with the mouse or the keyboard, offers your other windows for the remaining space, with optional window thumbnails.
- Multiple and vertical displays, zones applied again automatically when the display setup changes.
- Excluded apps, gaps between windows, launch at login.

The app is available in English and French, following the macOS language.

The full requirements are in [BESOIN.md](BESOIN.md), and the architecture and module contracts in [ARCHITECTURE.md](ARCHITECTURE.md) (both in French).

## Install

**[Download Fenestra](https://github.com/famaridon/fenestra/releases/latest/download/Fenestra.zip)** (latest version; all versions on the [releases page](https://github.com/famaridon/fenestra/releases)). Builds are not signed yet: see the [installation guide](https://famaridon.github.io/fenestra/guide/installation/#download-a-release) to open the app.

## Build and run

```sh
brew install xcodegen   # if needed
xcodegen generate
open Fenestra.xcodeproj    # then Cmd+R
```

From the command line:

```sh
xcodebuild -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' build
```

On first launch, allow Fenestra in **System Settings > Privacy & Security > Accessibility**.

## Tests

```sh
xcodebuild -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' test
```

## Documentation

```sh
cd docs && pnpm install && pnpm dev
```

The site is in English (root) and French (`src/content/docs/fr/`).

### Intro video

The home page video is made with [Remotion](https://www.remotion.dev) in `video/`: one component per scene in `src/scenes/`, texts per language in `src/i18n.ts`, scene order in `src/Root.tsx`.

```sh
cd video && pnpm install
pnpm studio     # live preview
pnpm render     # out/fenestra-intro-{en,fr}.mp4 and .jpg posters
```

The `Release` workflow renders it and attaches it to the release; the documentation links to the video of the latest release.

## Release

Push a `vX.Y.Z` tag (or `vX.Y.Z-beta.1` for a pre-release): the `Release` workflow runs the tests, builds an unsigned arm64 app and publishes `Fenestra.zip` and the intro video on GitHub Releases.

```sh
git tag v0.1.0 && git push origin v0.1.0
```
