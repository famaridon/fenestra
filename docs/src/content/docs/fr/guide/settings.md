---
title: Réglages
description: Toutes les options de la fenêtre Réglages, par onglet.
---

Ouvrez les réglages depuis le menu de Fenestra dans la barre des menus. Chaque option est enregistrée immédiatement dans les préférences de l'utilisateur.

L'interrupteur général **Activer Fenestra** se trouve dans le menu de la barre des menus.

## Général

| Réglage | Défaut | Effet |
|---|---|---|
| Lancer à l'ouverture de session | désactivé | Démarre Fenestra à la connexion. |
| Placer les fenêtres en les glissant vers un bord | activé | Active le snap à la souris. La restauration au décollage et la bordure partagée n'en dépendent pas. |
| Restaurer la taille d'origine au décollage | activé | Rend la taille d'avant le snap quand on décolle une fenêtre. |
| Bordure partagée entre fenêtres collées | activé | Lie les fenêtres collées, voir [Bordure partagée](/fenestra/fr/guide/shared-border/). |
| Snap Layouts au survol du bouton vert | activé | Palette de dispositions quand le pointeur reste sur le bouton vert d'une fenêtre, voir [Snap Layouts](/fenestra/fr/guide/snap-layouts/). |
| Snap Assist | activé | Propose les autres fenêtres après un snap, voir [Snap Assist](/fenestra/fr/guide/snap-assist/). |
| Aperçu des fenêtres dans Snap Assist | désactivé | Affiche une miniature de chaque fenêtre. Grisé tant que Snap Assist est désactivé. Demande l'autorisation d'enregistrement de l'écran : tant qu'elle manque, une note et un bouton **Ouvrir les Réglages Système** apparaissent dessous. Voir [Miniatures des fenêtres](/fenestra/fr/guide/snap-assist/#miniatures-des-fenêtres). |
| Marge entre fenêtres | 0 pt | Espace entre fenêtres et avec les bords de l'écran. La bordure partagée la conserve. |
| Taille des coins | 120 pt | Longueur de bord comptée comme coin pour le glisser. |
| Bande de déclenchement entre deux écrans | 24 pt | Largeur de la zone qui déclenche le snap le long d'un bord partagé avec un autre écran. Les bords extérieurs gardent un seuil de 2 points. |

## Zones

| Réglage | Défaut | Effet |
|---|---|---|
| Moitiés, quarts, plein écran, tiers | tout sauf les tiers | Active ou désactive chaque zone. Une zone désactivée n'est jamais utilisée, ni à la souris, ni au clavier, ni par Snap Layouts ou Snap Assist, sans repli sur une autre. Les scripts et agents IA peuvent toujours l'utiliser. |
| Écran vertical : le bord haut passe en plein écran | désactivé | Sinon le bord haut donne la moitié haute. |
| Écran vertical : bords gauche/droit actifs | activé | Garde les moitiés gauche / droite sur un écran vertical. |
| Écran vertical : au clavier, ← et → coupent les moitiés haute et basse en quarts | activé | Sinon `←`/`→` sur une moitié haute ou basse donnent la moitié gauche / droite, comme sur un écran paysage. Voir [Écran vertical](/fenestra/fr/guide/vertical-display/#quarts--le-découpage-dans-lautre-sens). |

## Raccourcis

Une ligne par action avec un champ de saisie du raccourci, et un bouton pour **rétablir les raccourcis par défaut**. Voir [Raccourcis clavier](/fenestra/fr/guide/keyboard/).

Quand Rectangle, Magnet ou AeroSpace est utilisé sur le Mac, une section **Import** propose un bouton par application pour **reprendre ses raccourcis**. Voir [Garder les raccourcis de Rectangle, Magnet ou AeroSpace](/fenestra/fr/guide/keyboard/#garder-les-raccourcis-de-rectangle-magnet-ou-aerospace).

## Exclusions

Liste des **applications exclues** : aucun snap (souris, clavier, bordure) n'est appliqué à leurs fenêtres. Ajoutez ou retirez des applications dans cette liste.

## Agents

| Réglage | Défaut | Effet |
|---|---|---|
| Autoriser les agents IA et les scripts à disposer les fenêtres | activé | Permet à l'outil `fenestra`, et aux agents IA qui passent par lui (MCP), de lister et de disposer vos fenêtres. Voir [Agents IA et scripts](/fenestra/fr/guide/ai-agents/). |

Sous l'interrupteur, la configuration pour connecter **Claude Code** ou une autre **app MCP** (Claude Desktop, Cursor…), chacune avec un bouton **Copier**.

## À propos

Version et numéro de build, et un lien **Documentation** vers ce site (en français ou en anglais, selon la langue de macOS). Aucune donnée n'est collectée et Fenestra n'accède pas au réseau.
