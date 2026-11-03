---
title: Workspaces
description: Enregistrez un agencement de fenêtres sous un nom et retrouvez-le depuis le menu, un raccourci ou un agent IA.
---

Un **workspace** est un agencement de fenêtres enregistré sous un nom : quelle app va où, sur quel écran. Retrouvez-le d'un coup, les apps fermées étant relancées.

## Enregistrer un workspace

Disposez vos fenêtres, puis dans le menu de la barre des menus choisissez **Workspaces > Enregistrer l'agencement actuel…**. Les réglages s'ouvrent sur l'onglet **Workspaces** avec le nouveau workspace sélectionné : donnez-lui un nom et, si vous voulez, un raccourci.

Ce qui est enregistré, pour chaque fenêtre que Fenestra peut déplacer (voir [les règles](/fenestra/fr/guide/mouse/)) :

- l'**app** (son identifiant de bundle, pour la retrouver même renommée) ;
- l'**écran** où elle se trouve, par position (premier, deuxième… de gauche à droite) ;
- sa **zone** si elle est collée, sinon son **cadre exact**, en fractions de l'écran ;
- son **titre**, seulement quand l'app a plusieurs fenêtres, pour les distinguer.

Les fenêtres d'un autre Space sont invisibles pour Fenestra : un workspace couvre le Space courant.

## Le retrouver

- **Barre des menus** : **Workspaces**, puis le workspace.
- **Raccourci** : définissez-le dans l'onglet **Workspaces** des réglages. Un raccourci déjà utilisé par une action de snap reste à l'action de snap.
- **Agents IA et scripts** : `apply_workspace` ou `fenestra workspace apply <nom>`, voir [Agents IA](/fenestra/fr/guide/ai-agents/#workspaces).

Fenestra ouvre les apps qui n'ont pas de fenêtre et les attend (10 secondes au plus), place chaque fenêtre et met la première au premier plan. Les fenêtres qui ne font pas partie du workspace ne bougent pas. Un placement sur un écran qui n'est plus branché va sur l'écran principal.

## Basculer automatiquement avec les écrans

Activez **Appliquer automatiquement quand ces écrans sont branchés** pour un workspace : Fenestra retient les écrans branchés à ce moment-là (leurs tailles, quel que soit leur ordre ou leur identifiant). Ensuite, dès que la configuration d'écrans redevient celle-là, par exemple quand vous branchez le portable au bureau, le workspace s'applique tout seul, sans lancer d'app. Un workspace pour le bureau, un pour le portable seul, et vos fenêtres suivent.

Rien ne se passe au lancement, après une mise en veille, ni tant que les écrans ne changent pas. Si deux workspaces correspondent aux mêmes écrans, le premier de la liste l'emporte.

## Mettre à jour, renommer, supprimer

Dans l'onglet **Workspaces** des [réglages](/fenestra/fr/guide/settings/) :

- **Mettre à jour avec l'agencement actuel** remplace la disposition par les fenêtres telles qu'elles sont, en gardant le nom et le raccourci ;
- le champ **Nom** le renomme (touche Retour) ; deux workspaces ne peuvent pas porter le même nom ;
- **Appliquer** l'essaie tout de suite et indique les fenêtres qui n'ont pas pu être placées ;
- **−** le supprime.

Les workspaces sont dans `~/Library/Application Support/Fenestra/workspaces.json`, un fichier lisible : modifiez-le, versionnez-le, ou laissez un agent l'écrire par l'outil `fenestra`.
