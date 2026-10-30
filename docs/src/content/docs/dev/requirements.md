---
title: Requirements
description: Summary of BESOIN.md, priorities, out of scope and working assumptions.
---

This page summarizes `BESOIN.md` (at the repository root, in French, status: draft v0.1), which is authoritative.

**Goal**: bring the window management experience of Windows 11 and Ubuntu to macOS, instant with the mouse and the keyboard, suited to multi-display setups that include a vertical display. Target: macOS 26+, Apple silicon, Swift 6.

## Functional requirements

Priorities: **P0** required for the MVP, **P1** expected in v1, **P2** later.

| # | Requirement | Priority |
|---|---|---|
| F1 | Snap by drag and drop, instant preview | P0 |
| F2 | Restore the original size | P0 |
| F3 | `Win + arrow`-style shortcuts | P0 |
| F4 | Composed layouts | P0 |
| F5 | Shared border between snapped windows | P1 |
| F6 | Vertical display support | P0 |
| F7 | Multiple displays | P0 |
| F8 | Snap Assist | P2 |
| F9 | Menu bar app and settings | P0 |

## Non-functional requirements

| # | Requirement |
|---|---|
| NF1 | Responsiveness: preview in under 50 ms; shared border without visible stutter. |
| NF2 | Frugality: close to 0% CPU when idle, under 50 MB of memory. |
| NF3 | Robustness: an app that does not respond or refuses the size does not block Fenestra; the actual size is read back. |
| NF4 | Public APIs only, no need to disable SIP. |
| NF5 | Coexists with native tiling, with a recommendation to turn it off. |
| NF6 | Privacy: no data collected, no network access. |

## Out of scope

- Automatic tiling of every window (snapping stays manual).
- Managing macOS desktops (Spaces): there is no public API.
- Per-window Alt+Tab: covered by AltTab.
- App Store distribution: impossible, the app cannot be sandboxed with Accessibility.

## Open questions and working assumptions

| Question | Working assumption |
|---|---|
| Vertical display: top edge = top half or full screen? | **Top half** by default, with an option to maximize. |
| Thirds of the screen (⅓ / ⅔)? | Planned, **keyboard only**, with no default shortcut. |
| Shared border for windows placed by hand? | **Only** windows snapped by Fenestra. |
| Default gap between windows? | **0**, as on Windows. |

## Milestones

M0 skeleton, M1 zone engine and keyboard, M2 drag snapping and restoration, M3 shared border, M4 settings and exclusions, M5 Snap Assist.
