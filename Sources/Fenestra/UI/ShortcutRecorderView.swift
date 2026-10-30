import AppKit
import SwiftUI

/// Button that records a keyboard shortcut (at least one of ⌃⌥⌘ required).
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut?
    @State private var isRecording = false
    @State private var monitor: Any?

    init(shortcut: Binding<KeyboardShortcut?>) {
        _shortcut = shortcut
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(isRecording ? "Tapez le raccourci…" : (shortcut?.displayString ?? "Cliquer pour définir")) {
                isRecording ? stopRecording() : startRecording()
            }
            .frame(minWidth: 130)
            Button { shortcut = nil } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.borderless)
                .disabled(shortcut == nil)
                .help("Effacer le raccourci")
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let flags = UInt(event.modifierFlags.rawValue) & KeyboardShortcut.relevantFlags
            MainActor.assumeIsolated { handle(keyCode: keyCode, flags: flags) }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func handle(keyCode: UInt16, flags: UInt) {
        let required = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag | KeyboardShortcut.commandFlag
        if keyCode == 53 {
            stopRecording()
        } else if flags == 0 && keyCode == KeyboardShortcut.Key.delete {
            shortcut = nil
            stopRecording()
        } else if flags & required != 0 {
            shortcut = KeyboardShortcut(keyCode: keyCode, modifiers: flags)
            stopRecording()
        } else {
            NSSound.beep()
        }
    }
}
