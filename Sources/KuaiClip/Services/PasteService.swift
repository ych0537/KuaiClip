import Foundation
import AppKit
import CoreGraphics

/// How formatting should be handled when pasting into the frontmost app.
enum PasteFormatting {
    /// Follow the "strip formatting by default" preference.
    case inherit
    /// Always paste with formatting (Command-V).
    case keepFormatting
    /// Always paste without formatting (Option-Shift-Command-V).
    case stripFormatting
}

/// Service for copy and paste operations
@MainActor
final class PasteService {
    static let shared = PasteService()

    private init() {}

    // MARK: - Public API

    /// Copy item content to clipboard
    func copyToClipboard(_ item: ClipboardItem) {
        // Every write performed by KuaiClip must be ignored by the monitor. For
        // images, replaying stored data would otherwise create another item.
        ClipboardMonitor.shared.setIgnoreNextCopy(true)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text, .fileURL, .other:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            } else {
                pasteboard.setString(item.content, forType: .string)
            }
        }

        HistoryStore.shared.markUsed(item)
    }

    /// Copy item and paste into frontmost application.
    ///
    /// The formatting parameter controls whether the paste preserves
    /// rich formatting. The inherit case follows the "strip formatting by
    /// default" preference from Preferences; the explicit cases always
    /// override it (Option+number keeps formatting, Option+Shift+number
    /// strips it).
    func copyAndPaste(_ item: ClipboardItem, formatting: PasteFormatting = .inherit) {
        let targetApplication = MenuBarManager.shared.pasteTargetApplication
        copyToClipboard(item)

        // Dismissing the popup restores the previously active application,
        // but activation is asynchronous. Wait until that application really
        // owns the foreground before posting Command-V; a fixed short delay
        // can otherwise paste into KuaiClip itself or drop the event.
        pasteWhenTargetIsFrontmost(
            targetApplication,
            stripFormatting: stripFormatting(for: formatting),
            remainingAttempts: 20
        )
    }

    // MARK: - Private

    /// Resolves the "strip formatting by default" preference for a paste.
    private func stripFormatting(for formatting: PasteFormatting) -> Bool {
        switch formatting {
        case .inherit:
            return UserDefaults.standard.bool(forKey: "stripFormattingByDefault")
        case .keepFormatting:
            return false
        case .stripFormatting:
            return true
        }
    }

    private func pasteWhenTargetIsFrontmost(
        _ targetApplication: NSRunningApplication?,
        stripFormatting: Bool,
        remainingAttempts: Int
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let targetApplication else {
                self.pasteToFrontmost(stripFormatting: stripFormatting)
                return
            }

            let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
            if frontmostPID == targetApplication.processIdentifier {
                self.pasteToFrontmost(stripFormatting: stripFormatting)
            } else if remainingAttempts > 1 {
                targetApplication.activate(options: [])
                self.pasteWhenTargetIsFrontmost(
                    targetApplication,
                    stripFormatting: stripFormatting,
                    remainingAttempts: remainingAttempts - 1
                )
            } else {
                NSLog("[KuaiClip] Paste cancelled because the previous application did not regain focus")
            }
        }
    }

    /// Simulate paste keystrokes to the frontmost application
    private func pasteToFrontmost(stripFormatting: Bool) {
        // Posting keyboard events uses the dedicated PostEvent TCC privilege.
        // It is distinct from full Accessibility API access and is compatible
        // with an App Sandbox build. If the user declines, the item has already
        // been copied and remains available for a manual Command-V.
        guard CGPreflightPostEventAccess() || CGRequestPostEventAccess() else {
            NSLog("[KuaiClip] Direct paste permission denied; content remains on the pasteboard")
            return
        }

        let src = CGEventSource(stateID: .combinedSessionState)

        let cmdKey: CGEventFlags = .maskCommand
        let optionKey: CGEventFlags = .maskAlternate
        let shiftKey: CGEventFlags = .maskShift

        var flags: CGEventFlags = cmdKey
        if stripFormatting {
            flags.insert(optionKey)
            flags.insert(shiftKey)
        }

        // CMD+V or OPTION+SHIFT+CMD+V
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)

        keyDown?.flags = flags
        keyUp?.flags = flags

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
