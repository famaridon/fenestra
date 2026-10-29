---
title: Dépannage
description: Questions fréquentes et solutions.
---

## L'aperçu n'apparaît pas

Vérifiez dans l'ordre :

1. **Autorisation d'Accessibilité** : Réglages Système > Confidentialité et sécurité > Accessibilité, Panes doit être activé.
2. **Panes est activé** (interrupteur du menu) et le snap par glisser est actif dans les réglages.
3. **L'application est-elle exclue ?** Voir l'onglet Exclusions.
4. **Fenêtre non standard** : Panes ignore les panneaux, palettes et fenêtres qui ne sont pas des fenêtres standard ou ne sont pas redimensionnables.
5. **Snap natif activé** : le collage de macOS peut interférer. Désactivez-le dans Réglages Système > Bureau et Dock > Fenêtres.
6. **Zone désactivée** : la zone visée est peut-être décochée dans l'onglet Zones.

Rappel : le pointeur doit toucher le bord, et on saisit la fenêtre par sa barre de titre.

## L'autorisation disparaît après une recompilation

L'autorisation est liée à la signature. Vérifiez que le projet est signé avec un certificat **Apple Development** et non « ad hoc » (voir [Installation](/guide/installation/)). Si l'entrée Panes est déjà périmée, supprimez-la de la liste Accessibilité puis relancez l'app pour la ré-autoriser.

## Une application refuse la taille demandée

Certaines applications imposent une taille minimale (ou des incréments). Panes **relit toujours la taille réelle** après chaque redimensionnement : la fenêtre peut donc déborder légèrement de sa zone, sans bloquer ni faire planter Panes. Une application qui ne répond pas est abandonnée après un très court délai.

## Consommation CPU et mémoire

Panes vise un CPU proche de 0 % au repos et moins de 50 Mo de mémoire. Si vous constatez davantage, désactivez Panes via le menu et relancez-le.

## Réinitialiser les réglages

Quittez Panes puis lancez dans un terminal :

```sh
defaults delete com.florentamaridon.Panes
```

Au prochain lancement, tous les réglages reviennent à leurs valeurs par défaut (et l'accueil réapparaît).
