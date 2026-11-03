---
title: Workspaces
description: Save an arrangement of windows under a name and bring it back from the menu, a shortcut or an AI agent.
---

A **workspace** is an arrangement of windows saved under a name: which app goes where, on which display. Bring it back in one go, with the apps launched if they were closed.

## Save a workspace

Arrange your windows, then in the menu bar menu choose **Workspaces > Save Current Arrangement…**. The settings open on the **Workspaces** tab with the new workspace selected: give it a name and, if you like, a shortcut.

What is saved, for every window Fenestra can move (see [the rules](/fenestra/guide/mouse/)):

- the **app** (its bundle identifier, so a renamed app is still found);
- the **display** it is on, by position (first, second… from left to right);
- its **zone** if it is snapped, otherwise its **exact frame**, as fractions of the display;
- its **title**, only when the app has several windows, to tell them apart.

Windows on another Space are not visible to Fenestra: a workspace covers the current Space.

## Bring it back

- **Menu bar**: **Workspaces**, then the workspace.
- **Shortcut**: set one in the **Workspaces** tab of the settings. A shortcut already used by a snap action is left to the snap action.
- **AI agents and scripts**: `apply_workspace` or `fenestra workspace apply <name>`, see [AI agents](/fenestra/guide/ai-agents/#workspaces).

Fenestra opens the apps that have no window and waits for them (up to 10 seconds), places every window, and brings the first one to the front. Windows that are not part of the workspace stay where they are. A placement on a display that is no longer connected goes to the primary display.

## Switch automatically with the displays

Turn on **Apply automatically when these displays are connected** for a workspace: Fenestra remembers the displays connected at that moment (their sizes, whatever their order or ids). Later, as soon as the display setup changes to that one, say when you plug the laptop into the desk, the workspace is applied on its own, without launching any app. One workspace for the desk, one for the laptop alone, and your windows follow.

Nothing happens at launch, after sleep, or while the displays stay the same. When two workspaces match the same displays, the first one in the list wins.

## Update, rename, delete

In the **Workspaces** tab of the [settings](/fenestra/guide/settings/):

- **Update with Current Arrangement** replaces the layout with the windows as they are now, keeping the name and the shortcut;
- the **Name** field renames it (press Return); two workspaces cannot share a name;
- **Apply** tries it right away and tells you which windows could not be placed;
- **−** deletes it.

Workspaces live in `~/Library/Application Support/Fenestra/workspaces.json`, a readable file: you can edit it, version it, or let an agent write it through the `fenestra` tool.
