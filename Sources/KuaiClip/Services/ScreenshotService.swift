import AppKit
import CoreGraphics
import ScreenCaptureKit
import SwiftUI
import UniformTypeIdentifiers

enum ScreenshotMode {
    case region
    case window
    case fullScreen
}

@MainActor
final class ScreenshotService: NSObject, NSWindowDelegate {
    static let shared = ScreenshotService()

    private var editorWindow: NSWindow?
    private var regionSelectionPanel: NSPanel?
    private var windowSelectionPanels: [NSPanel] = []
    private var windowSelectionEventMonitor: Any?

    func showModeChooser() {
        guard PurchaseManager.shared.accessState.hasFullAccess else {
            presentUpgradeRequired()
            return
        }
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

        guard ensureScreenCaptureAccess() else {
            presentScreenCapturePermissionRequired()
            return
        }

        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                switch mode {
                case .region:
                    try beginRegionSelection(content: content)
                case .window:
                    beginWindowSelection(content: content)
                case .fullScreen:
                    guard let display = displayAtMouseLocation(in: content.displays) else {
                        throw ScreenshotCaptureError.noDisplay
                    }
                    try await capture(display: display)
                }
            } catch {
                presentError(error.localizedDescription)
            }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "KuaiClip \(formatter.string(from: Date())).png"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let destination = panel.url else { return }
            do {
                try data.write(to: destination, options: .atomic)
                NSWorkspace.shared.activateFileViewerSelecting([destination])
                self?.dismissEditor()
            } catch {
                self?.presentError(error.localizedDescription)
            }
        }
        if let editorWindow {
            panel.beginSheetModal(for: editorWindow, completionHandler: completion)
        } else {
            completion(panel.runModal())
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

    private func displayAtMouseLocation(in displays: [SCDisplay]) -> SCDisplay? {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let screen,
              let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return displays.first
        }
        let displayID = CGDirectDisplayID(number.uint32Value)
        return displays.first { $0.displayID == displayID } ?? displays.first
    }

    private func capture(display: SCDisplay, sourceRect: CGRect? = nil) async throws {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = captureConfiguration(for: filter, sourceRect: sourceRect)
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        showEditor(image: NSImage(cgImage: image, size: .zero))
    }

    private func capture(windowID: CGWindowID) throws {
        guard let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            throw ScreenshotCaptureError.noWindow
        }
        showEditor(image: NSImage(cgImage: image, size: .zero))
    }

    private func captureConfiguration(for filter: SCContentFilter, sourceRect: CGRect? = nil) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        let rect = sourceRect ?? filter.contentRect
        // A window filter already defines its own capture bounds. Supplying the
        // filter's global contentRect as sourceRect makes ScreenCaptureKit crop
        // again in the filter-local coordinate space, which can yield an empty
        // image for windows positioned away from the origin.
        if let sourceRect {
            configuration.sourceRect = sourceRect
        }
        configuration.width = max(1, Int(rect.width * CGFloat(filter.pointPixelScale)))
        configuration.height = max(1, Int(rect.height * CGFloat(filter.pointPixelScale)))
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = false
        return configuration
    }

    private func beginWindowSelection(content: SCShareableContent) {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let windows = content.windows
            .filter {
                $0.owningApplication?.processID != ownPID &&
                $0.windowLayer == 0 &&
                $0.frame.width >= 80 && $0.frame.height >= 60
            }

        guard !windows.isEmpty else {
            presentError(L10n.screenshotNoWindow)
            return
        }

        dismissWindowSelection()
        windowSelectionPanels = NSScreen.screens.map { screen in
            let selectionView = WindowSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
            let panel = ScreenshotSelectionPanel(
                contentRect: screen.frame,
                // This must be an activating panel. A nonactivating transparent
                // panel can receive mouse-moved events while sending clicks to
                // the application underneath, which makes the highlight work
                // but leaves selection with no effect.
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = selectionView

            selectionView.onCancel = { [weak self] in
                self?.dismissWindowSelection()
            }
            selectionView.onSelection = { [weak self] window in
                self?.completeWindowSelection(window)
            }
            selectionView.windows = windows
            panel.orderFrontRegardless()
            return panel
        }
        NSApp.activate(ignoringOtherApps: true)
        let mouseLocation = NSEvent.mouseLocation
        let activePanel = windowSelectionPanels.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? windowSelectionPanels.first
        activePanel?.makeKeyAndOrderFront(nil)
        if let contentView = activePanel?.contentView {
            activePanel?.makeFirstResponder(contentView)
        }

        windowSelectionEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            guard let self, !windowSelectionPanels.isEmpty else { return event }
            if event.type == .keyDown, event.keyCode == 53 {
                dismissWindowSelection()
                return nil
            }
            return event
        }
    }

    private func dismissWindowSelection() {
        if let windowSelectionEventMonitor {
            NSEvent.removeMonitor(windowSelectionEventMonitor)
            self.windowSelectionEventMonitor = nil
        }
        windowSelectionPanels.forEach { $0.orderOut(nil) }
        windowSelectionPanels.removeAll()
    }

    private func completeWindowSelection(_ window: SCWindow) {
        guard !windowSelectionPanels.isEmpty else { return }
        let selectedWindowID = window.windowID
        dismissWindowSelection()
        do {
            try capture(windowID: selectedWindowID)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func beginRegionSelection(content: SCShareableContent) throws {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main,
              let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let display = content.displays.first(where: { $0.displayID == CGDirectDisplayID(number.uint32Value) }) else {
            throw ScreenshotCaptureError.noDisplay
        }

        regionSelectionPanel?.orderOut(nil)
        let selectionView = RegionSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
        let panel = ScreenshotSelectionPanel(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = selectionView
        regionSelectionPanel = panel

        selectionView.onCancel = { [weak self] in
            self?.regionSelectionPanel?.orderOut(nil)
            self?.regionSelectionPanel = nil
        }
        selectionView.onSelection = { [weak self] selection in
            guard let self else { return }
            regionSelectionPanel?.orderOut(nil)
            regionSelectionPanel = nil
            guard selection.width >= 2, selection.height >= 2 else { return }
            let sourceRect = CGRect(
                x: selection.minX,
                y: screen.frame.height - selection.maxY,
                width: selection.width,
                height: selection.height
            )
            Task {
                do {
                    try await self.capture(display: display, sourceRect: sourceRect)
                } catch {
                    self.presentError(error.localizedDescription)
                }
            }
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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

    private func ensureScreenCaptureAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        return CGRequestScreenCaptureAccess()
    }

    private func presentScreenCapturePermissionRequired() {
        let alert = NSAlert()
        alert.messageText = L10n.screenCapturePermissionTitle
        alert.informativeText = L10n.screenCapturePermissionMessage
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.openSystemSettings)
        alert.addButton(withTitle: L10n.cancel)

        if alert.runModal() == .alertFirstButtonReturn,
           let settingsURL = URL(
               string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
           ) {
            NSWorkspace.shared.open(settingsURL)
        }
    }

    private func presentUpgradeRequired() {
        let alert = NSAlert()
        alert.messageText = L10n.premiumRequired
        alert.informativeText = L10n.premiumRequiredDetail
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.openPreferences)
        alert.addButton(withTitle: L10n.cancel)
        if alert.runModal() == .alertFirstButtonReturn {
            MenuBarManager.shared.showPreferences()
        }
    }

}

private enum ScreenshotCaptureError: LocalizedError {
    case noDisplay
    case noWindow

    var errorDescription: String? {
        switch self {
        case .noDisplay: L10n.screenshotNoDisplay
        case .noWindow: L10n.screenshotNoWindow
        }
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

private final class ScreenshotSelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
private final class RegionSelectionView: NSView {
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        let selection = selectionRect
        startPoint = nil
        currentPoint = nil
        needsDisplay = true
        onSelection?(selection)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        bounds.fill()
        guard !selectionRect.isEmpty else { return }

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: selectionRect).addClip()
        NSColor.clear.setFill()
        selectionRect.fill(using: .copy)
        NSGraphicsContext.restoreGraphicsState()

        let border = NSBezierPath(rect: selectionRect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        NSColor.white.setStroke()
        border.stroke()
    }

    private var selectionRect: CGRect {
        guard let startPoint, let currentPoint else { return .zero }
        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
}

@MainActor
private final class WindowSelectionView: NSView {
    var windows: [SCWindow] = []
    var onSelection: ((SCWindow) -> Void)?
    var onCancel: (() -> Void)?

    private var hoveredWindow: SCWindow?
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        window?.makeFirstResponder(self)
        updateHoveredWindow()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        updateHoveredWindow()
    }

    override func mouseDown(with event: NSEvent) {
        let point = event.cgEvent?.location ?? CGEvent(source: nil)?.location
        guard let point,
              let selectedWindow = windows.first(where: { $0.frame.contains(point) }) else {
            return
        }
        // Let AppKit finish dispatching this mouse event before the callback
        // removes and releases the panel that owns this view.
        DispatchQueue.main.async { [weak self] in
            self?.onSelection?(selectedWindow)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.22).setFill()
        bounds.fill()

        if let hoveredWindow {
            let rect = localRect(for: hoveredWindow.frame).intersection(bounds)
            if !rect.isEmpty {
                NSGraphicsContext.saveGraphicsState()
                NSBezierPath(rect: rect).addClip()
                NSColor.clear.setFill()
                rect.fill(using: .copy)
                NSGraphicsContext.restoreGraphicsState()

                let border = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 8, yRadius: 8)
                border.lineWidth = 4
                NSColor.systemBlue.setStroke()
                border.stroke()
            }
        }

    }

    private func updateHoveredWindow() {
        guard let point = CGEvent(source: nil)?.location else { return }
        let match = windows.first { $0.frame.contains(point) }
        if match?.windowID != hoveredWindow?.windowID {
            hoveredWindow = match
            needsDisplay = true
        }
    }

    private func localRect(for quartzRect: CGRect) -> CGRect {
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        let appKitRect = CGRect(
            x: quartzRect.minX,
            y: mainDisplayHeight - quartzRect.maxY,
            width: quartzRect.width,
            height: quartzRect.height
        )
        guard let window else { return .zero }
        return appKitRect.offsetBy(dx: -window.frame.minX, dy: -window.frame.minY)
    }
}
