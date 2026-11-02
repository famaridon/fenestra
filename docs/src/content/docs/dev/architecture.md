---
title: Architecture
description: Features and clean architecture layers, single coordinate space and data flow.
---

This page summarizes `ARCHITECTURE.md` (at the repository root, in French), which remains the reference for the contract between modules and their signatures.

## Conventions

- **Swift 6**, strict concurrency mode. Everything that touches AppKit, Accessibility or mouse events is `@MainActor`, and so are the use cases.
- **No private API** and **no third-party dependency** in the app or the `fenestra` tool. The only exception is the test target, which uses [Harmonize](https://github.com/perrystreetsoftware/Harmonize) to check the architecture.
- UI text written in English in the code and translated in `Localizable.xcstrings` (French); code identifiers in English.
- No `print`: logging goes through `os.Logger` (subsystem `com.florentamaridon.Fenestra`, one category per module).

## Layers

The code is organized **by feature**, then **by layer**: `Sources/Fenestra/<Feature>/<Layer>/`.

| Layer | Contents | May use | Imports |
|---|---|---|---|
| **Domain** | Pure values and rules (structs, enums), tested without mocks | Domain | Foundation, CoreGraphics |
| **Application** | **Use cases** (one type per case, `execute` method) and **ports** (protocols) | Domain, Application | Foundation, CoreGraphics, Observation, os |
| **Infrastructure** | System adapters implementing the ports: Accessibility, Carbon, NSEvent, ScreenCaptureKit, NSWorkspace, socket | Domain, Application, Infrastructure | any |
| **Presentation** | SwiftUI and panels; the panels implement the display ports | Domain, Application, Presentation | any |
| **App** (`App/`) | Composition root: builds the adapters and the use cases and wires them | everything | any |

- Infrastructure and Presentation don't know each other.
- A feature uses only the **Domain** and **Application** of another feature.
- `Kernel` is shared by every feature and depends on none.
- When two features would depend on each other, one declares a port the other implements: Snapping declares `SnapFollowUp` (implemented by Snap Assist) and `SnappedWindowResizeHandler` (implemented by the shared border).

`Tests/FenestraTests/Architecture/ArchitectureTests.swift` checks these rules with Harmonize: where each file sits, the imports of Domain and Application, no class in Domain, and the types each layer uses.

## Features

| Folder | Role |
|---|---|
| `App/` | Entry point, `AppController` (wiring, starts and stops the monitors from the settings). |
| `Kernel/` | Displays and geometry (`ScreenInfo`, `ScreenLayout`, `ScreenGeometry`), `Zone`; ports `WindowHandle`, `WindowSystem`, `DisplayProvider`, `PointerState` and their Accessibility / `NSScreen` adapters. |
| `Snapping/` | Drag, keyboard, restoration, display changes. Use cases `DragSnapSession`, `SnapWithKeyboard`, `SnapWindowToZone`, `PlaceWindowInZone`, `ReapplySnapsAfterDisplayChange`; `SnapStore` holds the snapped windows. |
| `SharedBorder/` | `SharedBorderResolver` (pure) and the `PropagateBorderResize` use case. |
| `SnapAssist/` | `OfferSnapAssist` use case, panel, thumbnails (ScreenCaptureKit), Screen Recording permission. |
| `SnapLayouts/` | `ShowSnapLayouts` use case, green button hover monitor, palette. |
| `ExternalControl/` | `LayoutPlanner` (pure), use cases `ListDisplays`, `ListWindows`, `ApplyLayout`, JSON dispatcher and Unix socket. |
| `Settings/` | Observable `Settings` model persisted in `UserDefaults`, `LaunchAtLogin`, settings views. |
| `Onboarding/`, `MenuBar/` | Accessibility permission and welcome window; menu bar content. |
| `Sources/Shared/` | `ControlSocket`: the socket protocol, compiled into both the app and the tool. |
| `Sources/FenestraCLI/` | The `fenestra` tool, shipped in `Contents/Helpers/`: command line and MCP server over stdio, with no third-party dependency. |

## A single coordinate space

:::caution[Core rule]
All business logic works in the **AX** coordinate space: origin at the top left of the main display, `y` pointing down, in points. It is the space used by `AXUIElement` and `CGEvent`.
:::

`NSScreen` and `NSEvent.mouseLocation` have their origin at the bottom left. The conversion happens **only** in `ScreenGeometry` (`toAX` / `toCocoa`), with `axRect.origin.y = primaryHeight - cocoaRect.maxY`. It is covered by unit tests. Every frame crossing a port is in AX space; the panels convert to Cocoa themselves.

## Data flow

```text
Drag
  DragMonitor (mouse, AX space)
    -> DragSnapSession.mouseDown / mouseDragged / mouseUp
       -> WindowSystem.window(at:)          window under the pointer
       -> DragZoneResolver.zone(...)        pointer + display -> Zone?
       -> SnapPreview.show / hide           translucent preview
       -> (released) PlaceWindowInZone
            Zone.frame -> WindowHandle.setFrame -> read back -> SnapStore
       -> SnapFollowUp.windowSnapped        Snap Assist, if the zone has a complement

Keyboard
  HotkeyManager (Carbon) or menu
    -> AppController.perform(action)
       -> SnapWithKeyboard.execute(action)
          -> KeyboardSnapResolver.command(...)   action + state + display -> SnapCommand
          -> SnapWindowToZone | restore | move to the next display
```

Other flows:

- **Shared border**: if the *size* changes while dragging a snapped window, `DragSnapSession` calls `SnappedWindowResizeHandler`, implemented by `PropagateBorderResize`, which calls `SharedBorderResolver.adjustments(...)` (a pure function) and applies the new frames.
- **Restoration**: if the *position* changes on a snapped window and **Restore original size when unsnapping** is on, the original size (`SnapRecord.restoreFrame`) is applied once and the record is removed.
- **Displays**: `ScreenWatcher` runs `ReapplySnapsAfterDisplayChange` when the display configuration changes.

## Robustness

Each `AXUIElementCreateApplication` gets a 0.25 s messaging timeout. `setFrame` applies size, position, then size again, and **always reads back** the actual frame: an app that refuses the size blocks nothing.

## Tests

Tests (Swift Testing) mirror the features in `Tests/FenestraTests/<Feature>/`. They cover the Domain, and the use cases with fakes of the ports (`Support/Fakes.swift`), with no Accessibility or real display. `Architecture/` holds the layer rules.

```sh
xcodegen generate   # the .xcodeproj is not under version control
xcodebuild test -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' -derivedDataPath build
```

## Documentation

This site lives in `docs/` (Astro Starlight); see `docs/README.md` for the commands.
