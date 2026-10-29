---
title: Bordure partagée
description: Redimensionner plusieurs fenêtres collées en tirant leur bordure commune.
---

Comme les *snap groups* de Windows 11, des fenêtres collées côte à côte restent **liées** : tirer la bordure qui les sépare les redimensionne ensemble.

## Fonctionnement

1. Collez deux fenêtres ou plus avec Panes (par exemple une à gauche et une à droite).
2. Tirez le bord commun d'une des fenêtres avec la souris.
3. Les fenêtres voisines qui partageaient ce bord se redimensionnent pour rester **jointives** : si l'une s'agrandit, l'autre rétrécit d'autant.

Cela marche sur les bordures **verticales** (entre gauche et droite) et **horizontales** (par exemple entre deux quarts empilés). Avec plusieurs voisines le long du même bord, toutes suivent.

## Tailles minimales

Les tailles minimales des applications sont respectées : si une fenêtre ne peut pas rétrécir davantage, la bordure s'arrête, et la fenêtre que vous tirez est ramenée à la limite.

## Quand le lien se rompt

Le lien entre fenêtres disparaît dès que l'une d'elles est :

- **décollée** (glissée hors de sa zone, qui lui rend sa taille d'origine) ;
- **déplacée** ;
- **fermée**.

## Limites

- Seules les fenêtres **collées par Panes** sont liées. Deux fenêtres placées à la main côte à côte ne le sont pas.
- Les fenêtres des applications exclues ou non standard sont ignorées.
- Une application qui refuse la taille demandée peut laisser un petit écart : Panes relit toujours la taille réelle après chaque redimensionnement.

La fonction se désactive dans l'onglet **Général** des [réglages](/guide/reglages/).
