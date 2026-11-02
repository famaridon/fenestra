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
Thirds (left, center, right, left two thirds, right two thirds) exist as actions but have **no default shortcut**: assign your own in the settings. They are also **turned off** in the **Zones** tab by default: turn them on there, or their shortcuts do nothing. Dragging to an edge never gives a third; the [Snap Layouts](/fenestra/guide/snap-layouts/) palette offers them once they are on.
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
6. `⌃⌥←`: there is no neighboring display, so the window is **restored** (size and position from before the first snap).

More on a landscape display:

- `⌃⌥↑` on a window that is not snapped: full screen. On a half: the top quarter. On a full-screen window or a top quarter, with no display above: nothing.
- `⌃⌥↓` on a window that is not snapped: nothing (unlike Windows, it is not minimized). On a full-screen window: restore (or, with a display below, move there; see below). On a half: the bottom quarter.
- `⌃⌥→` on a left half: right half (and the other way around with `←`).

### Two displays side by side

Display A on the left, display B on the right, a window that is not snapped on A.

1. `⌃⌥→`: right half of A.
2. `⌃⌥→` again: the window moves to B, in the **left half** (mirror zone).
3. `⌃⌥→` again: right half of B. One more press, with no display further right, restores the window.

The other way, `⌃⌥←` on a left half of B sends the window back to A in the right half.

### Two displays stacked

Display A above, display B below (a laptop under a monitor, for example), both landscape. On a vertical display, `↑`/`↓` follow other rules, see [Vertical displays](/fenestra/guide/vertical-display/).

- `⌃⌥↓` on a full-screen window of A: the window moves to B, still full screen. `⌃⌥↑` brings it back.
- `⌃⌥↓` on a bottom quarter of A: the window moves to B, in the matching **top** quarter (mirror zone). `⌃⌥↑` on a top quarter of B does the opposite.

On a vertical display, cycling uses `↑`/`↓`, see [Vertical displays](/fenestra/guide/vertical-display/).

After each snap to a half or a quarter, [Snap Assist](/fenestra/guide/snap-assist/) offers your other windows for the free space.

## Other actions

- **Quarters, full screen, thirds**: put the window in that zone on its current display. If it is already there, nothing happens.
- **Restore**: puts the window back where it was before the first snap, size and position (no effect if it is not snapped).
- **Next / previous display**: sends the window to the next or previous display. A snapped window keeps its zone; a window that is not snapped keeps its relative position and its size (reduced if it does not fit). See [Multiple displays](/fenestra/guide/multiple-displays/).

:::note
A zone turned off in the **Zones** tab of the [settings](/fenestra/guide/settings/) is never used by the keyboard either: when a shortcut would lead to it, nothing happens.
:::

## Change the shortcuts

Open Fenestra's settings (from the menu bar menu), **Shortcuts** tab: click a shortcut and type the new key combination. A button restores the default shortcuts. See [Settings](/fenestra/guide/settings/).

:::caution
A shortcut already used by the system or another app may fail to register: Fenestra then skips it (and logs it).
:::

## Keep the shortcuts of Rectangle, Magnet or AeroSpace

If you come from **Rectangle**, **Magnet** or **AeroSpace**, Fenestra finds their settings on your Mac and offers to reuse their shortcuts: in the welcome window at first launch, and at the bottom of the **Shortcuts** tab of the settings. Click **Import from Rectangle** (or Magnet, or AeroSpace): the shortcuts of the actions that exist in Fenestra replace yours, the others are untouched. Nothing is read from the other app until you click, and it is never modified.

| App | Where it is read | What is imported |
|---|---|---|
| Rectangle | its preferences (`com.knollsoft.Rectangle`) | halves, quarters, full screen, restore, next / previous display, thirds; an action you left without shortcut in Rectangle loses it in Fenestra too; absent entries follow Rectangle's defaults (recommended or Spectacle set) |
| Magnet | its preferences (`com.crowdcafe.windowmagnet`) | halves, quarters, thirds, full screen, restore; absent entries follow Magnet's factory shortcuts; the display shortcuts keep Fenestra's (which are Magnet's too) |
| AeroSpace | `~/.aerospace.toml` or `~/.config/aerospace/aerospace.toml`, table `[mode.main.binding]` | `move left/right/up/down` → the arrow actions, `fullscreen` → full screen, `move-node-to-monitor left/prev/right/next` → previous / next display; key names are read as on a QWERTY layout |

A shortcut taken over by an import is removed from any other action that used it, so each shortcut keeps a single action. Bindings with no equivalent (Rectangle's *Center*, AeroSpace's `focus`, `workspace`…) are counted in the window and listed in the log (Console, subsystem `com.florentamaridon.Fenestra`, category `shortcut-import`). You can import again at any time, or restore the defaults.

:::tip
Quit the other app (or turn off its shortcuts) before using Fenestra's: two apps registering the same global shortcut do not get along.
:::
