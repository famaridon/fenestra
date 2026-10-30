---
title: Snap Assist
description: After snapping a window, pick another one to fill the remaining space, as on Windows 11.
---

As on Windows 11, when you snap a window to one half of the screen, with the mouse or the keyboard, Fenestra offers to **fill the remaining space** with another window. Two clicks are enough to put two windows side by side.

## How it works

1. Snap a window: drag it to an edge or a corner (see [Snapping with the mouse](/fenestra/guide/mouse/)), or use a shortcut such as `⌃⌥←` (see [Keyboard shortcuts](/fenestra/guide/keyboard/)).
2. The free space shows the list of your other open windows, with their app icon and title.
3. **Click** a window: it fills the free space and comes to the front.

**Escape**, a click anywhere else or another shortcut closes the list without doing anything. When you cycle with the arrows, the list follows the window and offers the space left by its new zone.

## Which space is offered

| Zone you snapped to | Space offered |
|---|---|
| Left / right half | The other half |
| Top / bottom half (vertical display) | The other half |
| Top quarter | The bottom quarter on the same side |
| Bottom quarter | The top quarter on the same side |

Full screen and thirds have no free space to fill, so Snap Assist does not show up.

The window you pick is snapped like any other: it stays **linked** to its neighbor by the [shared border](/fenestra/guide/shared-border/), and gets its original size back when you unsnap it.

## Which windows are listed

- The visible standard windows of every app (minimized windows are not listed).
- Except the window you just snapped, windows already snapped on that display, and windows of [excluded apps](/fenestra/guide/settings/#exclusions).

If no window is left, the list does not show up.

The list does not show up either when another snapped window already fills the free space.

## Limitations

- You pick a window with the mouse: the list cannot be browsed with the keyboard yet.

## Turn it off

Snap Assist can be turned off in the **General** tab of the [settings](/fenestra/guide/settings/).
