---
title: Multiple displays
description: Independent displays, sending windows to the next or previous display, plugging and unplugging.
---

## Independent displays

Every feature works **on each display independently**: each display has its own zones, computed on its visible area (without the menu bar or the Dock), and its own orientation. You can have a landscape display and a vertical one, each with its own split.

## Move a window to another display

- **With the arrows**: pressing `⌃⌥←` or `⌃⌥→` again on a window already snapped on that side moves it to the neighboring display, see [Keyboard shortcuts](/fenestra/guide/keyboard/).
- **Next display** `⌃⌥⌘→` / **previous display** `⌃⌥⌘←`: sends the window to the next or previous display. The order is reading order (left to right, then top to bottom) and wraps around.
  - A snapped window keeps its zone on the new display.
  - A window that is not snapped is moved proportionally.
  - With a single display, nothing happens.
- **With the mouse**: just drag the window to the edge of the display you want. The zone is computed on the display under the pointer. Along the junction between two displays, a 24-point band on each side triggers the matching half, since the pointer does not stop there.

## Plugging and unplugging

Plugging or unplugging a display, or changing its resolution, must not leave any window off screen. Fenestra reacts to the change: every window it snapped **gets its zone applied again** on its display, or on the main display if its display is gone.

:::note
Only windows snapped by Fenestra are adjusted. The others are left to macOS.
:::
