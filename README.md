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
- Snap Assist: after a snap with the mouse or the keyboard, offers your other windows for the remaining space, with optional window thumbnails.
- Multiple and vertical displays, zones applied again automatically when the display setup changes.
- Excluded apps, gaps between windows, launch at login.

The app's interface is currently in French only; an English version is planned.

The full requirements are in [BESOIN.md](BESOIN.md), and the architecture and module contracts in [ARCHITECTURE.md](ARCHITECTURE.md) (both in French).

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
