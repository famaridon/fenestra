import ApplicationServices

/// `AccessibilityTrust` backed by `AXIsProcessTrusted`.
@MainActor
final class AXAccessibilityTrust: AccessibilityTrust {
    var isTrusted: Bool { AXIsProcessTrusted() }

    func requestTrust() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
