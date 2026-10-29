---
title: Écran vertical
description: Haut / bas au lieu de gauche / droite sur un écran en orientation portrait.
---

## Détection

Panes détecte l'orientation de **chaque écran** : si sa hauteur est supérieure à sa largeur, il est traité comme vertical. Aucun réglage n'est nécessaire.

## Découpage haut / bas

Sur un écran vertical, le découpage principal est **haut / bas** :

- glisser vers le **bord haut** : moitié haute ;
- glisser vers le **bord bas** : moitié basse ;
- les **bords gauche et droit** restent disponibles pour les moitiés gauche / droite (réglable).

Sur un écran paysage, le bord bas ne fait rien et le bord haut donne le plein écran.

## Raccourcis adaptés

| Action | Fenêtre non collée | Autre état |
|---|---|---|
| `⌃⌥↑` | Moitié haute | Moitié haute : plein écran. Moitié basse : monte sur l'écran voisin du dessus (sinon moitié haute). |
| `⌃⌥↓` | Moitié basse | Moitié haute : descend sur l'écran voisin du dessous (sinon moitié basse). Moitié basse ou plein écran : restauration. |

`⌃⌥←` et `⌃⌥→` donnent toujours les moitiés gauche et droite, et `↑`/`↓` sur ces moitiés donnent les quarts, comme sur un écran paysage.

## Option « bord haut = plein écran »

Par défaut, le bord haut d'un écran vertical donne la **moitié haute**. Si vous préférez le comportement de Windows (plein écran), activez l'option correspondante dans l'onglet **Zones** des [réglages](/guide/reglages/).

Vous pouvez aussi désactiver les bords gauche et droit sur écran vertical, si vous ne voulez que le découpage haut / bas.
