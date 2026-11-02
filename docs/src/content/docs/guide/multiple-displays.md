---
title: Multiple displays
description: Independent displays, sending windows to the next or previous display, plugging and unplugging.
---

## Independent displays

Every feature works **on each display independently**: each display has its own zones, computed on its visible area (without the menu bar or the Dock), and its own orientation. You can have a landscape display and a vertical one, each with its own split.

## Move a window to another display

- **With the arrows**: pressing `⌃⌥←` or `⌃⌥→` again on a window already snapped on that side moves it to the neighboring display. With stacked displays, `⌃⌥↓` / `⌃⌥↑` do the same from a full-screen window or a bottom / top quarter of a landscape display. See [Keyboard shortcuts](/fenestra/guide/keyboard/).
- **Next display** `⌃⌥⌘→` / **previous display** `⌃⌥⌘←`: sends the window to the next or previous display. The order is reading order (left to right, then top to bottom) and wraps around.
  - A snapped window keeps its zone on the new display.
  - A window that is not snapped keeps its relative position and its size (reduced if it does not fit).
  - With a single display, nothing happens.
- **With the mouse**: just drag the window to the edge of the display you want. The zone is computed on the display under the pointer. Along every edge shared with another display (side, top or bottom), a 24-point band triggers that edge's zone (half, quarter near a corner, full screen at the top), since the pointer does not stop there. The band covers the whole edge.

## Plugging and unplugging

Plugging or unplugging a display, or changing its resolution, must not leave any window off screen. Fenestra reacts to the change: every window it snapped **gets its zone applied again** on its display, or on the main display (the one with the menu bar) if its display is gone. The zone's standard frame is applied: sizes changed with the [shared border](/fenestra/guide/shared-border/) are lost.

:::note
Only windows snapped by Fenestra are adjusted. The others are left to macOS.
:::
