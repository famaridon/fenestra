---
title: Multi-écrans
description: Écrans indépendants, envoi vers l'écran suivant ou précédent, branchement et débranchement.
---

## Écrans indépendants

Toutes les fonctions marchent **sur chaque écran indépendamment** : chaque écran a ses propres zones, calculées sur sa zone visible (sans barre des menus ni Dock), et sa propre orientation. Vous pouvez avoir un écran paysage et un écran vertical, chacun avec son découpage.

## Changer une fenêtre d'écran

- **Avec les flèches** : appuyer de nouveau sur `⌃⌥←` ou `⌃⌥→` sur une fenêtre déjà collée de ce côté la fait passer à l'écran voisin. Avec des écrans superposés, `⌃⌥↓` / `⌃⌥↑` font de même depuis une fenêtre plein écran ou un quart du bas / du haut d'un écran paysage. Voir [Raccourcis clavier](/fenestra/fr/guide/keyboard/).
- **Écran suivant** `⌃⌥⌘→` / **écran précédent** `⌃⌥⌘←` : envoie la fenêtre sur l'écran suivant ou précédent. L'ordre est celui de lecture (de gauche à droite, puis de haut en bas) et boucle.
  - Une fenêtre collée garde sa zone sur le nouvel écran.
  - Une fenêtre non collée garde sa position relative et sa taille (réduite si elle ne tient pas).
  - Avec un seul écran, il ne se passe rien.
- **À la souris** : glissez simplement la fenêtre vers le bord de l'écran voulu. La zone est calculée sur l'écran qui contient le pointeur. Le long de chaque bord partagé avec un autre écran (côté, haut ou bas), une bande de 24 points déclenche la zone de ce bord (moitié, quart près d'un coin, plein écran en haut), puisque le pointeur ne s'y arrête pas. La bande couvre tout le bord.

## Branchement et débranchement

Brancher ou débrancher un écran, ou changer sa résolution, ne doit laisser aucune fenêtre hors de l'écran. Fenestra réagit au changement : chaque fenêtre qu'il a collée **voit sa zone réappliquée** sur son écran, ou sur l'écran principal (celui de la barre des menus) si son écran a disparu. C'est le cadre standard de la zone qui est appliqué : les tailles modifiées avec la [bordure partagée](/fenestra/fr/guide/shared-border/) sont perdues.

:::note
Seules les fenêtres collées par Fenestra sont réajustées. Les autres restent gérées par macOS.
:::
