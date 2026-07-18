import AppKit
import SwiftUI

enum ScreenshotMode {
    case region
    case window
    case fullScreen
}

@MainActor
final class ScreenshotService: NSObject, NSWindowDelegate {
    static let shared = ScreenshotService()

    private var editorWindow: NSWindow?
    private var captureProcess: Process?

    func showModeChooser() {
        MenuBarManager.shared.dismissPopup()
        let menu = NSMenu()
        addItem(L10n.captureRegion, symbol: "rectangle.dashed", mode: .region, to: menu)
        addItem(L10n.captureWindow, symbol: "macwindow", mode: .window, to: menu)
        addItem(L10n.captureFullScreen, symbol: "rectangle.inset.filled", mode: .fullScreen, to: menu)
        menu.addItem(.separator())
        let cancel = NSMenuItem(title: L10n.cancel, action: nil, keyEquivalent: "")
        menu.addItem(cancel)
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    func capture(_ mode: ScreenshotMode) {
        dismissEditor()
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("KuaiClip-\(UUID().uuidString).png")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        switch mode {
        case .region:
            process.arguments = ["-i", "-s", "-x", output.path]
        case .window:
            process.arguments = ["-i", "-w", "-x", output.path]
        case .fullScreen:
            process.arguments = ["-x", output.path]
        }
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.captureProcess = nil
                guard process.terminationStatus == 0,
                      let data = try? Data(contentsOf: output),
                      let image = NSImage(data: data) else {
                    try? FileManager.default.removeItem(at: output)
                    return
                }
                try? FileManager.default.removeItem(at: output)
                self?.showEditor(image: image)
            }
        }
        captureProcess = process
        do {
            try process.run()
        } catch {
            presentError(error.localizedDescription)
        }
    }

    func copyToClipboard(_ data: Data) {
        guard let image = NSImage(data: data) else { return }
        ClipboardMonitor.shared.setIgnoreNextCopy(true)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        let dimensions = ClipboardMonitor.fullSizePNGData(from: image)
        let label = "[\(L10n.image): \(dimensions?.width ?? Int(image.size.width))×\(dimensions?.height ?? Int(image.size.height))]"
        HistoryStore.shared.addItem(label, contentType: .image, imageData: data)
        dismissEditor()
    }

    func saveToDownloads(_ data: Data) {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        var destination = downloads.appendingPathComponent("KuaiClip \(formatter.string(from: Date())).png")
        var suffix = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = downloads.appendingPathComponent("KuaiClip \(formatter.string(from: Date())) \(suffix).png")
            suffix += 1
        }
        do {
            try data.write(to: destination, options: .atomic)
            NSWorkspace.shared.activateFileViewerSelecting([destination])
            dismissEditor()
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func addItem(_ title: String, symbol: String, mode: ScreenshotMode, to menu: NSMenu) {
        let item = ScreenshotMenuItem(title: title, mode: mode)
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        item.target = self
        item.action = #selector(selectMode(_:))
        menu.addItem(item)
    }

    @objc private func selectMode(_ sender: ScreenshotMenuItem) {
        capture(sender.mode)
    }

    private func showEditor(image: NSImage) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let width = min(max(image.size.width, 620), screen.width - 80)
        let height = min(max(image.size.height + 76, 420), screen.height - 80)
        let view = ScreenshotEditorView(image: image)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.screenshotEditor
        window.minSize = NSSize(width: 620, height: 420)
        // Keep ownership in ScreenshotService. Releasing an NSWindow while
        // AppKit is still completing its close animation can crash in
        // _NSWindowTransformAnimation.
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        editorWindow = window
    }

    private func dismissEditor() {
        // orderOut is synchronous and does not start NSWindow's close
        // transform animation. Keep the hidden window retained until the next
        // editor replaces it, so SwiftUI/AppKit button actions can unwind
        // safely.
        editorWindow?.orderOut(nil)
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.screenshotFailed
        alert.informativeText = message
        alert.runModal()
    }

}

private final class ScreenshotMenuItem: NSMenuItem {
    let mode: ScreenshotMode
    init(title: String, mode: ScreenshotMode) {
        self.mode = mode
        super.init(title: title, action: nil, keyEquivalent: "")
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
