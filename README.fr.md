<p align="center">
  <img src="docs/src/assets/logo.svg" alt="" width="128" height="128">
</p>

<h1 align="center">Fenestra</h1>

<p align="center">Gestionnaire de fenêtres macOS (barre des menus) façon Windows / Ubuntu.<br>
<a href="https://famaridon.github.io/fenestra/fr/">Documentation</a> · <a href="README.md">English</a></p>

## Fonctionnalités

- Snap par glisser : bords et coins de l'écran, aperçu translucide, restauration de la taille d'origine au détachement.
- Raccourcis clavier globaux configurables (moitiés, quarts, tiers, plein écran, restauration, changement d'écran).
- Bordure partagée : redimensionner une fenêtre collée ajuste ses voisines.
- Snap Assist : après un snap à la souris ou au clavier, propose les autres fenêtres pour l'espace restant, avec des miniatures en option.
- Écrans multiples et verticaux, réapplication automatique au changement de configuration.
- Applications exclues, marges entre fenêtres, lancement à la connexion.

Le besoin complet est décrit dans [BESOIN.md](BESOIN.md), l'architecture et les contrats entre modules dans [ARCHITECTURE.md](ARCHITECTURE.md).

## Installer

**[Télécharger Fenestra](https://github.com/famaridon/fenestra/releases/latest/download/Fenestra.zip)** (dernière version ; toutes les versions sur la [page des releases](https://github.com/famaridon/fenestra/releases)). Les versions ne sont pas encore signées : voir le [guide d'installation](https://famaridon.github.io/fenestra/fr/guide/installation/#télécharger-une-version) pour ouvrir l'app.

## Compiler et lancer

```sh
brew install xcodegen   # si besoin
xcodegen generate
open Fenestra.xcodeproj    # puis Cmd+R
```

En ligne de commande :

```sh
xcodebuild -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' build
```

Au premier lancement, autoriser Fenestra dans **Réglages Système > Confidentialité et sécurité > Accessibilité**.

## Tests

```sh
xcodebuild -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' test
```

## Documentation

```sh
cd docs && pnpm install && pnpm dev
```

Le site est en anglais (racine) et en français (`src/content/docs/fr/`).

## Publier une version

Poussez un tag `vX.Y.Z` (ou `vX.Y.Z-beta.1` pour une préversion) : le workflow `Release` lance les tests, compile une app arm64 non signée et publie `Fenestra.zip` dans les Releases GitHub.

```sh
git tag v0.1.0 && git push origin v0.1.0
```
