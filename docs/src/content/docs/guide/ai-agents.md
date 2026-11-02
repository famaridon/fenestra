---
title: AI agents and scripts
description: Let Claude and other AI agents arrange your windows over MCP, or script whole layouts from the terminal.
---

Fenestra ships with a small command-line tool, `fenestra`, that talks to the running app. AI agents use it through the **Model Context Protocol (MCP)**, and you can call it from scripts. Either way, a whole **layout** — several windows, on several displays — is applied in **one go**.

Ask Claude something like *“set me up for coding: Xcode on the left two thirds, Safari on the right, Slack full screen on the top display”* and the windows move.

Everything stays on your Mac: the tool talks to Fenestra through a local socket that only your user account can open.

## Connect an AI agent

Open the **Agents** tab of the [settings](/fenestra/guide/settings/). It shows the configuration for this copy of Fenestra, with a **Copy** button:

- **Claude Code**: copy the command and run it in a terminal. It looks like:

  ```sh
  claude mcp add fenestra -- /Applications/Fenestra.app/Contents/Helpers/fenestra mcp
  ```

- **Claude Desktop, Cursor and other MCP apps**: copy the JSON block into the app's MCP configuration file (for Claude Desktop: *Settings › Developer › Edit Config*):

  ```json
  {
    "mcpServers": {
      "fenestra": {
        "args": ["mcp"],
        "command": "/Applications/Fenestra.app/Contents/Helpers/fenestra"
      }
    }
  }
  ```

The path points to where Fenestra is installed: copy the configuration again if you move the app. If Fenestra is not running, the tool starts it in the background.

## What an agent can do

| Tool | Effect |
|---|---|
| `list_displays` | The displays in reading order (left to right, then top to bottom), with their index, size and orientation. |
| `list_windows` | The windows Fenestra can move, with their app, title, display and zone. |
| `apply_layout` | Places several windows at once, see below. |

Agents follow the same rules as you: minimized, full-screen, fixed-size and [excluded](/fenestra/guide/settings/#exclusions) windows are left alone. Commands fail with a clear error while Fenestra is turned off in the menu bar or does not have the Accessibility permission.

## Describing a layout

A layout is a list of **placements**. Each one picks a window and says where it goes:

| Field | Meaning |
|---|---|
| `app` | App name (`Safari`) or bundle identifier (`com.apple.Safari`), case-insensitive. Required. |
| `title` | Part of the window title, to pick one window of an app with several. |
| `display` | A string: `primary` or `main` (default, the display with the menu bar), an index (`"1"`, `"2"`…, quoted), `left`, `right`, `top`, `bottom`, or `id:` followed by the `id` that `list_displays` returns. |
| `zone` | A named zone: `leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `maximize`, `leftThird`, `centerThird`, `rightThird`, `leftTwoThirds`, `rightTwoThirds`. |
| `rect` | Or a custom area, in fractions of the display's usable area (without the menu bar and the Dock): `{"x": 0, "y": 0, "width": 0.6, "height": 1}` is the left 60 %. |

Give a `zone` or a `rect`, not both. Set `launch_apps` to `true` to open the apps that have no window yet; Fenestra waits up to 10 seconds for their windows.

```json
{
  "placements": [
    { "app": "Xcode", "zone": "leftTwoThirds" },
    { "app": "Safari", "title": "GitHub", "zone": "rightThird" },
    { "app": "Terminal", "display": "2", "rect": { "x": 0, "y": 0.5, "width": 1, "height": 0.5 } },
    { "app": "Slack", "display": "top", "zone": "maximize" }
  ],
  "launch_apps": true
}
```

- Each window is used **once**: list an app twice to place two of its windows (front-most first), or tell them apart with `title`.
- Windows that are not listed **stay where they are**.
- The **first** placement ends up in front.
- Zones and `rect` areas keep the **gap between windows** set in the settings. Zones work with [restore](/fenestra/guide/keyboard/) like any other snap. A window placed with `rect` is not considered snapped.
- The reply lists the windows placed and, for each placement that failed, why (no matching window, unknown display…).

## From the terminal

The same tool works in scripts and shortcuts:

```sh
FENESTRA=/Applications/Fenestra.app/Contents/Helpers/fenestra
$FENESTRA displays
$FENESTRA windows
$FENESTRA layout '{"placements": [{"app": "Xcode", "zone": "leftHalf"}, {"app": "Safari", "zone": "rightHalf"}]}'
$FENESTRA layout - < coding.json
```

Each command prints its result as JSON. When the request fails as a whole (invalid JSON, Fenestra turned off…), it prints `fenestra: <message>` on stderr and exits with status 1. A layout where only some placements fail still exits with 0: check the `failed` list in the result.

## Turning it off

Turn off **Allow AI agents and scripts to arrange windows** in the **Agents** tab of the [settings](/fenestra/guide/settings/): Fenestra closes its socket and the tool can no longer reach it. The tool then tries to launch Fenestra for 10 seconds and gives up with "Fenestra is not running and could not be started", even though the app is running.
