---
title: Architecture
description: Découpage en modules, repère de coordonnées unique et flux de données.
---

Cette page résume `ARCHITECTURE.md` (à la racine du dépôt), qui reste la référence du contrat entre modules et des signatures.

## Conventions

- **Swift 6**, mode strict de concurrence. Tout ce qui touche AppKit, l'Accessibilité ou les événements souris est `@MainActor`.
- **Pas d'API privée** (NF4) et **aucune dépendance tierce** (pas de SwiftPM externe).
- Textes d'interface écrits en anglais dans le code et traduits dans `Localizable.xcstrings` (français) ; identifiants de code en anglais.
- Pas de `print` : journalisation avec `os.Logger` (sous-système `com.florentamaridon.Fenestra`, une catégorie par module).

## Modules

| Dossier | Rôle |
|---|---|
| `App/` | Point d'entrée, `AppController` (assemblage), construction des écrans depuis `NSScreen`. |
| `Core/` | Swift pur (Foundation + CoreGraphics), 100 % testable : géométrie, zones, résolveurs, registre des snaps, bordure partagée, association des fenêtres entre API. |
| `Accessibility/` | `AXWindow` (enveloppe d'un `AXUIElement`) et `AXWindowFinder`. |
| `Capture/` | `WindowThumbnailer` (miniatures des fenêtres avec ScreenCaptureKit) et `ScreenRecordingPermission`. |
| `Input/` | `DragMonitor` (souris globale) et `HotkeyManager` (Carbon `RegisterEventHotKey`). |
| `Settings/` | Modèle `Settings` observable, persisté dans `UserDefaults`, et `LaunchAtLogin` (`SMAppService`). |
| `UI/` | Barre des menus, accueil, réglages, saisie de raccourci, panneaux d'aperçu et de Snap Assist. |
| `Controllers/` | `SnapController`, `SharedBorderController`, `ScreenWatcher`, `SnapAssistController`. |

## Un seul repère de coordonnées

:::caution[Règle centrale]
Tout le code métier travaille dans le repère **AX** : origine en haut à gauche de l'écran principal, `y` vers le bas, en points. C'est celui de `AXUIElement` et de `CGEvent`.
:::

`NSScreen` et `NSEvent.mouseLocation` ont leur origine en bas à gauche. La conversion se fait **uniquement** dans `ScreenGeometry` (`toAX` / `toCocoa`), avec `axRect.origin.y = primaryHeight - cocoaRect.maxY`. Elle est couverte par des tests unitaires. Seuls les panneaux d'aperçu reçoivent des cadres Cocoa, convertis par l'appelant.

## Flux de données

```text
Glisser
  DragMonitor (souris, repère AX)
    -> SnapController.mouseDown / mouseDragged / mouseUp
       -> AXWindowFinder.window(at:)       fenêtre sous le pointeur
       -> DragZoneResolver.zone(...)        pointeur + écran -> Zone ?
       -> SnapPreviewPanel.show / hide      aperçu translucide
       -> (relâché) place(zone, on: screen)
            Zone.frame -> AXWindow.setFrame -> relecture -> SnapRegistry
       -> SnapAssistController              si la zone a un complément

Clavier
  HotkeyManager (Carbon)
    -> AppController.perform(action)
       -> SnapController.perform(action)
          -> KeyboardSnapResolver.command(...)   action + état + écran -> SnapCommand
          -> place(...) | restore(...) | rien
          -> SnapAssistController            après un place, si la zone a un complément
```

Autres flux :

- **Bordure partagée** : si la *taille* change pendant un glisser sur une fenêtre collée, `SharedBorderController` appelle `SharedBorderResolver.adjustments(...)` (fonction pure) puis applique les nouveaux cadres.
- **Restauration** : si la *position* change sur une fenêtre collée, la taille d'origine (`SnapRecord.restoreFrame`) est rendue une seule fois et l'enregistrement est retiré.
- **Écrans** : `ScreenWatcher` réapplique la zone de chaque fenêtre du registre quand la configuration des écrans change.

## Robustesse

Chaque `AXUIElementCreateApplication` reçoit un délai de messagerie de 0,25 s. `setFrame` applique taille, position, puis taille, et **relit toujours** le cadre réel : une application qui refuse la taille ne bloque rien.

## Tests

Les tests (Swift Testing) portent surtout sur `Core/`.

```sh
xcodebuild test -scheme Fenestra -destination 'platform=macOS'
```

## Documentation

Ce site est dans `docs/` (Astro Starlight) ; voir `docs/README.md` pour les commandes.
