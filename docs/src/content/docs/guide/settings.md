---
title: Settings
description: Every option in the Settings window, tab by tab.
---

Open the settings from Fenestra's menu in the menu bar. Each option is saved immediately in the user's preferences.

The main **Enable Fenestra** switch is in the menu bar menu.

## General

| Setting | Default | Effect |
|---|---|---|
| Launch at login | off | Starts Fenestra when you log in. |
| Snap windows by dragging them to an edge | on | Turns on snapping with the mouse. Restoration on unsnap and the shared border do not depend on it. |
| Restore original size when unsnapping | on | Gives back the pre-snap size when you unsnap a window. |
| Shared border between snapped windows | on | Links snapped windows, see [Shared border](/fenestra/guide/shared-border/). |
| Snap Layouts when hovering the green button | on | Palette of layouts when the pointer rests on a window's green button, see [Snap Layouts](/fenestra/guide/snap-layouts/). |
| Snap Assist | on | Offers your other windows after a snap, see [Snap Assist](/fenestra/guide/snap-assist/). |
| Window previews in Snap Assist | off | Shows a thumbnail of each window. Greyed out while Snap Assist is off. Needs the Screen & System Audio Recording permission: while it is missing, a note and an **Open System Settings** button show up below. See [Window thumbnails](/fenestra/guide/snap-assist/#window-thumbnails). |
| Gap between windows | 0 pt | Space between windows and with the screen edges. The shared border keeps it. |
| Corner size | 120 pt | Length of edge counted as a corner when dragging. |
| Trigger band between two displays | 24 pt | Width of the area that triggers a snap along an edge shared with another display. Outer edges keep a 2-point threshold. |

## Zones

| Setting | Default | Effect |
|---|---|---|
| Halves, quarters, full screen, thirds | all but thirds | Turns each zone on or off. A disabled zone is never used, with the mouse, the keyboard, Snap Layouts or Snap Assist, and there is no fallback to another one. Scripts and AI agents can still use it. |
| Vertical Display: Top edge goes full screen | off | Otherwise the top edge gives the top half. |
| Vertical Display: Left and right edges active | on | Keeps the left / right halves on a vertical display. |
| Vertical Display: With the keyboard, ← and → cut the top and bottom halves into quarters | on | Otherwise `←`/`→` on a top or bottom half give the left / right half, as on a landscape display. See [Vertical displays](/fenestra/guide/vertical-display/#quarters-the-split-goes-the-other-way). |

## Shortcuts

One row per action with a field to record the shortcut, and a button to **restore the default shortcuts**. See [Keyboard shortcuts](/fenestra/guide/keyboard/).

## Exclusions

List of **excluded apps**: no snapping (mouse, keyboard, border) is applied to their windows. Add or remove apps in this list.

## Agents

| Setting | Default | Effect |
|---|---|---|
| Allow AI agents and scripts to arrange windows | on | Lets the `fenestra` tool, and AI agents through it (MCP), list and arrange your windows. See [AI agents and scripts](/fenestra/guide/ai-agents/). |

Below the switch, the configuration to connect **Claude Code** or another **MCP app** (Claude Desktop, Cursor…), each with a **Copy** button.

## About

Version and build number, and a **Documentation** link to this site (in English or French, following the macOS language). No data is collected and Fenestra does not access the network.
