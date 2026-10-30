---
title: Expression de besoin
description: Résumé de BESOIN.md, priorités, hors périmètre et hypothèses retenues.
---

Cette page résume `BESOIN.md` (à la racine du dépôt, statut : brouillon v0.1), qui fait foi.

**Objectif** : retrouver sur macOS l'expérience de gestion des fenêtres de Windows 11 et Ubuntu, instantanée à la souris comme au clavier, adaptée aux configurations multi-écrans avec un écran vertical. Cible : macOS 26+, Apple silicon, Swift 6.

## Besoins fonctionnels

Priorités : **P0** indispensable au MVP, **P1** attendu en v1, **P2** plus tard.

| # | Besoin | Priorité |
|---|---|---|
| F1 | Snap par glisser-déposer, aperçu instantané | P0 |
| F2 | Restauration de la taille d'origine | P0 |
| F3 | Raccourcis façon `Win + flèches` | P0 |
| F4 | Dispositions composées | P0 |
| F5 | Bordure partagée entre fenêtres collées | P1 |
| F6 | Prise en compte de l'écran vertical | P0 |
| F7 | Multi-écrans | P0 |
| F8 | Snap Assist | P2 |
| F9 | Application de barre des menus et réglages | P0 |

## Besoins non fonctionnels

| # | Exigence |
|---|---|
| NF1 | Réactivité : aperçu en moins de 50 ms ; bordure partagée sans saccade. |
| NF2 | Sobriété : CPU proche de 0 % au repos, moins de 50 Mo de mémoire. |
| NF3 | Robustesse : une app qui ne répond pas ou refuse la taille ne bloque pas Fenestra ; la taille réelle est relue. |
| NF4 | API publiques uniquement, pas de SIP à désactiver. |
| NF5 | Coexistence avec le collage natif, avec recommandation de le désactiver. |
| NF6 | Confidentialité : aucune donnée collectée, aucun accès réseau. |

## Hors périmètre

- Tiling automatique de toutes les fenêtres (on garde un snap manuel).
- Gestion des bureaux macOS (Spaces) : pas d'API publique.
- Alt+Tab fenêtre par fenêtre : couvert par AltTab.
- Distribution sur l'App Store : impossible, l'app ne peut pas être sandboxée avec l'Accessibilité.

## Questions ouvertes et hypothèses retenues

| Question | Hypothèse retenue |
|---|---|
| Écran vertical : bord haut = moitié haute ou plein écran ? | **Moitié haute** par défaut, option pour maximiser. |
| Tiers d'écran (⅓ / ⅔) ? | Prévus, **au clavier seulement**, sans raccourci par défaut. |
| Bordure partagée sur des fenêtres placées à la main ? | **Uniquement** les fenêtres collées par Fenestra. |
| Marges entre fenêtres par défaut ? | **0**, comme sous Windows. |

## Jalons

M0 squelette, M1 moteur de zones et clavier, M2 snap par glisser et restauration, M3 bordure partagée, M4 réglages et exclusions, M5 Snap Assist.
