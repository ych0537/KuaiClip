import Foundation
import AppKit
import CoreGraphics

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

    /// Copy item and paste into frontmost application
    func copyAndPaste(_ item: ClipboardItem, pasteWithoutFormatting: Bool = false) {
        let targetApplication = MenuBarManager.shared.pasteTargetApplication
        copyToClipboard(item)

        // Dismissing the popup restores the previously active application,
        // but activation is asynchronous. Wait until that application really
        // owns the foreground before posting Command-V; a fixed short delay
        // can otherwise paste into KuaiClip itself or drop the event.
        pasteWhenTargetIsFrontmost(
            targetApplication,
            stripFormatting: pasteWithoutFormatting,
            remainingAttempts: 20
        )
    }

    // MARK: - Private

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
