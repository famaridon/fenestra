import Carbon
import Foundation
import os

/// Global hotkeys built on Carbon `RegisterEventHotKey` (no Accessibility permission needed).
/// Each shortcut runs the closure registered for it (a snap action, a workspace…).
@MainActor
final class HotkeyManager {
    typealias Action = @MainActor () -> Void

    private struct Entry {
        let action: Action
        let ref: EventHotKeyRef
    }

    private static let signature: OSType = 0x504E_4545 // "PNEE"
    private static let logger = Logger(subsystem: "com.florentamaridon.Fenestra", category: "hotkeys")

    /// Hot key id -> owning manager. The Carbon callback cannot capture context, so it looks the manager up here.
    private static var owners: [UInt32: HotkeyManager] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerRef: EventHandlerRef?

    private var entries: [UInt32: Entry] = [:]

    /// Replaces every registered hotkey. A shortcut the system or another app already owns is skipped and logged.
    func register(_ bindings: [KeyboardShortcut: Action]) {
        unregisterAll()
        Self.installHandlerIfNeeded()
        for (shortcut, action) in bindings {
            let id = Self.nextID
            Self.nextID &+= 1
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(shortcut.keyCode), shortcut.carbonModifiers,
                EventHotKeyID(signature: Self.signature, id: id),
                GetApplicationEventTarget(), 0, &ref
            )
            guard status == noErr, let ref else {
                Self.logger.error("Cannot register \(shortcut.displayString): OSStatus \(status)")
                continue
            }
            entries[id] = Entry(action: action, ref: ref)
            Self.owners[id] = self
        }
    }

    func unregisterAll() {
        for (id, entry) in entries {
            UnregisterEventHotKey(entry.ref)
            Self.owners[id] = nil
        }
        entries.removeAll()
    }

    isolated deinit {
        unregisterAll()
    }

    private func fire(_ id: UInt32) {
        entries[id]?.action()
    }

    private static func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let result = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
            )
            guard result == noErr, hotKeyID.signature == HotkeyManager.signature else {
                return OSStatus(eventNotHandledErr)
            }
            let id = hotKeyID.id
            // Application-target Carbon events are delivered on the main thread.
            MainActor.assumeIsolated { HotkeyManager.owners[id]?.fire(id) }
            return noErr
        }, 1, &spec, nil, &handlerRef)
        if status != noErr {
            logger.error("Cannot install hot key handler: OSStatus \(status)")
        }
    }
}
