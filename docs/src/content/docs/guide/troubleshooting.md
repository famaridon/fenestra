---
title: Troubleshooting
description: Frequently asked questions and fixes.
---

## The preview does not appear

Check, in this order:

1. **Accessibility permission**: in System Settings > Privacy & Security > Accessibility, Fenestra must be turned on.
2. **Fenestra is enabled** (switch in the menu) and drag snapping is on in the settings.
3. **Is the app excluded?** See the Exclusions tab.
4. **Non-standard window**: Fenestra ignores panels, palettes and windows that are not standard or not resizable.
5. **Native tiling is on**: macOS tiling can interfere. Turn it off in System Settings > Desktop & Dock > Windows.
6. **Disabled zone**: the zone you are aiming for may be unchecked in the Zones tab.

Reminder: the pointer must touch the edge, and you grab the window by its title bar.

## Snap Assist shows icons instead of thumbnails

1. Check that **Window previews in Snap Assist** is on in the **General** tab of the settings.
2. Check that Fenestra is allowed in **System Settings > Privacy & Security > Screen & System Audio Recording**, then relaunch Fenestra.
3. A window that is hidden, on another desktop (Space) or cannot be captured keeps its app icon: this is expected.

## The permission disappears after a rebuild

The permission is tied to the signature. Make sure the project is signed with an **Apple Development** certificate and not "ad hoc" (see [Installation](/fenestra/guide/installation/)). If the Fenestra entry is already stale, remove it from the Accessibility list, then relaunch the app to grant the permission again.

## An app refuses the requested size

Some apps enforce a minimum size (or size increments). Fenestra **always reads back the actual size** after each resize: the window may slightly overflow its zone, without blocking or crashing Fenestra. An app that does not respond is given up on after a very short delay.

## CPU and memory usage

Fenestra aims for close to 0% CPU when idle and less than 50 MB of memory. If you see more, disable Fenestra from the menu and relaunch it.

## Reset the settings

Quit Fenestra, then run in a terminal:

```sh
defaults delete com.florentamaridon.Fenestra
```

On the next launch, every setting goes back to its default value (and the welcome window shows up again).
