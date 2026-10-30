---
title: Installation
description: Télécharger une version ou compiler depuis les sources, et autoriser l'Accessibilité.
---

Fenestra n'est pas distribué sur l'App Store : l'application ne peut pas être sandboxée tout en pilotant les fenêtres via l'Accessibilité. Téléchargez une version prête à l'emploi sur GitHub, ou compilez-la depuis les sources.

## Prérequis

- macOS 26 ou plus récent
- Mac Apple silicon

## Télécharger une version

1. [Téléchargez Fenestra](https://github.com/famaridon/fenestra/releases/latest/download/Fenestra.zip) (dernière version, `Fenestra.zip`), décompressez-le et déplacez `Fenestra.app` dans `/Applications`.
2. Les versions **ne sont pas encore signées ni notarisées** : macOS refuse d'ouvrir l'app au premier lancement. Retirez l'attribut de quarantaine dans un terminal :

   ```sh
   xattr -dr com.apple.quarantine /Applications/Fenestra.app
   ```

3. Lancez Fenestra, puis accordez l'autorisation d'Accessibilité (voir plus bas).

Les versions précédentes et leurs changements sont sur la [page des releases](https://github.com/famaridon/fenestra/releases).

:::caution[Mises à jour]
Une version non signée change d'identité à chaque version : macOS oublie l'autorisation d'Accessibilité. Après une mise à jour, supprimez l'ancienne entrée Fenestra de la liste Accessibilité et accordez de nouveau l'autorisation.
:::

## Compiler depuis les sources

Il faut en plus Xcode (avec un compte donnant un certificat **Apple Development**) et [Homebrew](https://brew.sh) pour installer XcodeGen.

Le projet Xcode est généré par [XcodeGen](https://github.com/yonaskolb/XcodeGen) à partir de `project.yml` ; le `.xcodeproj` n'est pas versionné.

```sh
brew install xcodegen
xcodegen generate
open Fenestra.xcodeproj
```

Dans Xcode, sélectionnez le schéma **Fenestra** puis lancez avec **Run** (⌘R).

## Premier lancement et autorisation d'Accessibilité

Fenestra vit dans la **barre des menus** : il n'a pas d'icône dans le Dock. Au premier lancement, une fenêtre d'accueil vous guide pour accorder l'autorisation d'Accessibilité et affiche son état en temps réel.

1. Ouvrez **Réglages Système > Confidentialité et sécurité > Accessibilité**.
2. Activez l'interrupteur à côté de **Fenestra**.
3. Revenez à la fenêtre d'accueil : l'état passe à « accordé » et Fenestra démarre ses moniteurs.

:::note
Sans cette autorisation, Fenestra ne peut ni déplacer ni redimensionner les fenêtres des autres applications.
:::

Une seconde autorisation, l'**enregistrement de l'écran**, est facultative : elle ne sert qu'aux [miniatures de Snap Assist](/fenestra/fr/guide/snap-assist/#miniatures-des-fenêtres), et Fenestra ne la demande que si vous activez cette option.

## Pourquoi la signature Apple Development ?

macOS associe l'autorisation d'Accessibilité à l'identité de signature de l'application. Une compilation signée « ad hoc » change d'identité à chaque build, et l'autorisation disparaît. Avec un certificat **Apple Development** stable, macOS reconnaît l'application d'une compilation à l'autre et **conserve l'autorisation**.

## Éviter le double snap

macOS 26 propose son propre collage de fenêtres. Pour éviter que les deux systèmes réagissent en même temps, désactivez le collage natif par glisser :

**Réglages Système > Bureau et Dock > Fenêtres**, puis désactivez le collage des fenêtres au glissement vers les bords de l'écran.

Fenestra cohabite avec le collage natif, mais le désactiver est recommandé.

## Lancer à l'ouverture de session

Dans les réglages de Fenestra (onglet **Général**), activez **Lancer à l'ouverture de session**. Fenestra utilise pour cela `SMAppService`.
