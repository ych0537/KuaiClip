import SwiftUI
import AppKit

/// Manages the menu bar icon and the popup window
@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()

    private static let defaultPopupSize = NSSize(width: 340, height: 400)
    private static let minimumPopupSize = NSSize(width: 340, height: 400)
    private static let popupWidthKey = "popupWindowWidth"
    private static let popupHeightKey = "popupWindowHeight"

    private var statusItem: NSStatusItem?
    private var popupWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    private var isPopupVisible: Bool = false
    private var isPopupAlertPresented: Bool = false

    private override init() {
        super.init()
     }

     // MARK: - Setup

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        applyIconTheme(to: button)

        button.toolTip = "KuaiClip (\(HotkeyManager.shared.hotkeyDescription))"
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp])

        statusItem?.menu = makeMenu()
     }

    func refreshLocalization() {
        statusItem?.menu = makeMenu()
        statusItem?.button?.toolTip = "KuaiClip (\(HotkeyManager.shared.hotkeyDescription))"
        preferencesWindow?.title = L10n.preferencesTitle
    }

    func refreshIconTheme() {
        guard let button = statusItem?.button else { return }
        applyIconTheme(to: button)
    }

    private func applyIconTheme(to button: NSStatusBarButton) {
        if let image = AppIconTheme.selected.menuBarImage {
            image.accessibilityDescription = "KuaiClip"
            button.title = ""
            button.image = image
        } else if let image = NSImage(
            systemSymbolName: "list.clipboard",
            accessibilityDescription: "KuaiClip"
        ) {
            image.isTemplate = true
            button.title = ""
            button.image = image
        } else {
            button.image = nil
            button.title = "KuaiClip"
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let clearUnpinnedItem = NSMenuItem(
            title: L10n.clearUnpinned,
            action: #selector(menuClearUnpinned),
            keyEquivalent: ""
         )
        clearUnpinnedItem.target = self
        menu.addItem(clearUnpinnedItem)

        let clearAllItem = NSMenuItem(
            title: L10n.clearAllItems,
            action: #selector(menuClearAll),
            keyEquivalent: ""
         )
        clearAllItem.target = self
        clearAllItem.keyEquivalentModifierMask = .option
        clearAllItem.isAlternate = true
        menu.addItem(clearAllItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: L10n.preferences,
            action: #selector(menuOpenPreferences),
            keyEquivalent: ","
         )
        prefsItem.keyEquivalentModifierMask = .command
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L10n.quit,
            action: #selector(menuQuit),
            keyEquivalent: "q"
         )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
     }

     // MARK: - Popup Window

    func togglePopup() {
        if isPopupVisible {
            dismissPopup()
         } else {
            showPopup()
         }
     }

    func showPopup() {
        guard !isPopupVisible else { return }
        NSLog("[KuaiClip] showPopup called")

        let popupView = PopupView(
            onPinLimitAlertPresented: {
                self.isPopupAlertPresented = true
            },
            onDismiss: {
                self.dismissPopup()
            }
        )

        let targetScreen = screen(at: NSEvent.mouseLocation)
        let popupSize = restoredPopupSize(for: targetScreen)
        let hostingView = NSHostingView(rootView: popupView)
        hostingView.frame = NSRect(origin: .zero, size: popupSize)
        hostingView.autoresizingMask = [.width, .height]

        let window = PopupPanel(
            contentRect: NSRect(origin: .zero, size: popupSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless, .resizable],
            backing: .buffered,
            defer: false
         )

        window.isFloatingPanel = true
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.hasShadow = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = Self.minimumPopupSize
        window.isMovableByWindowBackground = true

         // SwiftUI handles all styling (background + rounded corners) directly.
        window.contentView = hostingView

         // Position window
        positionWindow(window, on: targetScreen)

        NSLog("[KuaiClip] Popup window frame: %@", NSStringFromRect(window.frame))

        popupWindow = window
        isPopupAlertPresented = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isPopupVisible = true
     }

    func dismissPopup() {
        guard isPopupVisible, let window = popupWindow else { return }
        NSLog("[KuaiClip] dismissPopup called")
        savePopupSize(window.frame.size)
        window.orderOut(nil)
        popupWindow = nil
        isPopupVisible = false
        isPopupAlertPresented = false
     }

    func showPreferences() {
        dismissPopup()

         // Return existing window if already open
        if let win = preferencesWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
         }

        let prefsView = PreferencesView()
        let hostingView = NSHostingView(rootView: prefsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 520)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
         )
        window.title = L10n.preferencesTitle
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        preferencesWindow = window
     }

    private func positionWindow(_ window: NSWindow, on screen: NSScreen?) {
         // Position the popup at the current mouse cursor location
        let mouseLoc = NSEvent.mouseLocation
        let size = window.frame.size
        window.setFrame(NSRect(
            x: mouseLoc.x - size.width / 2,
            y: mouseLoc.y - size.height - 12,
            width: size.width,
            height: size.height
         ), display: false)

         // Clamp to visible screen
        if let screen = screen ?? window.screen ?? NSScreen.main {
            var f = window.frame
            let vf = screen.visibleFrame
            if f.minX < vf.minX { f.origin.x = vf.minX + 8 }
            if f.maxX > vf.maxX { f.origin.x = vf.maxX - size.width - 8 }
            if f.minY < vf.minY { f.origin.y = vf.minY + 8 }
            if f.maxY > vf.maxY { f.origin.y = vf.maxY - size.height - 8 }
            window.setFrame(f, display: false)
         }
     }

    private func screen(at point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }

    private func restoredPopupSize(for screen: NSScreen?) -> NSSize {
        let defaults = UserDefaults.standard
        let savedWidth = defaults.double(forKey: Self.popupWidthKey)
        let savedHeight = defaults.double(forKey: Self.popupHeightKey)
        let requested = NSSize(
            width: savedWidth > 0 ? savedWidth : Self.defaultPopupSize.width,
            height: savedHeight > 0 ? savedHeight : Self.defaultPopupSize.height
        )
        guard let visibleSize = screen?.visibleFrame.size else { return requested }
        return NSSize(
            width: min(max(requested.width, Self.minimumPopupSize.width), visibleSize.width - 16),
            height: min(max(requested.height, Self.minimumPopupSize.height), visibleSize.height - 16)
        )
    }

    private func savePopupSize(_ size: NSSize) {
        guard size.width >= Self.minimumPopupSize.width,
              size.height >= Self.minimumPopupSize.height else { return }
        let defaults = UserDefaults.standard
        defaults.set(size.width, forKey: Self.popupWidthKey)
        defaults.set(size.height, forKey: Self.popupHeightKey)
    }

     // MARK: - Status Item Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let currentEvent = NSApp.currentEvent
        let isOptionPressed = currentEvent?.modifierFlags.contains(.option) ?? false
        let isShiftPressed = currentEvent?.modifierFlags.contains(.shift) ?? false

        if isOptionPressed && isShiftPressed {
            ClipboardMonitor.shared.setIgnoreNextCopy(true)
         } else if isOptionPressed {
            ClipboardMonitor.shared.toggleEnabled()
            updateIcon()
         } else {
            togglePopup()
         }
     }

     // MARK: - Menu Actions

    @objc private func menuClearUnpinned() {
        HistoryStore.shared.clearUnpinned()
     }

    @objc private func menuClearAll() {
        HistoryStore.shared.clearAll()
     }

    @objc private func menuOpenPreferences() {
        showPreferences()
     }

    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
     }

     // MARK: - Status Update

    func updateIcon() {
        guard let button = statusItem?.button else { return }
        if ClipboardMonitor.shared.isMonitoring {
            button.alphaValue = 1.0
         } else {
            button.alphaValue = 0.4
         }
     }
}

// MARK: - NSWindowDelegate

extension MenuBarManager: NSWindowDelegate {
    nonisolated func windowDidResignKey(_ notification: Notification) {
         // Delay to distinguish "clicked outside" from internal focus shifts
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
            let km = MenuBarManager.shared
             // If our popup is no longer key (user clicked elsewhere), dismiss
            if km.isPopupVisible,
               !km.isPopupAlertPresented,
               NSApp.keyWindow == nil || !(NSApp.keyWindow is PopupPanel) {
                km.dismissPopup()
             }
         }
     }

    nonisolated func windowWillClose(_ notification: Notification) {
        let closingWindow = notification.object as? NSWindow
        Task { @MainActor in
            let km = MenuBarManager.shared
            if let win = closingWindow, win === km.preferencesWindow {
                km.preferencesWindow = nil
             }
            if closingWindow === km.popupWindow {
                km.isPopupVisible = false
             }
         }
     }
}
