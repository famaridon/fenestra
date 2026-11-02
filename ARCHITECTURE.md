# Fenestra — Architecture et contrat entre modules

Ce document fixe le découpage du code et les API partagées. Chaque module est
développé indépendamment ; le respect strict des signatures ci-dessous est ce
qui permet l'assemblage final.

## Règles générales

- Swift 6, mode strict de concurrence. Tout ce qui touche AppKit, l'Accessibilité
  ou les événements souris est `@MainActor`. Les use cases aussi (ils pilotent des fenêtres).
- **Un seul repère de coordonnées dans tout le code métier : le repère « AX »**
  (origine en haut à gauche de l'écran principal, `y` vers le bas, en points).
  C'est le repère de `AXUIElement` et de `CGEvent`. `NSScreen` et
  `NSEvent.mouseLocation` utilisent l'origine en bas à gauche : la conversion
  se fait **uniquement** dans `ScreenGeometry`. Les ports ne transportent que du repère AX ;
  les panneaux (Presentation) convertissent eux-mêmes vers Cocoa.
- Pas d'API privée. Aucune dépendance externe dans l'app ni dans l'outil `fenestra`.
  Seule exception : la cible de tests utilise **Harmonize** (règles d'architecture, voir plus bas).
- Textes d'interface écrits en **anglais** dans le code et traduits dans `Sources/Fenestra/Localizable.xcstrings` (français) ; l'app suit la langue de macOS. Identifiants de code en anglais.
- Pas de `print` de debug dans le code livré ; utiliser `os.Logger`
  (`Logger(subsystem: "com.florentamaridon.Fenestra", category: "<module>")`).

## Couches (clean architecture)

Le code est rangé **par feature**, puis **par couche** : `Sources/Fenestra/<Feature>/<Couche>/`.

| Couche | Contenu | Peut utiliser | Imports autorisés |
|---|---|---|---|
| **Domain** | valeurs et règles pures (structs, enums), testées sans mock | Domain | Foundation, CoreGraphics |
| **Application** | **use cases** (un type par cas, méthode `execute`) et **ports** (protocoles) | Domain, Application | Foundation, CoreGraphics, Observation, os |
| **Infrastructure** | adaptateurs système qui implémentent les ports : Accessibilité, Carbon, NSEvent, ScreenCaptureKit, NSWorkspace, socket | Domain, Application, Infrastructure | tous |
| **Presentation** | SwiftUI, NSPanel ; les panneaux implémentent les ports d'affichage | Domain, Application, Presentation | tous |
| **App** (`App/`) | point d'assemblage : construit les adaptateurs et les use cases, les branche | tout | tous |

- Infrastructure et Presentation ne se connaissent pas.
- Une feature n'utilise d'une autre feature que son **Domain** et son **Application**, jamais son
  Infrastructure ni sa Presentation.
- `Kernel` est partagé par toutes les features, à toutes les couches (même règle de sens), et ne dépend
  d'aucune feature.
- Quand deux features dépendraient l'une de l'autre, l'une déclare un port que l'autre implémente
  (inversion de dépendance) : `SnapFollowUp` (Snap Assist) et `SnappedWindowResizeHandler` (bordure partagée)
  sont déclarés par Snapping.

Ces règles sont vérifiées par `Tests/FenestraTests/Architecture/ArchitectureTests.swift`, avec
[Harmonize](https://github.com/perrystreetsoftware/Harmonize) (version épinglée dans `project.yml`, fichier
`.harmonize.yaml` à la racine) : place de chaque fichier, imports de Domain et Application, Domain sans classe, et
types utilisés par chaque couche (identifiants relevés avec SwiftSyntax).

## Arborescence

```
Sources/Fenestra/
  App/                                  — composition root
    FenestraApp.swift                   — @main, scènes SwiftUI (MenuBarExtra, Settings, fenêtre d'accueil)
    AppDelegate.swift                   — fenêtre d'accueil au 1er lancement
    AppController.swift                 — construit et branche tout ; démarre / arrête les moniteurs selon les réglages
  Kernel/                               — partagé par toutes les features
    Domain/ScreenGeometry.swift         — conversion Cocoa <-> AX
    Domain/ScreenInfo.swift             — modèle d'écran, orientation
    Domain/ScreenLayout.swift           — ensemble d'écrans : voisinage, écran contenant un point/une fenêtre
    Domain/Zone.swift                   — enum Zone + calcul de cadre
    Application/WindowHandle.swift      — port WindowHandle (une fenêtre d'une autre app) + WindowRef (clé hashable)
    Application/SystemPorts.swift       — ports WindowSystem, DisplayProvider, PointerState
    Infrastructure/AXWindow.swift       — WindowHandle sur un AXUIElement
    Infrastructure/AXWindowFinder.swift — recherches par l'API d'Accessibilité + AXWindowSystem
    Infrastructure/ScreenInfo+NSScreen.swift — NSScreenDisplays, SystemPointer, ScreenInfo depuis NSScreen
    Presentation/ScreenGeometry+Cocoa.swift  — conversion AX -> Cocoa pour placer les panneaux
  Snapping/                             — glisser, clavier, restauration, changement d'écrans
    Domain/DragZoneResolver.swift       — pointeur près d'un bord -> Zone ?
    Domain/KeyboardSnapResolver.swift   — action clavier + état -> commande
    Domain/SnapAction.swift             — actions clavier + raccourcis par défaut
    Domain/KeyboardShortcut.swift       — raccourci clavier (valeur pure)
    Domain/SnapRegistry.swift           — mémoire des fenêtres collées (restauration au décollage)
    Domain/SnapSettings.swift           — instantané des réglages lus par les use cases
    Domain/SnapGeometry.swift           — cadre au décollage, déplacement proportionnel entre écrans
    Application/SnappingPorts.swift     — ports SnapSettingsProvider, SnapPreview, SnapFollowUp, SnappedWindowResizeHandler
    Application/SnapStore.swift         — fenêtres collées de la session (SnapRegistry<WindowRef>)
    Application/ManageableWindows.swift — fenêtres que Fenestra peut déplacer
    Application/PlaceWindowInZone.swift — use case : placer une fenêtre dans une zone et l'enregistrer
    Application/SnapWindowToZone.swift  — use case : snap choisi par l'utilisateur (premier plan + Snap Assist)
    Application/SnapWithKeyboard.swift  — use case : action clavier sur la fenêtre active
    Application/DragSnapSession.swift   — use case avec état : un glisser, du clic au relâchement
    Application/ReapplySnapsAfterDisplayChange.swift — use case : replacer les fenêtres collées
    Infrastructure/DragMonitor.swift    — événements souris globaux (repère AX)
    Infrastructure/HotkeyManager.swift  — raccourcis globaux (Carbon RegisterEventHotKey)
    Infrastructure/ScreenWatcher.swift  — changement d'écrans -> ReapplySnapsAfterDisplayChange
    Presentation/SnapPreviewPanel.swift — aperçu translucide (port SnapPreview)
  SharedBorder/
    Domain/SharedBorderResolver.swift   — calcul de la bordure partagée
    Domain/SharedBorderGeometry.swift   — bords entraînés, correction après un refus de taille
    Application/PropagateBorderResize.swift — use case (port SnappedWindowResizeHandler)
  SnapAssist/
    Domain/WindowMatcher.swift          — associe une fenêtre AX à une fenêtre ScreenCaptureKit
    Application/SnapAssistPorts.swift   — SnapAssistCandidate ; ports SnapAssistPresenter, WindowThumbnails, ScreenRecordingAccess
    Application/OfferSnapAssist.swift   — use case (port SnapFollowUp) : proposer les fenêtres, placer la choisie
    Infrastructure/WindowThumbnailer.swift — miniatures (ScreenCaptureKit)
    Infrastructure/ScreenRecordingPermission.swift — autorisation d'enregistrement de l'écran
    Presentation/SnapAssistPanel.swift  — panneau Snap Assist (port SnapAssistPresenter)
  SnapLayouts/
    Domain/SnapLayout.swift             — dispositions de la palette
    Application/SnapLayoutsPorts.swift  — ports ZoomButtonLocator, SnapLayoutsPresenter
    Application/ShowSnapLayouts.swift   — use case : palette au repos du pointeur sur le bouton vert
    Infrastructure/ZoomButtonHoverMonitor.swift — survol (NSEvent) + AXZoomButtonLocator
    Presentation/SnapLayoutsPanel.swift — palette (port SnapLayoutsPresenter), se ferme quand le pointeur s'éloigne
  ExternalControl/                      — commandes de l'outil fenestra (CLI, MCP)
    Domain/LayoutSpec.swift             — LayoutSpec et LayoutPlanner : fenêtres -> cadres
    Application/ControlResults.swift    — résultats JSON des commandes ; port AppLauncher
    Application/ListDisplays.swift, ListWindows.swift, ApplyLayout.swift — use cases
    Infrastructure/CommandDispatcher.swift — JSON -> use case -> réponse
    Infrastructure/ControlServer.swift  — socket Unix local (~/Library/Application Support/Fenestra/control.sock)
    Infrastructure/WorkspaceAppLauncher.swift — lance les apps (NSWorkspace)
  ShortcutImport/                       — reprise des raccourcis de Rectangle, Magnet et AeroSpace
    Domain/ShortcutSource.swift         — ShortcutSource, ShortcutSourceData, ImportedShortcuts (fusion), PreferenceShortcut
    Domain/RectangleShortcuts.swift     — préférences de Rectangle -> ImportedShortcuts (défauts recommandés / Spectacle)
    Domain/MagnetShortcuts.swift        — préférences de Magnet -> ImportedShortcuts
    Domain/AeroSpaceShortcuts.swift     — ~/.aerospace.toml ([mode.main.binding]) -> ImportedShortcuts ; mini-lecteur TOML
    Application/ShortcutImportPorts.swift — ports ShortcutSourceReader, ShortcutsStore
    Application/DetectShortcutSources.swift, ImportShortcuts.swift — use cases
    Infrastructure/SystemShortcutSourceReader.swift — UserDefaults (ou conteneur sandbox) et fichiers du dossier personnel
    Presentation/ShortcutImportView.swift — bloc « Importer depuis … », injecté dans l'accueil et l'onglet Raccourcis par App
  Settings/
    Application/Settings.swift          — modèle @Observable persisté dans UserDefaults (+ snapSettings) ; port LoginItem ; implémente ShortcutsStore
    Infrastructure/LaunchAtLogin.swift  — SMAppService
    Presentation/SettingsView.swift, ShortcutRecorderView.swift, ExcludedAppsView.swift
  Onboarding/
    Application/AccessibilityPermission.swift — état de l'autorisation (interrogé jusqu'à l'accord) ; port AccessibilityTrust
    Infrastructure/AXAccessibilityTrust.swift — AXIsProcessTrusted
    Presentation/OnboardingView.swift   — accueil
  MenuBar/
    Presentation/MenuBarView.swift      — contenu du MenuBarExtra
Config/Signing.xcconfig                 — signature des builds locaux : ad hoc, ou votre équipe dans Config/Signing.local.xcconfig (non versionné)
Sources/Shared/ControlSocket.swift      — protocole du socket, partagé par l'app et l'outil
Sources/FenestraCLI/main.swift          — outil `fenestra` (Contents/Helpers) : CLI + serveur MCP stdio
Tests/FenestraTests/<Feature>/          — Swift Testing : Domain, et use cases avec des fakes des ports (Support/Fakes.swift)
Tests/FenestraTests/Architecture/       — règles de dépendance entre couches (Harmonize)
docs/                                   — site Astro Starlight (documentation utilisateur et développeur)
```

## Contrat des types partagés

### Kernel/Domain : géométrie

```swift
enum ScreenOrientation: String, Sendable, Codable { case landscape, portrait }

struct ScreenInfo: Hashable, Sendable, Identifiable {
    let id: CGDirectDisplayID
    let frame: CGRect          // cadre complet, repère AX
    let visibleFrame: CGRect   // sans barre des menus ni Dock, repère AX
    init(id: CGDirectDisplayID, frame: CGRect, visibleFrame: CGRect)
    var orientation: ScreenOrientation { frame.height > frame.width ? .portrait : .landscape }
    var isPortrait: Bool { get }
}

enum Direction: Sendable { case left, right, up, down }

struct ScreenLayout: Sendable {
    let screens: [ScreenInfo]
    init(screens: [ScreenInfo])
    func screen(id: CGDirectDisplayID) -> ScreenInfo?
    func screen(containing point: CGPoint) -> ScreenInfo?
    /// Écran qui contient la plus grande part du cadre ; sinon le plus proche.
    func screen(for windowFrame: CGRect) -> ScreenInfo?
    /// Écran voisin dans une direction (chevauchement sur l'axe perpendiculaire, puis distance).
    func neighbor(of screen: ScreenInfo, toward direction: Direction) -> ScreenInfo?
    /// Ordre de lecture : minX puis minY. Boucle. nil si un seul écran.
    func next(after screen: ScreenInfo) -> ScreenInfo?
    func previous(before screen: ScreenInfo) -> ScreenInfo?
    /// Bords de l'écran qui touchent un autre écran (le glisser y utilise une bande plus large).
    func innerEdges(of screen: ScreenInfo) -> Set<Direction>
    /// Écrans dans l'ordre de lecture (index de list_displays).
    var readingOrder: [ScreenInfo] { get }
}

enum ScreenGeometry {
    /// `primaryHeight` = hauteur du cadre de `NSScreen.screens[0]`.
    static func toAX(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect
    static func toCocoa(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect
    static func toAX(_ point: CGPoint, primaryHeight: CGFloat) -> CGPoint
    static func toCocoa(_ point: CGPoint, primaryHeight: CGFloat) -> CGPoint
}
```

Formules : `axRect.origin.y = primaryHeight - cocoaRect.maxY`, `axPoint.y = primaryHeight - cocoaPoint.y`.

### Zones, actions et résolveurs (Kernel/Domain, Snapping/Domain, SnapLayouts/Domain)

```swift
enum Zone: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds
    var id: String { rawValue }
    var localizedName: String            // « Moitié gauche », …
    var systemImage: String              // symbole SF représentatif
    /// Cadre de la zone dans `area` (cadre visible de l'écran, repère AX).
    /// `gap` : marge entre fenêtres ET avec les bords de l'écran. On inset
    /// `area` de gap/2, puis chaque zone de gap/2 sur chaque côté.
    func frame(in area: CGRect, gap: CGFloat) -> CGRect
    /// Zone qui complète l'espace restant (Snap Assist) : leftHalf -> rightHalf,
    /// topLeft -> bottomLeft… ; nil pour maximize et les tiers.
    var complement: Zone?
    var isThird: Bool
    /// Vrai si les deux zones se recouvrent (Snap Assist : complément déjà occupé).
    func overlaps(_ other: Zone) -> Bool
    static let defaultEnabled: Set<Zone>  // tout sauf les tiers
}

/// Disposition de la palette Snap Layouts : une zone par fenêtre, dans l'ordre de remplissage.
struct SnapLayout: Hashable, Sendable, Identifiable {
    let zones: [Zone]
    /// Dispositions de l'orientation dont toutes les zones sont activées (les tiers en paysage seulement).
    static func available(for orientation: ScreenOrientation, enabledZones: Set<Zone>) -> [SnapLayout]
}

struct KeyboardShortcut: Codable, Hashable, Sendable {
    var keyCode: UInt16            // code virtuel (gauche 123, droite 124, bas 125, haut 126…)
    var modifiers: UInt            // NSEvent.ModifierFlags.rawValue (⌃ 1<<18, ⌥ 1<<19, ⌘ 1<<20, ⇧ 1<<17)
    var displayString: String      // « ⌃⌥← »
    var carbonModifiers: UInt32    // controlKey 0x1000, optionKey 0x0800, cmdKey 0x0100, shiftKey 0x0200
}

enum SnapAction: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case left, right, up, down
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize, restore
    case nextDisplay, previousDisplay
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds
    var id: String { rawValue }
    var localizedName: String
    var defaultShortcut: KeyboardShortcut?   // ⌃⌥←→↑↓ ; quarts ⌃⌥U/I/J/K ; maximize ⌃⌥↩ ; restore ⌃⌥⌫ ;
                                             // nextDisplay ⌃⌥⌘→ ; previousDisplay ⌃⌥⌘← ; tiers : nil
    /// Zone placée directement (quarts, maximize, tiers) ; nil pour les flèches, restore et les écrans.
    var fixedZone: Zone?
    static var defaultShortcuts: [SnapAction: KeyboardShortcut]
}

struct DragZoneResolver: Sendable {
    struct Config: Sendable, Equatable {
        var edgeThreshold: CGFloat = 2        // distance à un bord extérieur (points) pour « toucher »
        var innerEdgeThreshold: CGFloat = 24  // largeur de la bande le long d'un bord partagé avec un autre écran
        var cornerLength: CGFloat = 120       // longueur de bord comptée comme coin
        var portraitTopEdgeMaximizes = false  // écran vertical : bord haut = plein écran au lieu de moitié haute
        var portraitSideEdgesEnabled = true   // écran vertical : bords gauche/droit actifs
        var enabledZones: Set<Zone> = Zone.defaultEnabled
    }
    var config: Config
    /// `pointer` et `screen.frame` en repère AX. Règles :
    /// - coins (près d'un bord vertical ET à moins de cornerLength d'un bord horizontal, ou l'inverse) -> quart ;
    /// - bord gauche / droit -> moitié (paysage toujours ; portrait si portraitSideEdgesEnabled) ;
    /// - bord haut -> maximize (paysage) ; topHalf ou maximize (portrait) ;
    /// - bord bas -> bottomHalf (portrait) ; nil (paysage).
    /// Une zone absente de enabledZones donne nil (pas de repli).
    /// `innerEdges` (`ScreenLayout.innerEdges(of:)`) : ces bords utilisent innerEdgeThreshold, sur toute leur longueur.
    func zone(forPointer pointer: CGPoint, on screen: ScreenInfo, innerEdges: Set<Direction> = []) -> Zone?
}

struct WindowSnapState: Sendable, Equatable {
    var zone: Zone
    var screenID: CGDirectDisplayID
}

enum SnapCommand: Sendable, Equatable {
    case place(Zone, on: ScreenInfo)
    case restore
    case none
}

struct KeyboardSnapResolver: Sendable {
    /// Portrait : ← / → coupent la moitié haute ou basse en quarts (Settings.portraitArrowsSplitHalves, true).
    var portraitArrowsSplitHalves = true
    /// `state` = nil si la fenêtre n'est pas collée. `screen` = écran courant de la fenêtre.
    func command(for action: SnapAction, state: WindowSnapState?, on screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand
}
```

Table de `KeyboardSnapResolver` (P = portrait, L = paysage, « voisin » = `layout.neighbor`,
« split » = `portraitArrowsSplitHalves`). Si `state.screenID != screen.id`, on considère la fenêtre comme non collée.

| action | état courant | résultat |
|---|---|---|
| left (P, split) | topHalf / bottomHalf | topLeft / bottomLeft |
| left (P, split) | topRight / bottomRight | topHalf / bottomHalf |
| left (P, split) | autres zones | comme en paysage (lignes ci-dessous) |
| left | non collée, maximize, topHalf, bottomHalf, tiers | leftHalf |
| left | rightHalf / topRight / bottomRight | leftHalf / topLeft / bottomLeft |
| left | leftHalf / topLeft / bottomLeft | voisin gauche : zone miroir (rightHalf / topRight / bottomRight) sur le voisin ; sans voisin : restore |
| right | symétrique de left | |
| up (L) | non collée, topHalf, bottomHalf, tiers | maximize |
| up (L) | leftHalf / rightHalf | topLeft / topRight |
| up (L) | bottomLeft / bottomRight | leftHalf / rightHalf |
| up (L) | maximize / topLeft / topRight | voisin haut : maximize / bottomLeft / bottomRight sur le voisin ; sinon none |
| up (P) | non collée, tiers | topHalf |
| up (P) | topHalf | maximize |
| up (P) | bottomHalf | voisin haut : bottomHalf sur le voisin ; sinon topHalf |
| up (P) | leftHalf / rightHalf | topLeft / topRight |
| up (P) | bottomLeft / bottomRight | split : topLeft / topRight ; sinon leftHalf / rightHalf |
| up (P) | maximize, topLeft, topRight | none |
| down (L) | non collée | none |
| down (L) | maximize / bottomLeft / bottomRight | voisin bas : maximize / topLeft / topRight sur le voisin ; sinon restore |
| down (L) | topHalf, bottomHalf, tiers | restore |
| down (L) | leftHalf / rightHalf | bottomLeft / bottomRight |
| down (L) | topLeft / topRight | leftHalf / rightHalf |
| down (P) | non collée, tiers | bottomHalf |
| down (P) | maximize | restore |
| down (P) | topHalf | voisin bas : topHalf sur le voisin ; sinon bottomHalf |
| down (P) | bottomHalf | restore |
| down (P) | leftHalf / rightHalf | bottomLeft / bottomRight |
| down (P) | topLeft / topRight | split : bottomLeft / bottomRight ; sinon leftHalf / rightHalf |
| down (P) | bottomLeft / bottomRight | restore |
| topLeft… bottomRight, maximize, tiers | tout | place(zone) sur l'écran courant ; si déjà cette zone sur cet écran : none |
| restore | collée / non collée | restore / none |
| nextDisplay / previousDisplay | collée | place(même zone, on: layout.next/previous) ; si pas d'autre écran : none |
| nextDisplay / previousDisplay | non collée | none (`SnapWithKeyboard` déplace la fenêtre proportionnellement) |

Les tiers (`leftThird`…) sont des zones « clavier seulement ».

### Snapping/Domain (registre) et SharedBorder/Domain

```swift
struct SnapRecord: Sendable, Equatable {
    var zone: Zone
    var screenID: CGDirectDisplayID
    var snappedFrame: CGRect     // cadre réellement obtenu après le snap (relu)
    var restoreFrame: CGRect     // cadre d'avant le premier snap (restauration)
}

struct SnapRegistry<Key: Hashable & Sendable>: Sendable {
    private(set) var records: [Key: SnapRecord]
    init()
    /// Enregistre un snap. Si la clé était déjà collée, conserve l'ancien restoreFrame.
    mutating func recordSnap(_ key: Key, zone: Zone, screenID: CGDirectDisplayID, snappedFrame: CGRect, currentFrame: CGRect)
    /// Met à jour le cadre collé (après un redimensionnement par bordure partagée).
    mutating func updateSnappedFrame(_ key: Key, to frame: CGRect)
    @discardableResult mutating func remove(_ key: Key) -> SnapRecord?
    func record(for key: Key) -> SnapRecord?
    func keys(on screenID: CGDirectDisplayID) -> [Key]
    /// Vrai si `frame` correspond encore au cadre collé (tolérance en points).
    func isStillSnapped(_ key: Key, frame: CGRect, tolerance: CGFloat) -> Bool
}

struct BorderWindow<Key: Hashable & Sendable>: Sendable, Identifiable {
    var id: Key
    var frame: CGRect
    var minSize: CGSize      // (0,0) si inconnue
}

struct BorderAdjustment<Key: Hashable & Sendable>: Sendable, Equatable {
    var id: Key
    var frame: CGRect
}

enum SharedBorderResolver {
    /// Une fenêtre collée est passée de `oldFrame` à `newFrame` (redimensionnement par l'utilisateur).
    /// Pour chaque bord qui a bougé, les voisines dont le bord opposé était à `gap` points de ce bord
    /// (à `tolerance` près, avec chevauchement sur l'axe perpendiculaire) sont redimensionnées pour
    /// le suivre en gardant l'écart `gap` (la marge des réglages). Les tailles
    /// minimales sont respectées : si une voisine ne peut pas rétrécir, le bord est limité et la fenêtre
    /// d'origine est aussi ramenée (son ajustement est alors inclus dans le résultat).
    /// Ne retourne que les cadres qui changent. Pur, sans effet de bord.
    static func adjustments<Key>(changed: Key, oldFrame: CGRect, newFrame: CGRect,
                                 neighbours: [BorderWindow<Key>], minSizeOfChanged: CGSize,
                                 tolerance: CGFloat, gap: CGFloat = 0) -> [BorderAdjustment<Key>]
}
```

### SnapAssist/Domain et ExternalControl/Domain

```swift
/// Ce qu'on sait d'une fenêtre, côté Accessibilité comme côté ScreenCaptureKit.
struct WindowDescriptor: Sendable, Equatable { let pid: pid_t; let frame: CGRect; let title: String? }

enum WindowMatcher {
    /// Même processus et même cadre (à `tolerance` près) ; à égalité, même titre, sinon le premier.
    static func bestMatch<ID>(for target: WindowDescriptor, among candidates: [(id: ID, window: WindowDescriptor)],
                              tolerance: CGFloat = 2) -> ID?
}

struct FractionRect: Codable, Sendable, Equatable {     // fractions 0…1 de la zone utile
    var x, y, width, height: Double
    var isValid: Bool { get }
    func frame(in area: CGRect, gap: CGFloat) -> CGRect // même règle d'écart que Zone
}
struct LayoutPlacement: Codable, Sendable, Equatable { var app: String; var title, display: String?; var zone: Zone?; var rect: FractionRect? }
struct LayoutSpec: Codable, Sendable, Equatable { var placements: [LayoutPlacement]; var launchApps: Bool? /* "launch_apps" */ }
struct LayoutWindow: Sendable, Equatable { var bundleIdentifier, appName, title: String? }
enum PlacementIssue: Error { case noTarget, ambiguousTarget, invalidRect, unknownDisplay(String), noWindow }
struct PlannedPlacement: Sendable, Equatable { var windowIndex: Int; var screen: ScreenInfo; var zone: Zone?; var frame: CGRect }

enum LayoutPlanner {
    static func matches(_ placement: LayoutPlacement, _ window: LayoutWindow) -> Bool
    /// Une fenêtre distincte par placement ; ceux qui ont un titre choisissent d'abord.
    static func assign(_ placements: [LayoutPlacement], to windows: [LayoutWindow]) -> [Int?]
    static func targetFrame(for placement: LayoutPlacement, on screen: ScreenInfo, gap: CGFloat) -> Result<(Zone?, CGRect), PlacementIssue>
    static func plan(_ spec: LayoutSpec, windows: [LayoutWindow], layout: ScreenLayout, gap: CGFloat) -> [Result<PlannedPlacement, PlacementIssue>]
}

extension ScreenLayout {
    /// nil, "", "primary", "main" ; "1", "2"… (readingOrder) ; "left"/"right"/"top"/"bottom" ; "id:<displayID>".
    func screen(matching selector: String?) -> ScreenInfo?
}
```

### Snapping/Domain : réglages et géométrie

```swift
/// Instantané des réglages lus par les use cases (relu à chaque événement).
struct SnapSettings: Sendable, Equatable {
    var dragSnapEnabled, restoreOnUnsnap: Bool
    var gap: CGFloat
    var enabledZones: Set<Zone>
    var dragResolver: DragZoneResolver.Config
    var portraitArrowsSplitHalves, sharedBorderEnabled, snapAssistEnabled, snapAssistPreviews: Bool
    var excludedBundleIdentifiers: Set<String>
    var keyboardResolver: KeyboardSnapResolver { get }
    func isExcluded(bundleIdentifier: String?) -> Bool
}

enum SnapGeometry {
    /// Taille d'avant le snap rendue pendant le glisser : le pointeur garde le même ratio horizontal
    /// dans la fenêtre et reste à 30 points au plus sous son bord haut.
    static func unsnappedFrame(restoring size: CGSize, from frame: CGRect, pointer: CGPoint) -> CGRect
    /// Même position relative dans la zone cible, réduite pour tenir, gardée dedans.
    static func proportionalFrame(_ frame: CGRect, from source: CGRect, to target: CGRect) -> CGRect
}

enum SharedBorderGeometry {   // SharedBorder/Domain
    static func shifted(_ frame: CGRect, old: CGRect, new: CGRect, tolerance: CGFloat) -> CGRect?
    static func corrected(_ frame: CGRect, requested: CGRect, actual: CGRect, gap: CGFloat) -> CGRect
    static func close(_ a: CGRect, _ b: CGRect) -> Bool
}
```

### Ports (Application)

```swift
// Kernel
@MainActor protocol WindowHandle: AnyObject, Hashable, Sendable {
    nonisolated var pid: pid_t { get }
    var frame: CGRect? { get }                                   // repère AX
    @discardableResult func setFrame(_ frame: CGRect) -> CGRect? // cadre réellement obtenu
    func raise()
    var title: String? { get }; var appName: String? { get }; var bundleIdentifier: String? { get }
    var isStandardWindow: Bool { get }; var isFullScreen: Bool { get }; var isResizable: Bool { get }
}
struct WindowRef: Hashable, Sendable { let window: any WindowHandle }   // clé de dictionnaire
@MainActor protocol WindowSystem: AnyObject {
    func frontmostWindow() -> (any WindowHandle)?
    func window(at point: CGPoint) -> (any WindowHandle)?
    func visibleStandardWindows() -> [any WindowHandle]
}
@MainActor protocol DisplayProvider: AnyObject { func currentLayout() -> ScreenLayout }
@MainActor protocol PointerState: AnyObject { var isLeftButtonPressed: Bool { get }; var location: CGPoint { get } }

// Snapping
@MainActor protocol SnapSettingsProvider: AnyObject { var snapSettings: SnapSettings { get } }   // Settings
@MainActor protocol SnapPreview: AnyObject { func show(frame: CGRect); func hide() }               // SnapPreviewPanel
@MainActor protocol SnapFollowUp: AnyObject {                                                     // OfferSnapAssist
    func windowSnapped(_ window: any WindowHandle, zone: Zone, screen: ScreenInfo)
    func cancel()
}
@MainActor protocol SnappedWindowResizeHandler: AnyObject {                                       // PropagateBorderResize
    func windowResized(_ window: any WindowHandle, from old: CGRect, to new: CGRect)
    func resizeEnded(_ window: any WindowHandle)
}

// SnapAssist
struct SnapAssistCandidate: Identifiable, Sendable, Equatable { let id: Int; let title, appName: String; let pid: pid_t }
@MainActor protocol SnapAssistPresenter: AnyObject {                                              // SnapAssistPanel
    func show(frame: CGRect, candidates: [SnapAssistCandidate], showsPreviews: Bool,
              onSelect: @escaping (Int) -> Void, onDismiss: @escaping () -> Void)
    func showThumbnail(_ image: CGImage, size: CGSize, for id: Int)
    func hide()
}
@MainActor protocol WindowThumbnails: AnyObject {                                                 // WindowThumbnailer
    func capture(_ targets: [(id: Int, window: WindowDescriptor)], maxSize: CGSize,
                 deliver: @escaping @MainActor (Int, CGImage, CGSize) -> Void) async
}
@MainActor protocol ScreenRecordingAccess: AnyObject {                                            // ScreenRecordingPermission
    var isGranted: Bool { get }; @discardableResult func request() -> Bool; func openSystemSettings()
}

// SnapLayouts
@MainActor protocol ZoomButtonLocator: AnyObject {                                                // AXZoomButtonLocator
    func zoomButton(at point: CGPoint) -> (window: any WindowHandle, buttonFrame: CGRect)?
}
@MainActor protocol SnapLayoutsPresenter: AnyObject {                                             // SnapLayoutsPanel
    var isVisible: Bool { get }
    func show(layouts: [SnapLayout], below button: CGRect, within area: CGRect,
              onSelect: @escaping (Zone) -> Void, onDismiss: @escaping () -> Void)
    func hide()
}

// ExternalControl, Settings, Onboarding
@MainActor protocol AppLauncher: AnyObject { func launch(_ apps: [String]) async }                // WorkspaceAppLauncher
@MainActor protocol LoginItem: AnyObject { var isEnabled: Bool { get }; func set(_ enabled: Bool) throws }  // LaunchAtLogin
@MainActor protocol AccessibilityTrust: AnyObject { var isTrusted: Bool { get }; func requestTrust() -> Bool }  // AXAccessibilityTrust

// ShortcutImport
@MainActor protocol ShortcutSourceReader: AnyObject { func read(_ source: ShortcutSource) -> ShortcutSourceData? }  // SystemShortcutSourceReader ; nil : app non utilisée
@MainActor protocol ShortcutsStore: AnyObject { var shortcuts: [SnapAction: KeyboardShortcut] { get set } }        // Settings
```

### ShortcutImport/Domain

```swift
enum ShortcutSource: String, CaseIterable { case rectangle, magnet, aerospace
    var name: String                      // nom du produit, jamais traduit
    var preferencesDomain: String?        // com.knollsoft.Rectangle, com.crowdcafe.windowmagnet ; nil pour AeroSpace
    var configurationPaths: [String]      // AeroSpace : .aerospace.toml, .config/aerospace/aerospace.toml (relatifs au dossier personnel)
    func parse(_ data: ShortcutSourceData) -> ImportedShortcuts
}
enum ShortcutSourceData { case preferences([String: Any]); case text(String) }
struct ImportedShortcuts: Equatable, Sendable {
    var shortcuts: [SnapAction: KeyboardShortcut]   // actions qui ont un équivalent dans la source
    var cleared: Set<SnapAction>                    // actions laissées sans raccourci dans la source
    var unmapped: [String]                          // raccourcis de la source sans équivalent (nommés comme elle)
    /// Importés remplacent les leurs ; `cleared` perdent le leur ; une autre action qui utilisait un raccourci
    /// importé le perd (un raccourci, une action) ; les actions inconnues de la source gardent le leur.
    func merged(into current: [SnapAction: KeyboardShortcut]) -> [SnapAction: KeyboardShortcut]
}
/// Dictionnaire MASShortcut `{keyCode, modifierFlags}` (Rectangle, Magnet) : `{}` = retiré par l'utilisateur,
/// clé absente = défaut de l'app, sans modificateur ou malformé = inutilisable.
enum PreferenceShortcut { case shortcut(KeyboardShortcut), removed, absent, unusable; init(_ raw: Any?) }
enum RectangleShortcuts { static func parse(_ preferences: [String: Any]) -> ImportedShortcuts }  // défauts selon alternateDefaultShortcuts
enum MagnetShortcuts { static func parse(_ preferences: [String: Any]) -> ImportedShortcuts }     // défauts d'usine ; écrans non lus
enum AeroSpaceShortcuts {                                                                           // [mode.main.binding] seulement
    static func parse(_ toml: String) -> ImportedShortcuts
    static func mainBindings(in toml: String) -> [Binding]            // clé -> commandes (chaîne ou tableau)
    static func shortcut(forKey key: String) -> KeyboardShortcut?     // "alt-shift-h" (QWERTY) ; nil sans modificateur
    static func action(for commands: [String]) -> SnapAction?         // move ←→↑↓, fullscreen, move-node-to-monitor left/prev/right/next
}
```

Tous les cadres qui traversent un port sont en repère AX.

### Use cases (Application)

Un type `@MainActor final class` par cas, dépendances reçues à l'`init`, méthode `execute`.

`SnapStore` (Snapping) : fenêtres collées de la session (`SnapRegistry<WindowRef>`, tolérance 4 points).
`currentRecord(for:frame:)` rend l'enregistrement d'une fenêtre encore à sa place et oublie les autres ;
`snappedWindows(on:excluding:)` fait de même pour un écran.

`ManageableWindows` (Snapping) : fenêtre standard, redimensionnable, pas en plein écran natif, app non exclue ;
`all()` liste les fenêtres visibles gérables.

`PlaceWindowInZone.execute(window, zone:, on:)` : `zone.frame(in: screen.visibleFrame, gap:)`, `setFrame`, relit,
enregistre (le `restoreFrame` d'une fenêtre déjà collée est conservé). Ni premier plan ni Snap Assist.

`SnapWindowToZone.execute(window, zone:, on:)` : snap choisi par l'utilisateur (clavier, palette) :
`followUp.cancel()`, place, `raise()`, `followUp.windowSnapped`.

`SnapWithKeyboard.execute(action)` : retire l'offre Snap Assist en cours, fenêtre active,
`KeyboardSnapResolver`, applique la commande ; un `.place` vers une zone absente de `enabledZones` est ignoré
(pas de repli) ; `.restore` rend `restoreFrame` ; `nextDisplay/previousDisplay` sur une fenêtre non collée :
`SnapGeometry.proportionalFrame` vers l'écran suivant / précédent.

`DragSnapSession` : `mouseDown(at:)`, `mouseDragged(at:)`, `mouseUp(at:)`, `cancel()`.
- `mouseDown` : fenêtre sous le pointeur si gérable ; mémorise son cadre et si elle est collée.
- `mouseDragged` : relit le cadre (au plus toutes les 16 ms).
  - Si la **taille** a changé → redimensionnement : `SnappedWindowResizeHandler.windowResized` si la fenêtre est collée.
  - Si la **position** a changé : fenêtre collée et `restoreOnUnsnap` → `SnapGeometry.unsnappedFrame`, une seule
    fois, et l'enregistrement est retiré. Puis, si `dragSnapEnabled`, `DragZoneResolver` sur l'écran du pointeur
    → `SnapPreview.show/hide` (zones désactivées ignorées).
- `mouseUp` : zone en attente → `PlaceWindowInZone` puis `SnapFollowUp.windowSnapped` ; après un redimensionnement →
  `resizeEnded`. Une fenêtre collée lâchée ailleurs qu'à sa place sort du registre.
- Un chien de garde termine le glisser si le relâchement n'arrive jamais (lâcher sur une de nos fenêtres).

`ReapplySnapsAfterDisplayChange.execute()` : chaque fenêtre du registre retrouve le cadre standard de sa zone
sur son écran (ou sur le premier si l'écran a disparu) ; les tailles modifiées par la bordure partagée sont perdues.

`PropagateBorderResize` (SharedBorder, port `SnappedWindowResizeHandler`) : si `sharedBorderEnabled`, passe à
`SharedBorderResolver` les fenêtres collées du même écran et la marge ; les fenêtres dont le bord du même côté
était aligné sur le bord tiré suivent aussi (`SharedBorderGeometry.shifted`). Une voisine qui refuse la taille
ramène la fenêtre tirée sur son bord réel (`corrected`).

`OfferSnapAssist` (SnapAssist, port `SnapFollowUp`) : après un snap sur une zone qui a un `complement` activé
(et si `snapAssistEnabled`), affiche les autres fenêtres gérables dans le cadre du complément. Rien n'est proposé
si une fenêtre collée de cet écran occupe déjà le complément (`Zone.overlaps`). Un choix place la fenêtre
(`PlaceWindowInZone`) et la passe au premier plan. Avec `snapAssistPreviews` et l'autorisation d'enregistrement
de l'écran, les miniatures arrivent une à une (`WindowThumbnails`). L'API d'Accessibilité ne donne pas de
`CGWindowID` public : chaque fenêtre est associée à sa fenêtre ScreenCaptureKit par processus, cadre et titre
(`WindowMatcher`). Une fenêtre non associée garde son icône.

`ShowSnapLayouts.execute()` (SnapLayouts) : appelé quand le pointeur se pose (300 ms) ; si le bouton n'est pas
pressé et que le pointeur est sur le bouton vert d'une fenêtre gérable, affiche `SnapLayout.available(...)` pour
l'écran de la fenêtre ; un clic sur une zone → `SnapWindowToZone`.

`ListDisplays`, `ListWindows`, `ApplyLayout` (ExternalControl) : voir « Commandes externes et MCP ».

`DetectShortcutSources.execute()` (ShortcutImport) : les sources dont `ShortcutSourceReader.read` rend quelque chose,
dans l'ordre de `ShortcutSource.allCases`. `ImportShortcuts.execute(from:)` : lit, `parse`, puis
`store.shortcuts = imported.merged(into: store.shortcuts)` ; rend `ImportedShortcuts` (nil si la source n'est pas
utilisée : rien ne change) et consigne les raccourcis sans équivalent (catégorie `shortcut-import`). L'autre app n'est
jamais modifiée.

### Infrastructure et Presentation

```swift
@MainActor final class AXWindow: WindowHandle {     // Hashable via CFEqual/CFHash de l'élément
    let element: AXUIElement
    var isMinimized: Bool { get }
    /// setFrame applique taille puis position puis taille (certaines apps ajustent) et relit le cadre.
}
@MainActor enum AXWindowFinder {
    static func frontmostWindow() -> AXWindow?
    static func window(at point: CGPoint) -> AXWindow?
    static func visibleStandardWindows() -> [AXWindow]
    /// Bouton vert sous le pointeur (sous-rôle AXZoomButton ou AXFullScreenButton) : sa fenêtre et son cadre.
    static func zoomButton(at point: CGPoint) -> (window: AXWindow, buttonFrame: CGRect)?
}
@MainActor final class DragMonitor {                // onMouseDown / onMouseDragged / onMouseUp en repère AX ; start(), stop()
}
@MainActor final class HotkeyManager {              // onAction ; register(_ shortcuts:), unregisterAll()
}
```

Chaque `AXUIElementCreateApplication` reçoit `AXUIElementSetMessagingTimeout(_, 0.25)` : une app qui ne répond
pas ne bloque jamais Fenestra.

Les panneaux (`SnapPreviewPanel`, `SnapAssistPanel`, `SnapLayoutsPanel`) reçoivent des cadres AX et les
convertissent avec `ScreenGeometry.toCocoa(_:)`. `SnapAssistPanel` lit l'icône de l'app à partir du `pid`.
Les vues SwiftUI reçoivent ce qu'elles utilisent à l'`init` (`Settings`, `AccessibilityPermission`, ports
`LoginItem` et `ScreenRecordingAccess`, closure d'action) : aucune ne connaît `AppController`.

Une Presentation n'utilise pas la Presentation d'une autre feature : `ShortcutImportView` (ShortcutImport) est
donc injectée par `FenestraApp` dans `SettingsView` et `OnboardingView` via un paramètre générique
`ShortcutImport: View` (nil quand `DetectShortcutSources` ne trouve rien, et le bloc n'apparaît pas).
`SystemShortcutSourceReader` lit les préférences d'une autre app par `UserDefaults.persistentDomain(forName:)`,
puis dans son conteneur sandbox (`~/Library/Containers/<domaine>/Data/Library/Preferences/`, cas de Magnet,
App Store), et les fichiers de configuration dans le dossier personnel (`.config/…` suit `$XDG_CONFIG_HOME`).

### Settings

```swift
@MainActor @Observable final class Settings: SnapSettingsProvider, ShortcutsStore {
    static let shared: Settings
    var isEnabled: Bool                      // interrupteur général (barre des menus), true
    var dragSnapEnabled: Bool                // glisser vers un bord, true
    var restoreOnUnsnap: Bool                // restauration au décollage, true
    var gap: Double                          // 0 par défaut
    var cornerLength: Double                 // 120
    var innerEdgeThreshold: Double           // 24 ; bande de déclenchement entre deux écrans
    var enabledZones: Set<Zone>              // Zone.defaultEnabled
    var portraitTopEdgeMaximizes: Bool       // false
    var portraitSideEdgesEnabled: Bool       // true
    var portraitArrowsSplitHalves: Bool      // true ; voir KeyboardSnapResolver
    var sharedBorderEnabled: Bool            // bordure partagée, true
    var snapAssistEnabled: Bool              // Snap Assist, true
    var snapAssistPreviews: Bool             // Snap Assist, false ; demande l'enregistrement de l'écran
    var snapLayoutsEnabled: Bool             // true ; palette au survol du bouton vert
    var excludedBundleIdentifiers: [String]
    var externalControlEnabled: Bool         // true ; socket de commandes pour l'outil fenestra (MCP)
    var shortcuts: [SnapAction: KeyboardShortcut]   // seules les actions assignées ; défaut SnapAction.defaultShortcuts
    var hasCompletedOnboarding: Bool
    func resetShortcuts()
    var snapSettings: SnapSettings { get }   // instantané pour les use cases
}
```

Persistance : chaque propriété est écrite dans `UserDefaults.standard` (JSON pour les
types composés) dans son `didSet`, et relue dans `init`. Un réglage lu par un use case passe aussi dans
`SnapSettings`.

### App (assemblage)

`AppController` (@MainActor, @Observable) construit les adaptateurs (`AXWindowSystem`, `NSScreenDisplays`,
`SystemPointer`, panneaux…), les use cases, et les branche : `DragMonitor` → `DragSnapSession`,
`HotkeyManager` et le menu → `SnapWithKeyboard`, `ZoomButtonHoverMonitor` → `ShowSnapLayouts`,
`ScreenWatcher` → `ReapplySnapsAfterDisplayChange`, `ControlServer` → `CommandDispatcher`.
Il démarre les moniteurs quand `permission.isGranted && settings.isEnabled`, les arrête
sinon, et ré-enregistre les raccourcis quand `settings.shortcuts` change. Les callbacks souris ne sont
branchés que si `dragSnapEnabled`, `restoreOnUnsnap` ou `sharedBorderEnabled` est actif (la souris sert aux
trois) ; la palette ne démarre que si `snapLayoutsEnabled`. Le socket suit `externalControlEnabled`,
indépendamment du reste (l'outil reçoit alors une erreur claire plutôt que rien).

## Commandes externes et MCP

L'app écoute sur un socket Unix créé sous `umask(0o077)` (accessible au seul propriétaire). Requête : une ligne JSON
`{"command": "...", "arguments": {...}}` ; réponse : `{"ok": true, "result": ...}` ou
`{"ok": false, "error": "..."}`. Commandes : `list_displays`, `list_windows`, `apply_layout`.

`apply_layout` reçoit un `LayoutSpec` : une liste de placements `{app, title?, display?, zone | rect}`
(rect en fractions 0…1 de la zone utile de l'écran) et `launch_apps`. `LayoutPlanner` (pur, testé)
attribue une fenêtre distincte à chaque placement — ceux qui ont un titre choisissent d'abord — et
calcule les cadres avec la même règle d'écart que `Zone`. Les placements en zone passent par
`PlaceWindowInZone` (la restauration fonctionne) ; les rect sortent la fenêtre du registre. Avec `launch_apps`,
`AppLauncher` ouvre les apps sans fenêtre, puis `ApplyLayout` attend leurs fenêtres (10 s au plus).
`CommandDispatcher` décode la requête, refuse si l'Accessibilité manque ou si Fenestra est en pause, et appelle
`ListDisplays`, `ListWindows` ou `ApplyLayout`.

L'outil `fenestra` (pas de dépendance externe) relaie ces commandes : en ligne de commande, ou comme
serveur MCP stdio (`fenestra mcp`, JSON-RPC écrit à la main : initialize, ping, tools/list, tools/call).
Il lance l'app en arrière-plan si le socket ne répond pas. Le socket n'est ouvert que si
`Settings.externalControlEnabled` (onglet Agents des réglages, qui donne aussi la config MCP à copier).
