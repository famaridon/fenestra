---
title: Multi-écrans
description: Écrans indépendants, envoi vers l'écran suivant ou précédent, branchement et débranchement.
---

## Écrans indépendants

Toutes les fonctions marchent **sur chaque écran indépendamment** : chaque écran a ses propres zones, calculées sur sa zone visible (sans barre des menus ni Dock), et sa propre orientation. Vous pouvez avoir un écran paysage et un écran vertical, chacun avec son découpage.

## Changer une fenêtre d'écran

- **Avec les flèches** : appuyer de nouveau sur `⌃⌥←` ou `⌃⌥→` sur une fenêtre déjà collée de ce côté la fait passer à l'écran voisin, voir [Raccourcis clavier](/guide/clavier/).
- **Écran suivant** `⌃⌥⌘→` / **écran précédent** `⌃⌥⌘←` : envoie la fenêtre sur l'écran suivant ou précédent. L'ordre est celui de lecture (de gauche à droite, puis de haut en bas) et boucle.
  - Une fenêtre collée garde sa zone sur le nouvel écran.
  - Une fenêtre non collée est déplacée proportionnellement.
  - Avec un seul écran, il ne se passe rien.
- **À la souris** : glissez simplement la fenêtre vers le bord de l'écran voulu. La zone est calculée sur l'écran qui contient le pointeur.

## Branchement et débranchement

Brancher ou débrancher un écran, ou changer sa résolution, ne doit laisser aucune fenêtre hors de l'écran. Panes réagit au changement : chaque fenêtre qu'il a collée **voit sa zone réappliquée** sur son écran, ou sur l'écran principal si son écran a disparu.

:::note
Seules les fenêtres collées par Panes sont réajustées. Les autres restent gérées par macOS.
:::
