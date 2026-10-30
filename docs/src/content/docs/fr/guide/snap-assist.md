---
title: Snap Assist
description: Après un snap, choisir une autre fenêtre pour remplir l'espace libre, comme sous Windows 11.
---

Comme sous Windows 11, quand vous collez une fenêtre sur une moitié de l'écran, à la souris ou au clavier, Fenestra propose de **remplir l'espace libre** avec une autre fenêtre. Deux clics suffisent pour mettre deux fenêtres côte à côte.

## Fonctionnement

1. Collez une fenêtre : glissez-la vers un bord ou un coin (voir [Snap à la souris](/fenestra/fr/guide/mouse/)), ou utilisez un raccourci comme `⌃⌥←` (voir [Raccourcis clavier](/fenestra/fr/guide/keyboard/)).
2. L'espace libre affiche la liste de vos autres fenêtres ouvertes, avec l'icône de l'application et le titre.
3. **Cliquez** une fenêtre : elle remplit l'espace libre et passe au premier plan.

**Échap**, un clic ailleurs ou un autre raccourci ferme la liste sans rien faire. Quand vous enchaînez les flèches, la liste suit la fenêtre et propose l'espace laissé par sa nouvelle zone.

## Quel espace est proposé

| Zone choisie | Espace proposé |
|---|---|
| Moitié gauche / droite | L'autre moitié |
| Moitié haute / basse (écran vertical) | L'autre moitié |
| Quart du haut | Le quart du bas du même côté |
| Quart du bas | Le quart du haut du même côté |

Le plein écran et les tiers ne laissent pas d'espace à remplir : Snap Assist ne s'affiche pas.

La fenêtre choisie est collée comme les autres : elle reste **liée** à sa voisine par la [bordure partagée](/fenestra/fr/guide/shared-border/) et retrouve sa taille d'origine quand on la décolle.

## Quelles fenêtres sont proposées

- Les fenêtres standard visibles de toutes les applications (les fenêtres réduites ne sont pas listées).
- Sauf la fenêtre que vous venez de coller, les fenêtres déjà collées sur cet écran et celles des [applications exclues](/fenestra/fr/guide/settings/#exclusions).

S'il ne reste aucune fenêtre, la liste ne s'affiche pas.

Elle ne s'affiche pas non plus si une autre fenêtre collée occupe déjà l'espace libre.

## Limites

- On choisit la fenêtre à la souris : la liste ne se parcourt pas encore au clavier.

## Le désactiver

Snap Assist se désactive dans l'onglet **Général** des [réglages](/fenestra/fr/guide/settings/).
