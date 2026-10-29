# Panes

Gestionnaire de fenêtres macOS (barre des menus) façon Windows / Ubuntu.

## Fonctionnalités

- Snap par glisser : bords et coins de l'écran, aperçu translucide, restauration de la taille d'origine au détachement.
- Raccourcis clavier globaux configurables (moitiés, quarts, tiers, plein écran, restauration, changement d'écran).
- Bordure partagée : redimensionner une fenêtre collée ajuste ses voisines.
- Snap Assist : propose les autres fenêtres pour l'espace restant.
- Écrans multiples et verticaux, réapplication automatique au changement de configuration.
- Applications exclues, marges entre fenêtres, lancement à la connexion.

Le besoin complet est décrit dans [BESOIN.md](BESOIN.md), l'architecture et les contrats entre modules dans [ARCHITECTURE.md](ARCHITECTURE.md).

## Compiler et lancer

```sh
brew install xcodegen   # si besoin
xcodegen generate
open Panes.xcodeproj    # puis Cmd+R
```

En ligne de commande :

```sh
xcodebuild -project Panes.xcodeproj -scheme Panes -destination 'platform=macOS' build
```

Au premier lancement, autoriser Panes dans **Réglages Système > Confidentialité et sécurité > Accessibilité**.

## Tests

```sh
xcodebuild -project Panes.xcodeproj -scheme Panes -destination 'platform=macOS' test
```

## Documentation

```sh
cd docs && pnpm install && pnpm dev
```
