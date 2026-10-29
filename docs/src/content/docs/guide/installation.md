---
title: Installation
description: Prérequis, compilation depuis les sources et autorisation d'Accessibilité.
---

Panes n'est pas distribué sur l'App Store : l'application ne peut pas être sandboxée tout en pilotant les fenêtres via l'Accessibilité. On la compile donc depuis les sources.

## Prérequis

- macOS 26 ou plus récent
- Mac Apple silicon
- Xcode (avec un compte donnant un certificat **Apple Development**)
- [Homebrew](https://brew.sh) pour installer XcodeGen

## Compiler depuis les sources

Le projet Xcode est généré par [XcodeGen](https://github.com/yonaskolb/XcodeGen) à partir de `project.yml` ; le `.xcodeproj` n'est pas versionné.

```sh
brew install xcodegen
xcodegen generate
open Panes.xcodeproj
```

Dans Xcode, sélectionnez le schéma **Panes** puis lancez avec **Run** (⌘R).

## Premier lancement et autorisation d'Accessibilité

Panes vit dans la **barre des menus** : il n'a pas d'icône dans le Dock. Au premier lancement, une fenêtre d'accueil vous guide pour accorder l'autorisation d'Accessibilité et affiche son état en temps réel.

1. Ouvrez **Réglages Système > Confidentialité et sécurité > Accessibilité**.
2. Activez l'interrupteur à côté de **Panes**.
3. Revenez à la fenêtre d'accueil : l'état passe à « accordé » et Panes démarre ses moniteurs.

:::note
Sans cette autorisation, Panes ne peut ni déplacer ni redimensionner les fenêtres des autres applications.
:::

## Pourquoi la signature Apple Development ?

macOS associe l'autorisation d'Accessibilité à l'identité de signature de l'application. Une compilation signée « ad hoc » change d'identité à chaque build, et l'autorisation disparaît. Avec un certificat **Apple Development** stable, macOS reconnaît l'application d'une compilation à l'autre et **conserve l'autorisation**.

## Éviter le double snap

macOS 26 propose son propre collage de fenêtres. Pour éviter que les deux systèmes réagissent en même temps, désactivez le collage natif par glisser :

**Réglages Système > Bureau et Dock > Fenêtres**, puis désactivez le collage des fenêtres au glissement vers les bords de l'écran.

Panes cohabite avec le collage natif, mais le désactiver est recommandé.

## Lancer à l'ouverture de session

Dans les réglages de Panes (onglet **Général**), activez **Lancer à l'ouverture de session**. Panes utilise pour cela `SMAppService`.
