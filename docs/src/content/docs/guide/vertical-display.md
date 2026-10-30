---
title: Vertical displays
description: Top / bottom instead of left / right on a display in portrait orientation.
---

## Detection

Fenestra detects the orientation of **each display**: if it is taller than it is wide, it is treated as vertical. No setting is needed.

## Top / bottom split

On a vertical display, the main split is **top / bottom**:

- drag to the **top edge**: top half;
- drag to the **bottom edge**: bottom half;
- the **left and right edges** still give the left / right halves (configurable).

On a landscape display, the bottom edge does nothing and the top edge gives full screen.

## Adapted shortcuts

| Action | Window not snapped | Other states |
|---|---|---|
| `⌃⌥↑` | Top half | Top half: full screen. Bottom half: moves up to the display above (otherwise top half). |
| `⌃⌥↓` | Bottom half | Top half: moves down to the display below (otherwise bottom half). Bottom half or full screen: restore. |

`⌃⌥←` and `⌃⌥→` always give the left and right halves, and `↑`/`↓` on those halves give the quarters, as on a landscape display.

## "Top edge = full screen" option

By default, the top edge of a vertical display gives the **top half**. If you prefer the Windows behavior (full screen), turn on the matching option in the **Zones** tab of the [settings](/fenestra/guide/settings/).

You can also turn off the left and right edges on vertical displays if you only want the top / bottom split.
