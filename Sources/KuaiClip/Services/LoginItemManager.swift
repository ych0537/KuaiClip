import Foundation
import ServiceManagement

enum LoginItemManager {
    static let defaultsKey = "launchAtLogin"
    static let defaultEnabled = true

    static func configuredValue(defaults: UserDefaults = .standard) -> Bool {
        defaults.register(defaults: [defaultsKey: defaultEnabled])
        return defaults.bool(forKey: defaultsKey)
    }

    static func applyConfiguredValue(defaults: UserDefaults = .standard) {
        setEnabled(configuredValue(defaults: defaults))
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                guard SMAppService.mainApp.status != .enabled else { return }
                try SMAppService.mainApp.register()
            } else {
                guard SMAppService.mainApp.status != .notRegistered else { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[KuaiClip] Login item error: %@", error.localizedDescription)
        }
    }
}
