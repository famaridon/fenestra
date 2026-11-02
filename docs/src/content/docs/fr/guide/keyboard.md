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
Les tiers (gauche, centre, droit, deux tiers gauche, deux tiers droite) existent comme actions, mais n'ont **pas de raccourci par défaut** : à vous d'en assigner dans les réglages. Ils sont aussi **désactivés** par défaut dans l'onglet **Zones** : activez-les, sinon leurs raccourcis ne font rien. Glisser vers un bord ne donne jamais un tiers ; la palette [Snap Layouts](/fenestra/fr/guide/snap-layouts/) les propose une fois activés.
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
6. `⌃⌥←` : il n'y a pas d'écran voisin, la fenêtre est **restaurée** (taille et position d'avant le premier snap).

Autres repères sur un écran paysage :

- `⌃⌥↑` sur une fenêtre non collée : plein écran. Sur une moitié : le quart du haut. Sur une fenêtre plein écran ou un quart du haut, sans écran au-dessus : rien.
- `⌃⌥↓` sur une fenêtre non collée : rien (contrairement à Windows, elle n'est pas réduite). Sur une fenêtre plein écran : restauration (ou, s'il y a un écran en dessous, passage sur cet écran ; voir plus bas). Sur une moitié : le quart du bas.
- `⌃⌥→` sur une moitié gauche : moitié droite (et inversement avec `←`).

### Deux écrans côte à côte

Écran A à gauche, écran B à droite, fenêtre non collée sur A.

1. `⌃⌥→` : moitié droite de A.
2. `⌃⌥→` encore : la fenêtre passe sur B, en **moitié gauche** (zone miroir).
3. `⌃⌥→` encore : moitié droite de B. Une nouvelle pression, faute de voisin à droite, restaure la fenêtre.

Dans l'autre sens, `⌃⌥←` sur une moitié gauche de B renvoie la fenêtre sur A en moitié droite.

### Deux écrans l'un au-dessus de l'autre

Écran A en haut, écran B en dessous (un portable sous un moniteur, par exemple), tous deux en paysage. Sur un écran vertical, `↑`/`↓` suivent d'autres règles, voir [Écran vertical](/fenestra/fr/guide/vertical-display/).

- `⌃⌥↓` sur une fenêtre plein écran de A : la fenêtre passe sur B, toujours en plein écran. `⌃⌥↑` la ramène.
- `⌃⌥↓` sur un quart du bas de A : la fenêtre passe sur B, dans le quart du **haut** correspondant (zone miroir). `⌃⌥↑` sur un quart du haut de B fait l'inverse.

Sur un écran vertical, le cycle utilise `↑`/`↓`, voir [Écran vertical](/fenestra/fr/guide/vertical-display/).

Après chaque snap sur une moitié ou un quart, [Snap Assist](/fenestra/fr/guide/snap-assist/) propose vos autres fenêtres pour l'espace libre.

## Autres actions

- **Quarts, plein écran, tiers** : placent la fenêtre dans la zone sur son écran courant. Si elle y est déjà, rien ne se passe.
- **Restaurer** : remet la fenêtre là où elle était avant le premier snap, taille et position (sans effet si elle n'est pas collée).
- **Écran suivant / précédent** : envoie la fenêtre sur l'écran suivant ou précédent. Une fenêtre collée garde sa zone ; une fenêtre non collée garde sa position relative et sa taille (réduite si elle ne tient pas). Voir [Multi-écrans](/fenestra/fr/guide/multiple-displays/).

:::note
Une zone désactivée dans l'onglet **Zones** des [réglages](/fenestra/fr/guide/settings/) n'est pas non plus utilisée au clavier : quand un raccourci y mènerait, rien ne se passe.
:::

## Changer les raccourcis

Ouvrez les réglages de Fenestra (depuis le menu de la barre des menus), onglet **Raccourcis** : cliquez sur un raccourci, saisissez la nouvelle combinaison. Un bouton permet de rétablir les raccourcis par défaut. Voir [Réglages](/fenestra/fr/guide/settings/).

:::caution
Un raccourci déjà pris par le système ou une autre application peut échouer à s'enregistrer : Fenestra l'ignore alors (il est consigné dans le journal).
:::

## Garder les raccourcis de Rectangle, Magnet ou AeroSpace

Si vous venez de **Rectangle**, **Magnet** ou **AeroSpace**, Fenestra trouve leurs réglages sur votre Mac et propose de reprendre leurs raccourcis : dans la fenêtre d'accueil au premier lancement, et en bas de l'onglet **Raccourcis** des réglages. Cliquez sur **Importer depuis Rectangle** (ou Magnet, ou AeroSpace) : les raccourcis des actions qui existent dans Fenestra remplacent les vôtres, les autres ne bougent pas. Rien n'est lu dans l'autre application avant le clic, et elle n'est jamais modifiée.

| Application | Où c'est lu | Ce qui est importé |
|---|---|---|
| Rectangle | ses préférences (`com.knollsoft.Rectangle`) | moitiés, quarts, plein écran, restauration, écran suivant / précédent, tiers ; une action laissée sans raccourci dans Rectangle le perd aussi dans Fenestra ; les entrées absentes suivent les défauts de Rectangle (jeu recommandé ou jeu Spectacle) |
| Magnet | ses préférences (`com.crowdcafe.windowmagnet`) | moitiés, quarts, tiers, plein écran, restauration ; les entrées absentes suivent les raccourcis d'usine de Magnet ; les raccourcis d'écran gardent ceux de Fenestra (qui sont aussi ceux de Magnet) |
| AeroSpace | `~/.aerospace.toml` ou `~/.config/aerospace/aerospace.toml`, table `[mode.main.binding]` | `move left/right/up/down` → les actions fléchées, `fullscreen` → plein écran, `move-node-to-monitor left/prev/right/next` → écran précédent / suivant ; les noms de touches sont lus comme sur un clavier QWERTY |

Un raccourci repris par un import est retiré de toute autre action qui l'utilisait, pour qu'un raccourci garde une seule action. Les raccourcis sans équivalent (*Center* de Rectangle, `focus` ou `workspace` d'AeroSpace…) sont comptés dans la fenêtre et listés dans le journal (Console, sous-système `com.florentamaridon.Fenestra`, catégorie `shortcut-import`). Vous pouvez importer de nouveau à tout moment, ou rétablir les raccourcis par défaut.

:::tip
Quittez l'autre application (ou désactivez ses raccourcis) avant d'utiliser ceux de Fenestra : deux applications qui enregistrent le même raccourci global ne font pas bon ménage.
:::
