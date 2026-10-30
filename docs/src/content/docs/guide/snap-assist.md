---
title: Snap Assist
description: After snapping a window, pick another one to fill the remaining space, as on Windows 11.
---

As on Windows 11, when you snap a window to one half of the screen, Fenestra offers to **fill the remaining space** with another window. Two clicks are enough to put two windows side by side.

## How it works

1. Drag a window to an edge or a corner (see [Snapping with the mouse](/fenestra/guide/mouse/)).
2. When you release it, the free space shows the list of your other open windows, with their app icon and title.
3. **Click** a window: it fills the free space and comes to the front.

**Escape**, or a click anywhere else, closes the list without doing anything.

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

## Limitations

- Snap Assist only shows up after a **drag** snap, not after a keyboard shortcut.

## Turn it off

Snap Assist can be turned off in the **General** tab of the [settings](/fenestra/guide/settings/).
