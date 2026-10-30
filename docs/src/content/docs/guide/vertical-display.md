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

## Quarters: the split goes the other way

On a landscape display, `↑`/`↓` cut a left or right half into quarters. On a vertical display, it is the other way around: `←`/`→` cut the **top or bottom half** into quarters.

| Shortcut | From | Result |
|---|---|---|
| `⌃⌥←` / `⌃⌥→` | Top half | Top-left / top-right quarter |
| `⌃⌥←` / `⌃⌥→` | Bottom half | Bottom-left / bottom-right quarter |
| `⌃⌥→` / `⌃⌥←` | Top-left / top-right quarter | Back to the top half (same for the bottom quarters) |
| `⌃⌥↑` / `⌃⌥↓` | Bottom / top quarter | The quarter above / below, on the same side |

For example: `⌃⌥↑` (top half), then `⌃⌥←` (top-left quarter), then `⌃⌥→` (back to the top half).

On a window that is not snapped, or already on a left or right half, `⌃⌥←` and `⌃⌥→` still give the left and right halves and move to the neighboring display, as on a landscape display.

To get the landscape behavior back (quarters cut from the left and right halves with `↑`/`↓`), turn off **With the keyboard, ← and → cut the top and bottom halves into quarters** in the **Vertical Display** section of the **Zones** tab of the [settings](/fenestra/guide/settings/).

## "Top edge = full screen" option

By default, the top edge of a vertical display gives the **top half**. If you prefer the Windows behavior (full screen), turn on the matching option in the **Zones** tab of the [settings](/fenestra/guide/settings/).

You can also turn off the left and right edges on vertical displays if you only want the top / bottom split.
