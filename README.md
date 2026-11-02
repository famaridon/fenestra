<p align="center">
  <img src="docs/src/assets/logo.svg" alt="" width="128" height="128">
</p>

<h1 align="center">Fenestra</h1>

<p align="center">Windows and Ubuntu-style window snapping for macOS, from the menu bar — and an MCP server built in, so AI agents can arrange your windows.<br>
<a href="https://famaridon.github.io/fenestra/">Documentation</a> · <a href="README.fr.md">Français</a></p>

## Built for AI agents

Fenestra ships with an **MCP server**. Connect Claude (or any MCP app) in one copy-paste from the settings, then just ask:

> *“Set me up for coding: Xcode on the left two thirds, Safari on the right, Slack full screen on the other display.”*

The agent lists your windows and displays, then places **every window in a single call**: named zones or custom proportions, any display, missing apps launched for you. The same commands work from the terminal for your own scripts. Everything stays on your Mac. See the [AI agents guide](https://famaridon.github.io/fenestra/guide/ai-agents/).

## Features

- AI agents and scripts: Claude and other MCP apps (or a shell script) arrange several windows in one call through the bundled `fenestra` tool.
- Drag snapping: screen edges and corners, translucent preview, original size restored when you unsnap.
- Configurable global keyboard shortcuts (halves, quarters, thirds, full screen, restore, move to another display); coming from Rectangle, Magnet or AeroSpace, import their shortcuts in one click.
- Shared border: resizing a snapped window adjusts its neighbors.
- Snap Layouts: rest the pointer on a window's green button and pick a zone in a palette of layouts, as on Windows 11.
- Snap Assist: after a snap with the mouse or the keyboard, offers your other windows for the remaining space, with optional window thumbnails.
- Multiple and vertical displays, zones applied again automatically when the display setup changes.
- Excluded apps, gaps between windows, launch at login.

The app is available in English and French, following the macOS language.

The architecture and module contracts are in [ARCHITECTURE.md](ARCHITECTURE.md) (in French).

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

The home page video is made with [Remotion](https://www.remotion.dev) in `video/`: one component per scene in `src/scenes/`, texts per language in `src/i18n.ts`, scene order and transitions in `src/timeline.ts`.

```sh
cd video && pnpm install
pnpm studio     # live preview
pnpm render     # out/fenestra-intro-{en,fr}.mp4 and .jpg posters
```

The `Release` workflow renders it and attaches it to the release; the documentation links to the video of the latest release.

## Release

Push a `vX.Y.Z` tag (or `vX.Y.Z-beta.1` for a pre-release): the `Release` workflow runs the tests, builds an unsigned arm64 app and publishes `Fenestra.zip`, its `.sha256` checksum and the intro video on GitHub Releases. Check `git tag` for the current version first.

```sh
git tag v1.2.0 && git push origin v1.2.0
```
