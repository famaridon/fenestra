---
title: Snapping with the mouse
description: Drag a window to an edge, size restoration, composed layouts and Snap Assist.
---

## Drag to an edge

Grab a window by its title bar and move the **pointer to the edge** of the screen.

| Where the pointer touches | Zone |
|---|---|
| Left / right edge | Left / right half |
| Corner | Quarter of the screen |
| Top edge (landscape display) | Full screen |
| Top / bottom edge (vertical display) | Top / bottom half, see [Vertical displays](/fenestra/guide/vertical-display/) |

- A **translucent preview** of the zone appears **immediately**, with no delay and no modifier key.
- **Releasing** the window applies the zone.
- **Moving away from the edge** cancels the preview: releasing then does nothing more.

On an **outer edge**, the pointer has to actually touch the edge (within about 2 points). It stops there on its own, so precision is not an issue. At the **junction between two displays**, the pointer moves from one display to the other without stopping, so Fenestra uses a wider band there (24 points by default, adjustable in Settings > General). A corner is the part of an edge close to an angle (120 points by default, adjustable).

## Size restoration

When you "unsnap" a snapped window by dragging it out of its zone, it **gets back the size it had before the snap**, as on Windows. The pointer stays at the same relative position in the title bar.

This can be turned off in the [settings](/fenestra/guide/settings/).

## Compose a layout

Combine zones to get, for example, **two windows on the left and one on the right**:

1. Drag window A to the top-left corner (top-left quarter).
2. Drag window B to the bottom-left corner (bottom-left quarter).
3. Drag window C to the right edge (right half).

This also works with the [keyboard](/fenestra/guide/keyboard/), and you can mix both methods.

## Snap Assist

After snapping a window to a half (or a quarter) by dragging, Fenestra shows the list of your other open windows (icon and title) in the remaining space.

- **Click** a window: it fills the remaining space.
- **Escape** (or a click elsewhere) closes the list.

Snap Assist can be turned off in the [settings](/fenestra/guide/settings/).
