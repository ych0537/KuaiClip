import Foundation
import AppKit
import Carbon

/// Manages global keyboard shortcuts. Supports two modes:
/// 1. Double-tap Left Command (needs Accessibility)
/// 2. Custom Carbon hotkey (works without permissions)
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotkeyRef: EventHotKeyRef?
    private var screenshotHotkeyRef: EventHotKeyRef?
    private var hotkeyID = EventHotKeyID(signature: 0x44_58_43_42, id: 1)
    private var screenshotHotkeyID = EventHotKeyID(signature: 0x44_58_43_42, id: 2)
    private var eventHandlerRef: EventHandlerRef?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    // Carbon hotkey state
    private(set) var currentKeyCode: UInt32 = UInt32(kVK_ANSI_C)
    private(set) var currentModifiers: UInt32 = UInt32(shiftKey | cmdKey)
    private(set) var screenshotKeyCode: UInt32 = UInt32(kVK_ANSI_S)
    private(set) var screenshotModifiers: UInt32 = UInt32(shiftKey | cmdKey)

    // Double-tap state
    private var lastCmdPressTime: Date = .distantPast
    private let doubleTapWindow: TimeInterval = 0.4
    private var cmdIsDown: Bool = false

    var onHotkeyPressed: (() -> Void)?
    var onScreenshotHotkeyPressed: (() -> Void)?

    /// Whether Accessibility permissions are granted
    var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    /// User preference for double-tap mode
    var useDoubleTap: Bool {
        get { UserDefaults.standard.bool(forKey: "hotkey_useDoubleTap") }
        set {
            UserDefaults.standard.set(newValue, forKey: "hotkey_useDoubleTap")
            register()
        }
    }

    /// Effective double-tap mode (respects permissions)
    var effectiveDoubleTap: Bool {
        useDoubleTap && isAccessibilityGranted
    }

    private init() {
        loadSavedHotkey()
    }

    // MARK: - Public API

    func register() {
        unregisterAll()

        if effectiveDoubleTap {
            registerDoubleTap()
        } else {
            registerCarbonHotkey()
        }
        registerScreenshotHotkey()
    }

    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        guard !conflictsWithScreenshot(keyCode: keyCode, modifiers: modifiers) else { return }
        currentKeyCode = keyCode
        currentModifiers = modifiers
        saveHotkey()
        register()
    }

    func updateScreenshotHotkey(keyCode: UInt32, modifiers: UInt32) -> Bool {
        guard !conflictsWithPopup(keyCode: keyCode, modifiers: modifiers) else { return false }
        screenshotKeyCode = keyCode
        screenshotModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: "screenshot_hotkey_keyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "screenshot_hotkey_modifiers")
        register()
        return true
    }

    func conflictsWithPopup(keyCode: UInt32, modifiers: UInt32) -> Bool {
        !effectiveDoubleTap && keyCode == currentKeyCode && modifiers == currentModifiers
    }

    func conflictsWithScreenshot(keyCode: UInt32, modifiers: UInt32) -> Bool {
        keyCode == screenshotKeyCode && modifiers == screenshotModifiers
    }

    func unregister() { unregisterAll() }

    var hotkeyDescription: String {
        if useDoubleTap {
            if isAccessibilityGranted { return L10n.doubleTapCommand }
            else { return "\(L10n.doubleTapCommand) (\(L10n.needsPermission))" }
        }
        return carbonDescription(keyCode: currentKeyCode, modifiers: currentModifiers)
    }

    var effectiveHotkeyDescription: String {
        if effectiveDoubleTap { return L10n.doubleTapCommand }
        return carbonDescription(keyCode: currentKeyCode, modifiers: currentModifiers)
    }

    // MARK: - Double-tap via Global Monitor

    private func registerDoubleTap() {
        // Global monitor for when app is in background
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        // Local monitor for when app is frontmost
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        NSLog("[KuaiClip] Double-tap Cmd registered (Accessibility: %@)",
              isAccessibilityGranted ? "yes" : "no")
    }

    private nonisolated func handleFlagsChanged(_ event: NSEvent) {
        let cmd = event.modifierFlags.contains(.command)
        Task { @MainActor in
            let km = HotkeyManager.shared
            let wasDown = km.cmdIsDown
            km.cmdIsDown = cmd
            if cmd, !wasDown { km.handleCmdPress() }
        }
    }

    private func handleCmdPress() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastCmdPressTime)
        if elapsed < doubleTapWindow {
            NSLog("[KuaiClip] Double-tap Cmd! (%.0fms)", elapsed * 1000)
            lastCmdPressTime = .distantPast
            DispatchQueue.main.async { [weak self] in self?.onHotkeyPressed?() }
        } else {
            lastCmdPressTime = now
        }
    }

    // MARK: - Carbon Hotkey

    private func registerCarbonHotkey() {
        var gRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            currentKeyCode, currentModifiers, hotkeyID,
            GetEventDispatcherTarget(), 0, &gRef
        )
        if status == noErr {
            hotkeyRef = gRef
            NSLog("[KuaiClip] Carbon hotkey registered: %@",
                  carbonDescription(keyCode: currentKeyCode, modifiers: currentModifiers))
        } else {
            NSLog("[KuaiClip] Carbon hotkey failed: %d", status)
        }

        if eventHandlerRef == nil {
            var spec = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            let ptr = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(GetEventDispatcherTarget(),
                { (_, event, ud) -> OSStatus in
                    guard let ud = ud else { return -1 }
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(ud).takeUnretainedValue()
                    var pressedID = EventHotKeyID()
                    let status = GetEventParameter(
                        event, EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID), nil,
                        MemoryLayout<EventHotKeyID>.size, nil, &pressedID
                    )
                    guard status == noErr else { return status }
                    manager.fireHotkey(id: pressedID.id)
                    return noErr
                }, 1, &spec, ptr, &eventHandlerRef)
        }
    }

    private func registerScreenshotHotkey() {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            screenshotKeyCode, screenshotModifiers, screenshotHotkeyID,
            GetEventDispatcherTarget(), 0, &ref
        )
        if status == noErr {
            screenshotHotkeyRef = ref
        } else {
            NSLog("[KuaiClip] Screenshot hotkey failed: %d", status)
        }
        if eventHandlerRef == nil {
            registerCarbonHotkeyHandlerOnly()
        }
    }

    private func registerCarbonHotkeyHandlerOnly() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { (_, event, ud) -> OSStatus in
            guard let ud else { return -1 }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(ud).takeUnretainedValue()
            var pressedID = EventHotKeyID()
            let status = GetEventParameter(
                event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil,
                MemoryLayout<EventHotKeyID>.size, nil, &pressedID
            )
            guard status == noErr else { return status }
            manager.fireHotkey(id: pressedID.id)
            return noErr
        }, 1, &spec, ptr, &eventHandlerRef)
    }

    private func fireHotkey(id: UInt32) {
        DispatchQueue.main.async { [weak self] in
            if id == self?.screenshotHotkeyID.id {
                self?.onScreenshotHotkeyPressed?()
            } else {
                self?.onHotkeyPressed?()
            }
        }
    }

    // MARK: - Cleanup

    private func unregisterAll() {
        if let r = hotkeyRef { UnregisterEventHotKey(r); hotkeyRef = nil }
        if let r = screenshotHotkeyRef { UnregisterEventHotKey(r); screenshotHotkeyRef = nil }
        if let r = eventHandlerRef { RemoveEventHandler(r); eventHandlerRef = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    private func reRegister() { register() }

    // MARK: - Description

    func carbonDescription(keyCode: UInt32, modifiers: UInt32) -> String {
        var p: [String] = []
        let m = Int(modifiers)
        if m & Int(shiftKey) != 0   { p.append("⇧") }
        if m & Int(controlKey) != 0 { p.append("⌃") }
        if m & Int(optionKey) != 0  { p.append("⌥") }
        if m & Int(cmdKey) != 0     { p.append("⌘") }
        if let c = keyCodeToChar(Int(keyCode)) { p.append(c.uppercased()) }
        else { p.append("?") }
        return p.joined()
    }

    func reregisterIfNeeded() { register() }

    func applyCustomFromStorage() {
        let kc = UserDefaults.standard.integer(forKey: "hotkey_keyCode")
        let mods = UserDefaults.standard.integer(forKey: "hotkey_modifiers")
        if kc > 0 {
            currentKeyCode = UInt32(kc)
            currentModifiers = UInt32(mods)
            if !effectiveDoubleTap { register() }
        }
    }

    func applyScreenshotFromStorage() {
        let d = UserDefaults.standard
        let keyCode = d.integer(forKey: "screenshot_hotkey_keyCode")
        let modifiers = d.integer(forKey: "screenshot_hotkey_modifiers")
        if keyCode > 0 {
            _ = updateScreenshotHotkey(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
        }
    }

    static func carbonModifiersFromNSEvent(_ event: NSEvent) -> UInt32 {
        var m: UInt32 = 0
        let f = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if f.contains(.shift)   { m |= UInt32(shiftKey) }
        if f.contains(.control) { m |= UInt32(controlKey) }
        if f.contains(.option)  { m |= UInt32(optionKey) }
        if f.contains(.command) { m |= UInt32(cmdKey) }
        return m
    }

    // MARK: - Helpers

    private func keyCodeToChar(_ k: Int) -> String? {
        let map: [Int: String] = [
            kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c",
            kVK_ANSI_D: "d", kVK_ANSI_E: "e", kVK_ANSI_F: "f",
            kVK_ANSI_G: "g", kVK_ANSI_H: "h", kVK_ANSI_I: "i",
            kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
            kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o",
            kVK_ANSI_P: "p", kVK_ANSI_Q: "q", kVK_ANSI_R: "r",
            kVK_ANSI_S: "s", kVK_ANSI_T: "t", kVK_ANSI_U: "u",
            kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
            kVK_ANSI_Y: "y", kVK_ANSI_Z: "z",
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2",
            kVK_ANSI_3: "3", kVK_ANSI_4: "4", kVK_ANSI_5: "5",
            kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8",
            kVK_ANSI_9: "9",
            kVK_Space: "␣", kVK_Return: "↩", kVK_Tab: "⇥",
            kVK_Escape: "⎋", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
            kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_LeftArrow: "←", kVK_RightArrow: "→",
        ]
        return map[k]
    }

    // MARK: - Persistence

    private func loadSavedHotkey() {
        let d = UserDefaults.standard
        let kc = d.integer(forKey: "hotkey_keyCode")
        let mods = d.integer(forKey: "hotkey_modifiers")
        if kc > 0 { currentKeyCode = UInt32(kc); currentModifiers = UInt32(mods) }
        let screenshotKC = d.integer(forKey: "screenshot_hotkey_keyCode")
        let screenshotMods = d.integer(forKey: "screenshot_hotkey_modifiers")
        if screenshotKC > 0 {
            screenshotKeyCode = UInt32(screenshotKC)
            screenshotModifiers = UInt32(screenshotMods)
        }
    }

    private func saveHotkey() {
        UserDefaults.standard.set(Int(currentKeyCode), forKey: "hotkey_keyCode")
        UserDefaults.standard.set(Int(currentModifiers), forKey: "hotkey_modifiers")
    }
}
