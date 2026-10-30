---
title: Écran vertical
description: Haut / bas au lieu de gauche / droite sur un écran en orientation portrait.
---

## Détection

Fenestra détecte l'orientation de **chaque écran** : si sa hauteur est supérieure à sa largeur, il est traité comme vertical. Aucun réglage n'est nécessaire.

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

## Quarts : le découpage dans l'autre sens

Sur un écran paysage, `↑`/`↓` coupent une moitié gauche ou droite en quarts. Sur un écran vertical, c'est l'inverse : `←`/`→` coupent la **moitié haute ou basse** en quarts.

| Raccourci | Depuis | Résultat |
|---|---|---|
| `⌃⌥←` / `⌃⌥→` | Moitié haute | Quart haut gauche / haut droit |
| `⌃⌥←` / `⌃⌥→` | Moitié basse | Quart bas gauche / bas droit |
| `⌃⌥→` / `⌃⌥←` | Quart haut gauche / haut droit | Retour à la moitié haute (idem pour les quarts du bas) |
| `⌃⌥↑` / `⌃⌥↓` | Quart du bas / du haut | Le quart au-dessus / au-dessous, du même côté |

Par exemple : `⌃⌥↑` (moitié haute), puis `⌃⌥←` (quart haut gauche), puis `⌃⌥→` (retour à la moitié haute).

Sur une fenêtre non collée, ou déjà sur une moitié gauche ou droite, `⌃⌥←` et `⌃⌥→` donnent toujours les moitiés gauche et droite et passent à l'écran voisin, comme sur un écran paysage.

Pour retrouver le comportement du paysage (quarts tirés des moitiés gauche et droite avec `↑`/`↓`), désactivez **Écran vertical : au clavier, ← et → coupent les moitiés haute et basse en quarts** dans l'onglet **Zones** des [réglages](/fenestra/fr/guide/settings/).

## Option « bord haut = plein écran »

Par défaut, le bord haut d'un écran vertical donne la **moitié haute**. Si vous préférez le comportement de Windows (plein écran), activez l'option correspondante dans l'onglet **Zones** des [réglages](/fenestra/fr/guide/settings/).

Vous pouvez aussi désactiver les bords gauche et droit sur écran vertical, si vous ne voulez que le découpage haut / bas.
