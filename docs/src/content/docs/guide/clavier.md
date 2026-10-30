---
title: Raccourcis clavier
description: Actions, raccourcis par défaut et comportement en cycle façon Win + flèches.
---

## Table des actions

| Action | Raccourci par défaut |
|---|---|
| Gauche | `⌃⌥←` |
| Droite | `⌃⌥→` |
| Haut | `⌃⌥↑` |
| Bas | `⌃⌥↓` |
| Quart haut gauche | `⌃⌥U` |
| Quart haut droit | `⌃⌥I` |
| Quart bas gauche | `⌃⌥J` |
| Quart bas droit | `⌃⌥K` |
| Plein écran | `⌃⌥↩` |
| Restaurer | `⌃⌥⌫` |
| Écran suivant | `⌃⌥⌘→` |
| Écran précédent | `⌃⌥⌘←` |
| Tiers (⅓, ⅔) | aucun par défaut |

:::note
Les tiers (gauche, centre, droit, deux tiers gauche, deux tiers droite) existent comme actions, mais n'ont **pas de raccourci par défaut** : à vous d'en assigner dans les réglages. Ils ne sont pas accessibles à la souris.
:::

## Le cycle des flèches

Comme avec `Win + flèches`, appuyer plusieurs fois sur la même flèche fait progresser la fenêtre.

### Un seul écran, écran paysage

Partons d'une fenêtre non collée.

1. `⌃⌥←` : moitié gauche.
2. `⌃⌥↑` : quart haut gauche.
3. `⌃⌥↓` : retour à la moitié gauche.
4. `⌃⌥↓` encore : quart bas gauche.
5. `⌃⌥↑` : moitié gauche de nouveau.
6. `⌃⌥←` : il n'y a pas d'écran voisin, la fenêtre est **restaurée** à sa taille d'origine.

Autres repères sur un écran paysage :

- `⌃⌥↑` sur une fenêtre non collée : plein écran. Sur une moitié : le quart du haut.
- `⌃⌥↓` sur une fenêtre pleine écran : restauration. Sur une moitié : le quart du bas.
- `⌃⌥→` sur une moitié gauche : moitié droite (et inversement avec `←`).

### Deux écrans côte à côte

Écran A à gauche, écran B à droite, fenêtre non collée sur A.

1. `⌃⌥→` : moitié droite de A.
2. `⌃⌥→` encore : la fenêtre passe sur B, en **moitié gauche** (zone miroir).
3. `⌃⌥→` encore : moitié droite de B. Une nouvelle pression, faute de voisin à droite, restaure la fenêtre.

Dans l'autre sens, `⌃⌥←` sur une moitié gauche de B renvoie la fenêtre sur A en moitié droite.

Sur un écran vertical, le cycle utilise `↑`/`↓`, voir [Écran vertical](/guide/ecran-vertical/).

## Autres actions

- **Quarts, plein écran, tiers** : placent la fenêtre dans la zone sur son écran courant. Si elle y est déjà, rien ne se passe.
- **Restaurer** : rend à la fenêtre sa taille d'avant le premier snap (sans effet si elle n'est pas collée).
- **Écran suivant / précédent** : envoie la fenêtre sur l'écran suivant ou précédent. Une fenêtre collée garde sa zone ; une fenêtre non collée est déplacée proportionnellement. Voir [Multi-écrans](/guide/multi-ecrans/).

## Changer les raccourcis

Ouvrez les réglages de Fenestra (depuis le menu de la barre des menus), onglet **Raccourcis** : cliquez sur un raccourci, saisissez la nouvelle combinaison. Un bouton permet de rétablir les raccourcis par défaut. Voir [Réglages](/guide/reglages/).

:::caution
Un raccourci déjà pris par le système ou une autre application peut échouer à s'enregistrer : Fenestra l'ignore alors (il est consigné dans le journal).
:::
