---
title: Architecture
description: Module layout, single coordinate space and data flow.
---

This page summarizes `ARCHITECTURE.md` (at the repository root, in French), which remains the reference for the contract between modules and their signatures.

## Conventions

- **Swift 6**, strict concurrency mode. Everything that touches AppKit, Accessibility or mouse events is `@MainActor`.
- **No private API** (NF4) and **no third-party dependency** (no external SwiftPM package).
- UI text in French, code identifiers in English.
- No `print`: logging goes through `os.Logger` (subsystem `com.florentamaridon.Fenestra`, one category per module).

## Modules

| Folder | Role |
|---|---|
| `App/` | Entry point, `AppController` (wiring), building displays from `NSScreen`. |
| `Core/` | Pure Swift (Foundation + CoreGraphics), fully testable: geometry, zones, resolvers, snap registry, shared border, matching windows across APIs. |
| `Accessibility/` | `AXWindow` (wrapper around an `AXUIElement`) and `AXWindowFinder`. |
| `Capture/` | `WindowThumbnailer` (window thumbnails with ScreenCaptureKit) and `ScreenRecordingPermission`. |
| `Input/` | `DragMonitor` (global mouse) and `HotkeyManager` (Carbon `RegisterEventHotKey`). |
| `Settings/` | Observable `Settings` model, persisted in `UserDefaults`, and `LaunchAtLogin` (`SMAppService`). |
| `UI/` | Menu bar, welcome window, settings, shortcut recorder, preview and Snap Assist panels. |
| `Controllers/` | `SnapController`, `SharedBorderController`, `ScreenWatcher`, `SnapAssistController`. |

## A single coordinate space

:::caution[Core rule]
All business logic works in the **AX** coordinate space: origin at the top left of the main display, `y` pointing down, in points. It is the space used by `AXUIElement` and `CGEvent`.
:::

`NSScreen` and `NSEvent.mouseLocation` have their origin at the bottom left. The conversion happens **only** in `ScreenGeometry` (`toAX` / `toCocoa`), with `axRect.origin.y = primaryHeight - cocoaRect.maxY`. It is covered by unit tests. Only the preview panels receive Cocoa frames, converted by the caller.

## Data flow

```text
Drag
  DragMonitor (mouse, AX space)
    -> SnapController.mouseDown / mouseDragged / mouseUp
       -> AXWindowFinder.window(at:)       window under the pointer
       -> DragZoneResolver.zone(...)        pointer + display -> Zone?
       -> SnapPreviewPanel.show / hide      translucent preview
       -> (released) place(zone, on: screen)
            Zone.frame -> AXWindow.setFrame -> read back -> SnapRegistry
       -> SnapAssistController              if the zone has a complement

Keyboard
  HotkeyManager (Carbon)
    -> AppController.perform(action)
       -> SnapController.perform(action)
          -> KeyboardSnapResolver.command(...)   action + state + display -> SnapCommand
          -> place(...) | restore(...) | nothing
          -> SnapAssistController            after a place, if the zone has a complement
```

Other flows:

- **Shared border**: if the *size* changes while dragging a snapped window, `SharedBorderController` calls `SharedBorderResolver.adjustments(...)` (a pure function), then applies the new frames.
- **Restoration**: if the *position* changes on a snapped window, the original size (`SnapRecord.restoreFrame`) is applied once and the record is removed.
- **Displays**: `ScreenWatcher` applies the zone of every window in the registry again when the display configuration changes.

## Robustness

Each `AXUIElementCreateApplication` gets a 0.25 s messaging timeout. `setFrame` applies size, position, then size again, and **always reads back** the actual frame: an app that refuses the size blocks nothing.

## Tests

Tests (Swift Testing) mostly cover `Core/`.

```sh
xcodebuild test -scheme Fenestra -destination 'platform=macOS'
```

## Documentation

This site lives in `docs/` (Astro Starlight); see `docs/README.md` for the commands.
