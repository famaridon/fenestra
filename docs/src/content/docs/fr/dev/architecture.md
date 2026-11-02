---
title: Architecture
description: Features et couches de clean architecture, repère de coordonnées unique et flux de données.
---

Cette page résume `ARCHITECTURE.md` (à la racine du dépôt), qui reste la référence du contrat entre modules et des signatures.

## Conventions

- **Swift 6**, mode strict de concurrence. Tout ce qui touche AppKit, l'Accessibilité ou les événements souris est `@MainActor`, comme les use cases.
- **Pas d'API privée** et **aucune dépendance tierce** dans l'app ni dans l'outil `fenestra`. Seule exception : la cible de tests utilise [Harmonize](https://github.com/perrystreetsoftware/Harmonize) pour vérifier l'architecture.
- Textes d'interface écrits en anglais dans le code et traduits dans `Localizable.xcstrings` (français) ; identifiants de code en anglais.
- Pas de `print` : journalisation avec `os.Logger` (sous-système `com.florentamaridon.Fenestra`, une catégorie par module).

## Couches

Le code est rangé **par feature**, puis **par couche** : `Sources/Fenestra/<Feature>/<Couche>/`.

| Couche | Contenu | Peut utiliser | Imports |
|---|---|---|---|
| **Domain** | Valeurs et règles pures (structs, enums), testées sans mock | Domain | Foundation, CoreGraphics |
| **Application** | **Use cases** (un type par cas, méthode `execute`) et **ports** (protocoles) | Domain, Application | Foundation, CoreGraphics, Observation, os |
| **Infrastructure** | Adaptateurs système qui implémentent les ports : Accessibilité, Carbon, NSEvent, ScreenCaptureKit, NSWorkspace, socket | Domain, Application, Infrastructure | tous |
| **Presentation** | SwiftUI et panneaux ; les panneaux implémentent les ports d'affichage | Domain, Application, Presentation | tous |
| **App** (`App/`) | Point d'assemblage : construit les adaptateurs et les use cases, les branche | tout | tous |

- Infrastructure et Presentation ne se connaissent pas.
- Une feature n'utilise d'une autre feature que son **Domain** et son **Application**.
- `Kernel` est partagé par toutes les features et ne dépend d'aucune.
- Quand deux features dépendraient l'une de l'autre, l'une déclare un port que l'autre implémente : Snapping déclare `SnapFollowUp` (implémenté par Snap Assist) et `SnappedWindowResizeHandler` (implémenté par la bordure partagée).

`Tests/FenestraTests/Architecture/ArchitectureTests.swift` vérifie ces règles avec Harmonize : place de chaque fichier, imports de Domain et Application, aucune classe dans Domain, types utilisés par chaque couche.

## Features

| Dossier | Rôle |
|---|---|
| `App/` | Point d'entrée, `AppController` (assemblage, démarre et arrête les moniteurs selon les réglages). |
| `Kernel/` | Écrans et géométrie (`ScreenInfo`, `ScreenLayout`, `ScreenGeometry`), `Zone` ; ports `WindowHandle`, `WindowSystem`, `DisplayProvider`, `PointerState` et leurs adaptateurs Accessibilité / `NSScreen`. |
| `Snapping/` | Glisser, clavier, restauration, changement d'écrans. Use cases `DragSnapSession`, `SnapWithKeyboard`, `SnapWindowToZone`, `PlaceWindowInZone`, `ReapplySnapsAfterDisplayChange` ; `SnapStore` garde les fenêtres collées. |
| `SharedBorder/` | `SharedBorderResolver` (pur) et le use case `PropagateBorderResize`. |
| `SnapAssist/` | Use case `OfferSnapAssist`, panneau, miniatures (ScreenCaptureKit), autorisation d'enregistrement de l'écran. |
| `SnapLayouts/` | Use case `ShowSnapLayouts`, surveillance du survol du bouton vert, palette. |
| `ExternalControl/` | `LayoutPlanner` (pur), use cases `ListDisplays`, `ListWindows`, `ApplyLayout`, répartiteur JSON et socket Unix. |
| `Settings/` | Modèle observable `Settings` persisté dans `UserDefaults`, `LaunchAtLogin`, vues des réglages. |
| `Onboarding/`, `MenuBar/` | Autorisation d'Accessibilité et fenêtre d'accueil ; contenu de la barre des menus. |
| `Sources/Shared/` | `ControlSocket` : le protocole du socket, compilé dans l'app et dans l'outil. |
| `Sources/FenestraCLI/` | L'outil `fenestra`, livré dans `Contents/Helpers/` : ligne de commande et serveur MCP sur stdio, sans dépendance tierce. |

## Un seul repère de coordonnées

:::caution[Règle centrale]
Toute la logique métier travaille dans le repère **AX** : origine en haut à gauche de l'écran principal, `y` vers le bas, en points. C'est le repère de `AXUIElement` et de `CGEvent`.
:::

`NSScreen` et `NSEvent.mouseLocation` ont leur origine en bas à gauche. La conversion se fait **uniquement** dans `ScreenGeometry` (`toAX` / `toCocoa`), avec `axRect.origin.y = primaryHeight - cocoaRect.maxY`. Elle est couverte par des tests unitaires. Tous les cadres qui traversent un port sont en repère AX ; les panneaux convertissent eux-mêmes vers Cocoa.

## Flux de données

```text
Glisser
  DragMonitor (souris, repère AX)
    -> DragSnapSession.mouseDown / mouseDragged / mouseUp
       -> WindowSystem.window(at:)          fenêtre sous le pointeur
       -> DragZoneResolver.zone(...)        pointeur + écran -> Zone ?
       -> SnapPreview.show / hide           aperçu translucide
       -> (relâché) PlaceWindowInZone
            Zone.frame -> WindowHandle.setFrame -> relecture -> SnapStore
       -> SnapFollowUp.windowSnapped        Snap Assist, si la zone a un complément

Clavier
  HotkeyManager (Carbon) ou menu
    -> AppController.perform(action)
       -> SnapWithKeyboard.execute(action)
          -> KeyboardSnapResolver.command(...)   action + état + écran -> SnapCommand
          -> SnapWindowToZone | restauration | déplacement vers l'écran suivant
```

Autres flux :

- **Bordure partagée** : si la *taille* change pendant le glisser d'une fenêtre collée, `DragSnapSession` appelle `SnappedWindowResizeHandler`, implémenté par `PropagateBorderResize`, qui appelle `SharedBorderResolver.adjustments(...)` (fonction pure) et applique les nouveaux cadres.
- **Restauration** : si la *position* change sur une fenêtre collée et que **Restore original size when unsnapping** est actif, la taille d'origine (`SnapRecord.restoreFrame`) est appliquée une fois et l'enregistrement est retiré.
- **Écrans** : `ScreenWatcher` lance `ReapplySnapsAfterDisplayChange` quand la configuration des écrans change.

## Robustesse

Chaque `AXUIElementCreateApplication` reçoit un délai de messagerie de 0,25 s. `setFrame` applique taille, position, puis taille, et **relit toujours** le cadre obtenu : une app qui refuse la taille ne bloque rien.

## Tests

Les tests (Swift Testing) suivent les features dans `Tests/FenestraTests/<Feature>/`. Ils couvrent le Domain, et les use cases avec des fakes des ports (`Support/Fakes.swift`), sans Accessibilité ni vrai écran. `Architecture/` contient les règles de couches.

```sh
xcodegen generate   # le .xcodeproj n'est pas versionné
xcodebuild test -project Fenestra.xcodeproj -scheme Fenestra -destination 'platform=macOS' -derivedDataPath build
```

## Documentation

Ce site vit dans `docs/` (Astro Starlight) ; voir `docs/README.md` pour les commandes.
