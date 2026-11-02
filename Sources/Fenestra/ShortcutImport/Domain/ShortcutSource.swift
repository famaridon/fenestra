import Foundation

/// A window manager whose keyboard shortcuts Fenestra can take over.
enum ShortcutSource: String, CaseIterable, Sendable, Identifiable, Hashable {
    case rectangle, magnet, aerospace

    var id: String { rawValue }

    /// Product name, never translated.
    var name: String {
        switch self {
        case .rectangle: "Rectangle"
        case .magnet: "Magnet"
        case .aerospace: "AeroSpace"
        }
    }

    /// `UserDefaults` domain holding the app's preferences; nil for an app configured by a file.
    var preferencesDomain: String? {
        switch self {
        case .rectangle: RectangleShortcuts.domain
        case .magnet: MagnetShortcuts.domain
        case .aerospace: nil
        }
    }

    /// Configuration files, relative to the home folder, in the order the app itself looks for them.
    var configurationPaths: [String] {
        switch self {
        case .rectangle, .magnet: []
        case .aerospace: AeroSpaceShortcuts.configurationPaths
        }
    }

    /// Reads the raw data of the source (preferences or configuration file) into shortcuts.
    func parse(_ data: ShortcutSourceData) -> ImportedShortcuts {
        switch (self, data) {
        case (.rectangle, .preferences(let preferences)): RectangleShortcuts.parse(preferences)
        case (.magnet, .preferences(let preferences)): MagnetShortcuts.parse(preferences)
        case (.aerospace, .text(let text)): AeroSpaceShortcuts.parse(text)
        default: ImportedShortcuts()
        }
    }
}

/// What a source leaves on the Mac: a preferences domain (property list values) or a text file.
enum ShortcutSourceData {
    case preferences([String: Any])
    case text(String)
}

/// Shortcuts read from a source, before they are merged into the settings.
struct ImportedShortcuts: Equatable, Sendable {
    /// One shortcut per Fenestra action that has an equivalent in the source.
    var shortcuts: [SnapAction: KeyboardShortcut] = [:]
    /// Actions the user deliberately left without a shortcut in the source.
    var cleared: Set<SnapAction> = []
    /// Bindings of the source with no equivalent in Fenestra, named as the source names them.
    var unmapped: [String] = []

    /// The settings after the import: imported shortcuts replace those of their actions, cleared actions lose
    /// theirs, and any other action that used a shortcut now taken by an import loses it too (a shortcut
    /// triggers one action). Actions the source knows nothing about keep their shortcut.
    func merged(into current: [SnapAction: KeyboardShortcut]) -> [SnapAction: KeyboardShortcut] {
        var result = current
        for action in cleared { result[action] = nil }
        let taken = Set(shortcuts.values)
        for (action, shortcut) in result where shortcuts[action] == nil && taken.contains(shortcut) {
            result[action] = nil
        }
        for (action, shortcut) in shortcuts { result[action] = shortcut }
        return result
    }
}

/// A shortcut as the MASShortcut library stores it in preferences (Rectangle, Magnet):
/// `{keyCode, modifierFlags}` with `NSEvent.ModifierFlags`; an empty dictionary means "explicitly none".
enum PreferenceShortcut: Equatable {
    case shortcut(KeyboardShortcut)
    /// The user removed the shortcut.
    case removed
    /// The preference was never written: the app uses its default.
    case absent
    /// Present but not usable as a global shortcut (malformed, or without any modifier).
    case unusable

    init(_ raw: Any?) {
        guard let dictionary = raw as? [String: Any] else {
            self = raw == nil ? .absent : .unusable
            return
        }
        if dictionary.isEmpty {
            self = .removed
            return
        }
        guard let keyCode = (dictionary["keyCode"] as? NSNumber)?.intValue, keyCode >= 0, keyCode <= UInt16.max,
              let flags = (dictionary["modifierFlags"] as? NSNumber)?.uintValue else {
            self = .unusable
            return
        }
        let shortcut = KeyboardShortcut(keyCode: UInt16(keyCode), modifiers: UInt(flags))
        self = shortcut.modifiers == 0 ? .unusable : .shortcut(shortcut)
    }
}

extension ImportedShortcuts {
    /// Builds the result of a preferences-based source: `mapping` gives the preference key of each action,
    /// `defaults` the shortcut the app uses when the key was never written. Keys of `preferences` that hold a
    /// shortcut but map to no action are reported as unmapped, under `name(key)`.
    static func fromPreferences(_ preferences: [String: Any], mapping: [(key: String, action: SnapAction)],
                                defaults: [SnapAction: KeyboardShortcut], unmappedKey: (String) -> String?)
        -> ImportedShortcuts {
        var result = ImportedShortcuts()
        for (key, action) in mapping {
            switch PreferenceShortcut(preferences[key]) {
            case .shortcut(let shortcut): result.shortcuts[action] = shortcut
            case .removed: result.cleared.insert(action)
            case .absent:
                if let shortcut = defaults[action] { result.shortcuts[action] = shortcut }
            case .unusable: break
            }
        }
        let mapped = Set(mapping.map(\.key))
        result.unmapped = preferences.keys.sorted().compactMap { key in
            guard !mapped.contains(key), let name = unmappedKey(key),
                  case .shortcut = PreferenceShortcut(preferences[key]) else { return nil }
            return name
        }
        return result
    }
}
