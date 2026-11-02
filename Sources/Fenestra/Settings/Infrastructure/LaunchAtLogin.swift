import ServiceManagement

/// Registers or unregisters the app as a login item.
@MainActor
final class LaunchAtLogin: LoginItem {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func set(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
