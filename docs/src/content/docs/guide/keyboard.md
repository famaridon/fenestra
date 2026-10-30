---
title: Keyboard shortcuts
description: Actions, default shortcuts and Win + arrow cycling.
---

## Actions

| Action | Default shortcut |
|---|---|
| Left | `⌃⌥←` |
| Right | `⌃⌥→` |
| Up | `⌃⌥↑` |
| Down | `⌃⌥↓` |
| Top-left quarter | `⌃⌥U` |
| Top-right quarter | `⌃⌥I` |
| Bottom-left quarter | `⌃⌥J` |
| Bottom-right quarter | `⌃⌥K` |
| Full screen | `⌃⌥↩` |
| Restore | `⌃⌥⌫` |
| Next display | `⌃⌥⌘→` |
| Previous display | `⌃⌥⌘←` |
| Thirds (⅓, ⅔) | none by default |

:::note
Thirds (left, center, right, left two thirds, right two thirds) exist as actions but have **no default shortcut**: assign your own in the settings. They are not available with the mouse.
:::

## Arrow cycling

As with `Win + arrows`, pressing the same arrow several times moves the window along.

### Single landscape display

Starting from a window that is not snapped:

1. `⌃⌥←`: left half.
2. `⌃⌥↑`: top-left quarter.
3. `⌃⌥↓`: back to the left half.
4. `⌃⌥↓` again: bottom-left quarter.
5. `⌃⌥↑`: left half again.
6. `⌃⌥←`: there is no neighboring display, so the window is **restored** to its original size.

More on a landscape display:

- `⌃⌥↑` on a window that is not snapped: full screen. On a half: the top quarter.
- `⌃⌥↓` on a full-screen window: restore. On a half: the bottom quarter.
- `⌃⌥→` on a left half: right half (and the other way around with `←`).

### Two displays side by side

Display A on the left, display B on the right, a window that is not snapped on A.

1. `⌃⌥→`: right half of A.
2. `⌃⌥→` again: the window moves to B, in the **left half** (mirror zone).
3. `⌃⌥→` again: right half of B. One more press, with no display further right, restores the window.

The other way, `⌃⌥←` on a left half of B sends the window back to A in the right half.

On a vertical display, cycling uses `↑`/`↓`, see [Vertical displays](/fenestra/guide/vertical-display/).

## Other actions

- **Quarters, full screen, thirds**: put the window in that zone on its current display. If it is already there, nothing happens.
- **Restore**: gives the window back its size from before the first snap (no effect if it is not snapped).
- **Next / previous display**: sends the window to the next or previous display. A snapped window keeps its zone; a window that is not snapped is moved proportionally. See [Multiple displays](/fenestra/guide/multiple-displays/).

## Change the shortcuts

Open Fenestra's settings (from the menu bar menu), **Shortcuts** tab: click a shortcut and type the new key combination. A button restores the default shortcuts. See [Settings](/fenestra/guide/settings/).

:::caution
A shortcut already used by the system or another app may fail to register: Fenestra then skips it (and logs it).
:::
