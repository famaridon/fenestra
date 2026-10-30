---
title: Shared border
description: Resize several snapped windows by dragging their common border.
---

Like Windows 11 *snap groups*, windows snapped side by side stay **linked**: dragging the border between them resizes them together.

## How it works

1. Snap two or more windows with Fenestra (for example one on the left and one on the right).
2. Drag the common edge of one of the windows with the mouse.
3. The neighboring windows that shared that edge resize to stay **adjacent**: if one grows, the other shrinks by the same amount.

This works on **vertical** borders (between left and right) and **horizontal** ones (for example between two stacked quarters). With several neighbors along the same edge, they all follow.

## Minimum sizes

App minimum sizes are respected: if a window cannot shrink any further, the border stops, and the window you are dragging is brought back to the limit.

## When the link breaks

The link between windows goes away as soon as one of them is:

- **unsnapped** (dragged out of its zone, which gives it back its original size);
- **moved**;
- **closed**.

## Limitations

- Only windows **snapped by Fenestra** are linked. Two windows placed side by side by hand are not.
- Windows of excluded or non-standard apps are ignored.
- An app that refuses the requested size can leave a small gap: Fenestra always reads back the actual size after each resize.

The feature can be turned off in the **General** tab of the [settings](/fenestra/guide/settings/).
