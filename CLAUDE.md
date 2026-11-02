# Fenestra

macOS menu bar app that snaps windows like Windows and Ubuntu: drag to edges, keyboard shortcuts, Snap Layouts on the green button, Snap Assist, shared border, multiple and vertical displays, and a `fenestra` CLI / MCP server for scripts and AI agents. Swift 6, macOS 26+, Apple silicon only, no third-party dependency (only the tests use Harmonize).

## Where things are

- `ARCHITECTURE.md` (French): module layout and the contract between modules. **Authoritative**: keep it in sync when you add a type, a setting, a file or a command.
- `Sources/Fenestra/<Feature>/<Layer>/`: clean architecture, by feature (`Kernel` shared, `Snapping`, `SharedBorder`, `SnapAssist`, `SnapLayouts`, `ExternalControl`, `Settings`, `Onboarding`, `MenuBar`), then by layer:
  - `Domain/`: pure values and rules (structs, enums), Foundation + CoreGraphics only;
  - `Application/`: use cases (one `@MainActor final class` per case, `execute`) and ports (protocols); no AppKit;
  - `Infrastructure/`: adapters implementing the ports (Accessibility, Carbon, NSEvent, ScreenCaptureKit, socket);
  - `Presentation/`: SwiftUI and panels (panels implement display ports; views get their dependencies at `init`).
  `App/` is the composition root (`AppController` builds and wires everything). A feature uses only the Domain and Application of another one; Infrastructure and Presentation never see each other. The rules are enforced by `Tests/FenestraTests/Architecture/ArchitectureTests.swift` (Harmonize): a new file must sit in a `<Feature>/<Layer>/` folder.
- `Tests/FenestraTests/<Feature>/`: Swift Testing, Domain tests and use case tests with fakes of the ports (`Support/Fakes.swift`, `SnappingHarness`).
- `Sources/FenestraCLI/`: the `fenestra` tool (CLI and `fenestra mcp` stdio server), embedded in the app at `Contents/Helpers/fenestra`. `Sources/Shared/`: code compiled into both targets.
- `docs/`: Astro Starlight site, English at the root, French in `src/content/docs/fr/`, published to https://famaridon.github.io/fenestra/.
- `video/`: Remotion intro video (scenes in `src/scenes/`, order and transitions in `src/timeline.ts`, on-screen text in `src/i18n.ts`).

## Non-goals

Snapping stays manual, as on Windows: no automatic tiling of every window. No Spaces management (no public API), no per-window Alt+Tab (AltTab covers it), no App Store build (Accessibility can't be sandboxed).

## Commands

```sh
xcodegen generate        # after any change to project.yml or added/removed files; .xcodeproj is not versioned
xcodebuild test -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' -derivedDataPath build
cd docs && pnpm dev       # http://localhost:4321/fenestra/
cd docs && pnpm build
cd video && pnpm studio   # or pnpm render → out/fenestra-intro-{en,fr}.mp4 + .jpg posters
```

UI behavior (panels, hover, drag) can only be checked by running the app from Xcode (⌘R).

## Code conventions

- Swift 6 strict concurrency; anything touching AppKit, Accessibility or mouse events is `@MainActor`.
- One coordinate space in the logic: AX (origin top-left of the primary display, y down). Convert to/from Cocoa only through `ScreenGeometry`; ports carry AX frames, panels convert.
- Public APIs only (no private API, no SIP to disable), no SwiftPM dependency in the app or the CLI (Harmonize, pinned in `project.yml`, is test-only), `os.Logger` (subsystem `com.florentamaridon.Fenestra`), never `print`.
- UI strings are written in English in code and translated to French in `Sources/Fenestra/Localizable.xcstrings`. Every new string needs its French entry; after a build, the keys in `build/**/*.stringsdata` must match the catalog exactly (no missing, no unused).
- Settings: one property in `Settings/Application/Settings.swift` (persisted in `didSet`, default in `init`; also in `SnapSettings` if a use case reads it), a control in `SettingsView`, a line in `ARCHITECTURE.md` and a row in the docs settings tables (both languages).
- Accessibility quirk: the green button reports the subrole `AXFullScreenButton` on recent macOS, not only `AXZoomButton`.

## A user-facing change is not done until

- the docs page exists or is updated **in English and French** (same slug in both; internal links start with `/fenestra/` and `/fenestra/fr/`), plus `docs/astro.config.mjs` sidebar for a new page;
- `README.md` and `README.fr.md` mention it if it is a feature;
- `ARCHITECTURE.md` reflects it;
- the video gets a scene if it is a headline feature (texts in both languages in `video/src/i18n.ts`).

## Git and releases

- Conventional commits in English (`feat:`, `fix:`, `docs:`, `ci:`, `feat(video):`).
- Release: push a `vX.Y.Z` tag (`vX.Y.Z-suffix` for a pre-release). `.github/workflows/release.yml` tests, builds an unsigned arm64 app (version from the tag), renders the video and publishes `Fenestra.zip`, its `.sha256` and the videos. The docs link to `releases/latest/download/…`, so the site's download button and video follow the latest release. Check `git tag` for the current version before proposing the next one.
- Docs deploy on every push to `docs/**` (`.github/workflows/docs.yml`). pnpm is pinned (`packageManager`) because recent pnpm refuses packages younger than 24 h in CI.
