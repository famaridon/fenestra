# Fenestra — Architecture et contrat entre modules

Ce document fixe le découpage du code et les API partagées. Chaque module est
développé indépendamment ; le respect strict des signatures ci-dessous est ce
qui permet l'assemblage final.

## Règles générales

- Swift 6, mode strict de concurrence. Tout ce qui touche AppKit, l'Accessibilité
  ou les événements souris est `@MainActor`.
- **Un seul repère de coordonnées dans tout le code métier : le repère « AX »**
  (origine en haut à gauche de l'écran principal, `y` vers le bas, en points).
  C'est le repère de `AXUIElement` et de `CGEvent`. `NSScreen` et
  `NSEvent.mouseLocation` utilisent l'origine en bas à gauche : la conversion
  se fait **uniquement** dans `ScreenGeometry`.
- Pas d'API privée (NF4). Pas de dépendance externe (pas de SwiftPM tiers).
- Textes d'interface en **français**. Identifiants de code en anglais.
- Pas de `print` de debug dans le code livré ; utiliser `os.Logger`
  (`Logger(subsystem: "com.florentamaridon.Fenestra", category: "<module>")`).

## Arborescence

```
Sources/Fenestra/
  FenestraApp.swift                    — @main, scènes SwiftUI (MenuBarExtra, Settings, fenêtre d'accueil)
  App/
    AppDelegate.swift                  — NSApplicationDelegate (fenêtre d'accueil au 1er lancement)
    AppController.swift                — point d'assemblage : possède Settings, DragMonitor, HotkeyManager, SnapController…
    ScreenInfo+NSScreen.swift          — construction de ScreenInfo / ScreenLayout depuis NSScreen
  Core/                                — Swift pur (Foundation + CoreGraphics), 100 % testable
    Geometry/ScreenGeometry.swift      — conversion Cocoa <-> AX
    Geometry/ScreenInfo.swift          — modèle d'écran, orientation
    Geometry/ScreenLayout.swift        — ensemble d'écrans : voisinage, écran contenant un point/une fenêtre
    Zones/Zone.swift                   — enum Zone + calcul de cadre
    Zones/SnapAction.swift             — actions clavier + raccourcis par défaut
    Zones/KeyboardShortcut.swift       — raccourci clavier (valeur pure)
    Zones/DragZoneResolver.swift       — pointeur près d'un bord -> Zone ?
    Zones/KeyboardSnapResolver.swift   — action clavier + état -> commande
    Snap/SnapRegistry.swift            — mémoire des fenêtres collées (restauration F2)
    Snap/SharedBorderResolver.swift    — calcul de la bordure partagée (F5)
  Accessibility/
    AXWindow.swift                     — enveloppe d'une fenêtre AXUIElement
    AXWindowFinder.swift               — fenêtre sous le pointeur, fenêtre active, toutes les fenêtres
  Input/
    DragMonitor.swift                  — événements souris globaux (repère AX)
    HotkeyManager.swift                — raccourcis globaux (Carbon RegisterEventHotKey)
  Settings/
    Settings.swift                     — modèle @Observable persisté dans UserDefaults
    LaunchAtLogin.swift                — SMAppService
  UI/
    MenuBarView.swift                  — contenu du MenuBarExtra
    OnboardingView.swift               — accueil / autorisation Accessibilité
    SettingsView.swift                 — réglages (onglets)
    ShortcutRecorderView.swift         — saisie d'un raccourci
    ExcludedAppsView.swift             — applications exclues
    SnapPreviewPanel.swift             — NSPanel d'aperçu translucide
    SnapAssistPanel.swift              — panneau Snap Assist (F8)
  Controllers/
    SnapController.swift               — orchestration glisser + clavier + restauration
    SharedBorderController.swift       — F5 : propage un redimensionnement aux voisines
    ScreenWatcher.swift                — F7 : réagit aux changements d'écrans
    SnapAssistController.swift         — F8
Tests/FenestraTests/                   — Swift Testing, surtout sur Core/
docs/                                  — site Astro Starlight (documentation utilisateur et développeur)
```

## Contrat des types partagés

### Core/Geometry

```swift
enum ScreenOrientation: String, Sendable, Codable { case landscape, portrait }

struct ScreenInfo: Hashable, Sendable, Identifiable {
    let id: CGDirectDisplayID
    let frame: CGRect          // cadre complet, repère AX
    let visibleFrame: CGRect   // sans barre des menus ni Dock, repère AX
    var orientation: ScreenOrientation { frame.height > frame.width ? .portrait : .landscape }
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

### Core/Zones

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
    static let defaultEnabled: Set<Zone>  // tout sauf les tiers
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
    static var defaultShortcuts: [SnapAction: KeyboardShortcut]
}

struct DragZoneResolver: Sendable {
    struct Config: Sendable, Equatable {
        var edgeThreshold: CGFloat = 2        // distance au bord (points) pour « toucher »
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
    func zone(forPointer pointer: CGPoint, on screen: ScreenInfo) -> Zone?
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
    /// `state` = nil si la fenêtre n'est pas collée. `screen` = écran courant de la fenêtre.
    func command(for action: SnapAction, state: WindowSnapState?, on screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand
}
```

Table de `KeyboardSnapResolver` (P = portrait, L = paysage, « voisin » = `layout.neighbor`).
Si `state.screenID != screen.id`, on considère la fenêtre comme non collée.

| action | état courant | résultat |
|---|---|---|
| left | non collée, maximize, topHalf, bottomHalf, tiers | leftHalf |
| left | rightHalf / topRight / bottomRight | leftHalf / topLeft / bottomLeft |
| left | leftHalf / topLeft / bottomLeft | voisin gauche : zone miroir (rightHalf / topRight / bottomRight) sur le voisin ; sans voisin : restore |
| right | symétrique de left | |
| up (L) | non collée, topHalf, bottomHalf, tiers | maximize |
| up (L) | leftHalf / rightHalf | topLeft / topRight |
| up (L) | bottomLeft / bottomRight | leftHalf / rightHalf |
| up (L) | maximize, topLeft, topRight | none |
| up (P) | non collée, tiers | topHalf |
| up (P) | topHalf | maximize |
| up (P) | bottomHalf | voisin haut : bottomHalf sur le voisin ; sinon topHalf |
| up (P) | leftHalf / rightHalf | topLeft / topRight |
| up (P) | bottomLeft / bottomRight | leftHalf / rightHalf |
| up (P) | maximize, topLeft, topRight | none |
| down (L) | non collée | none |
| down (L) | maximize, bottomLeft, bottomRight, topHalf, bottomHalf, tiers | restore |
| down (L) | leftHalf / rightHalf | bottomLeft / bottomRight |
| down (L) | topLeft / topRight | leftHalf / rightHalf |
| down (P) | non collée, tiers | bottomHalf |
| down (P) | maximize | restore |
| down (P) | topHalf | voisin bas : topHalf sur le voisin ; sinon bottomHalf |
| down (P) | bottomHalf | restore |
| down (P) | leftHalf / rightHalf | bottomLeft / bottomRight |
| down (P) | topLeft / topRight | leftHalf / rightHalf |
| down (P) | bottomLeft / bottomRight | restore |
| topLeft… bottomRight, maximize, tiers | tout | place(zone) sur l'écran courant ; si déjà cette zone sur cet écran : none |
| restore | collée / non collée | restore / none |
| nextDisplay / previousDisplay | collée | place(même zone, on: layout.next/previous) ; si pas d'autre écran : none |
| nextDisplay / previousDisplay | non collée | none (le contrôleur déplace la fenêtre proportionnellement) |

Les tiers (`leftThird`…) sont des zones « clavier seulement ».

### Core/Snap

```swift
struct SnapRecord: Sendable, Equatable {
    var zone: Zone
    var screenID: CGDirectDisplayID
    var snappedFrame: CGRect     // cadre réellement obtenu après le snap (relu)
    var restoreFrame: CGRect     // cadre d'avant le premier snap (F2)
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
    /// Pour chaque bord qui a bougé, les voisines qui partageaient ce bord (à `tolerance` près, avec
    /// chevauchement sur l'axe perpendiculaire) sont redimensionnées pour rester jointives. Les tailles
    /// minimales sont respectées : si une voisine ne peut pas rétrécir, le bord est limité et la fenêtre
    /// d'origine est aussi ramenée (son ajustement est alors inclus dans le résultat).
    /// Ne retourne que les cadres qui changent. Pur, sans effet de bord.
    static func adjustments<Key>(changed: Key, oldFrame: CGRect, newFrame: CGRect,
                                 neighbours: [BorderWindow<Key>], minSizeOfChanged: CGSize,
                                 tolerance: CGFloat) -> [BorderAdjustment<Key>]
}
```

### Accessibility

```swift
/// Enveloppe d'une fenêtre AXUIElement. Hashable via CFEqual/CFHash de l'élément.
@MainActor final class AXWindow: Hashable {
    let element: AXUIElement
    let pid: pid_t
    init(element: AXUIElement, pid: pid_t)
    var frame: CGRect? { get }                      // repère AX
    /// Applique taille puis position puis taille (certaines apps ajustent). Retourne le cadre relu (nil si échec).
    @discardableResult func setFrame(_ frame: CGRect) -> CGRect?
    var title: String? { get }
    var isMinimized: Bool { get }
    var isFullScreen: Bool { get }                   // kAXFullScreenAttribute
    var isStandardWindow: Bool { get }               // rôle AXWindow et sous-rôle AXStandardWindow
    var isResizable: Bool { get }                    // kAXSizeAttribute settable
    var bundleIdentifier: String? { get }            // via NSRunningApplication(processIdentifier:)
    var appName: String? { get }
    var appIcon: NSImage? { get }
    func raise()                                     // kAXRaiseAction + activation de l'app
    nonisolated static func == (lhs: AXWindow, rhs: AXWindow) -> Bool
    nonisolated func hash(into hasher: inout Hasher)
}

@MainActor enum AXWindowFinder {
    static func frontmostWindow() -> AXWindow?
    static func window(at point: CGPoint) -> AXWindow?            // repère AX ; AXUIElementCopyElementAtPosition puis attribut window
    static func visibleStandardWindows() -> [AXWindow]            // toutes apps `.regular`, fenêtres standard non minimisées
}
```

Chaque `AXUIElementCreateApplication` reçoit `AXUIElementSetMessagingTimeout(_, 0.25)` (NF3).

### Input

```swift
@MainActor final class DragMonitor {
    /// Points en repère AX.
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp: ((CGPoint) -> Void)?
    var isRunning: Bool { get }
    func start()
    func stop()
}

@MainActor final class HotkeyManager {
    var onAction: ((SnapAction) -> Void)?
    /// Remplace tous les raccourcis enregistrés. Un raccourci qui échoue est ignoré (journalisé).
    func register(_ shortcuts: [SnapAction: KeyboardShortcut])
    func unregisterAll()
}
```

### Settings

```swift
@MainActor @Observable final class Settings {
    static let shared: Settings
    var isEnabled: Bool                      // interrupteur général (barre des menus), true
    var dragSnapEnabled: Bool                // F1, true
    var restoreOnUnsnap: Bool                // F2, true
    var gap: Double                          // 0 par défaut
    var cornerLength: Double                 // 120
    var enabledZones: Set<Zone>              // Zone.defaultEnabled
    var portraitTopEdgeMaximizes: Bool       // false
    var portraitSideEdgesEnabled: Bool       // true
    var sharedBorderEnabled: Bool            // F5, true
    var snapAssistEnabled: Bool              // F8, true
    var excludedBundleIdentifiers: [String]
    var shortcuts: [SnapAction: KeyboardShortcut]   // seules les actions assignées ; défaut SnapAction.defaultShortcuts
    var hasCompletedOnboarding: Bool
    func resetShortcuts()
    func isExcluded(bundleIdentifier: String?) -> Bool
    var dragResolverConfig: DragZoneResolver.Config { get }
}

@MainActor enum LaunchAtLogin {
    static var isEnabled: Bool { get }
    static func set(_ enabled: Bool) throws   // SMAppService.mainApp
}
```

Persistance : chaque propriété est écrite dans `UserDefaults.standard` (JSON pour les
types composés) dans son `didSet`, et relue dans `init`.

### UI

```swift
@MainActor final class SnapPreviewPanel {
    init()
    /// `frame` en repère **Cocoa** (la conversion est faite par l'appelant).
    func show(frame: CGRect)
    func hide()
}

struct SnapAssistCandidate: Identifiable { let id: Int; let title: String; let appName: String; let icon: NSImage? }

@MainActor final class SnapAssistPanel {
    init()
    /// `frame` en repère Cocoa. `onSelect(id)` quand l'utilisateur clique une fenêtre ; `onDismiss` sur Échap / clic ailleurs.
    func show(frame: CGRect, candidates: [SnapAssistCandidate], onSelect: @escaping (Int) -> Void, onDismiss: @escaping () -> Void)
    func hide()
}

struct MenuBarView: View        // reçoit AppController via @Environment(AppController.self)
struct SettingsView: View       // idem
struct OnboardingView: View     // idem
struct ShortcutRecorderView: View   // init(shortcut: Binding<KeyboardShortcut?>)
struct ExcludedAppsView: View
```

### Controllers (assemblage)

`AppController` (@MainActor, @Observable) possède : `settings`, `permission`,
`dragMonitor`, `hotkeys`, `snapController`, `screenWatcher`, `snapAssist`.
Il démarre les moniteurs quand `permission.isGranted && settings.isEnabled`, les arrête
sinon, et ré-enregistre les raccourcis quand `settings.shortcuts` change.
Il expose `func perform(_ action: SnapAction)` pour les menus.

`SnapController` :
- `mouseDown(at:)` : repère la fenêtre sous le pointeur (`AXWindowFinder.window(at:)`), mémorise son cadre et
  si elle est collée (`registry.isStillSnapped`). Ignore les apps exclues et les fenêtres non standard.
- `mouseDragged(at:)` : relit le cadre de la fenêtre (au plus toutes les 16 ms).
  - Si la **taille** a changé → c'est un redimensionnement : délègue à `SharedBorderController` si la fenêtre est collée.
  - Si la **position** a changé (déplacement) : si la fenêtre était collée et `restoreOnUnsnap`, lui rend sa taille
    d'origine une seule fois (origine recalculée pour garder le pointeur au même ratio dans la barre de titre),
    puis retire l'enregistrement. Ensuite `DragZoneResolver` sur l'écran contenant le pointeur → affiche/cache l'aperçu.
- `mouseUp(at:)` : si une zone est affichée, applique `place(zone, on: screen)` ; cache l'aperçu ; déclenche Snap Assist.
- `perform(_ action: SnapAction)` : fenêtre active, `KeyboardSnapResolver`, applique la commande ;
  `nextDisplay/previousDisplay` sur fenêtre non collée : déplacement proportionnel vers l'écran voisin.
- `place(window, zone, screen)` : calcule `zone.frame(in: screen.visibleFrame, gap:)`, `setFrame`, relit, enregistre.
- `restore(window)` : `setFrame(record.restoreFrame)` puis `registry.remove`.

`ScreenWatcher` : sur `NSApplication.didChangeScreenParametersNotification`, pour chaque fenêtre du registre,
réapplique sa zone sur son écran (ou sur l'écran principal si l'écran a disparu).

`SnapAssistController` : après un snap par glisser sur une zone qui a un `complement`, affiche
`SnapAssistPanel` dans le cadre du complément, listant les autres fenêtres standard (icône + titre).
Un clic place la fenêtre choisie dans le complément. Échap ou clic ailleurs ferme.
