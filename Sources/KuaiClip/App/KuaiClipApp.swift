import SwiftUI
import AppKit

/// Main application entry point
@main
struct KuaiClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}

/// Application delegate - manages lifecycle, clipboard, hotkeys, menu bar
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[KuaiClip] Application launched")

        NSApp.setActivationPolicy(.accessory)
        AppTheme.applyAppearance(AppTheme.migrateStoredAppearance())
        if let icon = AppIconTheme.selected.appImage {
            NSApp.applicationIconImage = icon
        }

        // Set up menu bar
        MenuBarManager.shared.setup()

        // Start clipboard monitoring
        ClipboardMonitor.shared.start()

        // Register global hotkey
        HotkeyManager.shared.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyPressed()
        }
        HotkeyManager.shared.onScreenshotHotkeyPressed = {
            ScreenshotService.shared.showModeChooser()
        }
        HotkeyManager.shared.register()

        // Intercept CMD+, globally since LSUIElement hides the app menu
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 43, event.modifierFlags.contains(.command) {
                self?.openPreferences()
                return nil
            }
            return event
        }

        // First-launch accessibility check (only once)
        showAccessibilityPromptIfNeeded()

        print("[KuaiClip] Initialization complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[KuaiClip] Application terminating")
        ClipboardMonitor.shared.stop()
        HotkeyManager.shared.unregister()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            MenuBarManager.shared.showPopup()
        }
        return true
    }

    private func handleHotkeyPressed() {
        MenuBarManager.shared.togglePopup()
    }

    private func openPreferences() {
        MenuBarManager.shared.showPreferences()
    }

    // MARK: - Accessibility Prompt

    private func showAccessibilityPromptIfNeeded() {
        let key = "kuaiclip_hasShownAccessibilityPrompt"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        // Only prompt if double-tap is the selected mode AND accessibility not granted
        guard HotkeyManager.shared.useDoubleTap, !AXIsProcessTrusted() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = L10n.accessibilityTitle
            alert.informativeText = L10n.accessibilityBody
            alert.alertStyle = .informational
            alert.addButton(withTitle: L10n.openSystemSettings)
            alert.addButton(withTitle: L10n.useFallback)
            alert.addButton(withTitle: L10n.openPreferences)

            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                )
            case .alertSecondButtonReturn:
                // Switch to Carbon hotkey mode
                HotkeyManager.shared.useDoubleTap = false
                HotkeyManager.shared.register()
            case .alertThirdButtonReturn:
                self.openPreferences()
            default:
                break
            }
        }
    }
}
