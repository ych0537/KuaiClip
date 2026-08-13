import Foundation
import AppKit

/// Monitors the system clipboard for changes
@MainActor
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isEnabled: Bool = true
    private var ignoreNextCopy: Bool = false

    /// Polling interval in seconds. The Preferences setting is the source of
    /// truth; 0.5s is the fallback for first launch.
    private var pollingInterval: TimeInterval {
        let saved = UserDefaults.standard.double(forKey: "pollingInterval")
        return saved > 0 ? saved : 0.5
    }

    private init() {}

    // MARK: - Public API

    var isMonitoring: Bool {
        isEnabled
    }

    func start() {
        timer?.invalidate()
        timer = nil
        lastChangeCount = NSPasteboard.general.changeCount
        let interval = pollingInterval
        let newTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkClipboard()
            }
        }
        // Ensure timer fires even when popup is open
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
        print("[KuaiClip] Clipboard monitoring started (\(interval)s)")
    }

    /// Recreate the polling timer so a changed Preferences interval takes
    /// effect without restarting the app.
    func updatePollingInterval() {
        guard timer != nil else { return }
        start()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        print("[KuaiClip] Clipboard monitoring stopped")
    }

    func disable() {
        isEnabled = false
        print("[KuaiClip] Clipboard monitoring disabled")
    }

    func enable() {
        isEnabled = true
        print("[KuaiClip] Clipboard monitoring enabled")
    }

    func toggleEnabled() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    func setIgnoreNextCopy(_ ignore: Bool) {
        ignoreNextCopy = ignore
        if ignore {
            print("[KuaiClip] Ignoring next copy")
        }
    }

    // MARK: - Private

    private func checkClipboard() {
        guard isEnabled else { return }

        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        if ignoreNextCopy {
            ignoreNextCopy = false
            print("[KuaiClip] Ignored one copy")
            return
        }

        // Extract content from pasteboard
        guard let content = extractContent(from: pasteboard) else { return }

        DispatchQueue.main.async {
            self.handleNewContent(content)
        }
    }

    private func extractContent(from pasteboard: NSPasteboard) -> (String, ClipboardContentType, Data?)? {
        // Try string first
        if let string = pasteboard.string(forType: .string) {
            return (string, .text, nil)
        }

        // Try RTF as plain text
        if let rtfData = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            return (attributed.string, .text, nil)
        }

        // Try HTML
        if let htmlData = pasteboard.data(forType: .html),
           let htmlString = String(data: htmlData, encoding: .utf8) {
            return (htmlString, .text, nil)
        }

        // Try URL
        if let url = pasteboard.string(forType: .URL) {
            return (url, .fileURL, nil)
        }

        // Try file URLs
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !fileURLs.isEmpty {
            let paths = fileURLs.map { $0.path }.joined(separator: ", ")
            return (paths, .fileURL, nil)
        }

        // Keep the original pixel dimensions so replaying an image does not
        // write a reduced copy back to the clipboard.
        if let image = NSImage(pasteboard: pasteboard) {
            if let payload = Self.fullSizePNGData(from: image) {
                let sizeString = "\(payload.width)×\(payload.height)"
                return ("[\(L10n.image): \(sizeString)]", .image, payload.data)
            }
            return ("[\(L10n.image)]", .image, nil)
        }

        // Try generic data types
        let types = pasteboard.types ?? []
        if !types.isEmpty {
            let typeNames = types.map { $0.rawValue }.joined(separator: ", ")
            return ("[\(L10n.dataContent): \(typeNames)]", .other, nil)
        }

        return nil
    }

    private func handleNewContent(_ content: String, _ type: ClipboardContentType = .text, _ imageData: Data? = nil) {
        // Skip if this is KuaiClip's own paste operation (content starts with our marker)
        // We detect this by checking if the content was just set by PasteService
        HistoryStore.shared.addItem(content, contentType: type, imageData: imageData)
    }

    private func handleNewContent(_ tuple: (String, ClipboardContentType, Data?)) {
        let (content, type, imageData) = tuple
        // Deduplication is handled by HistoryStore
        HistoryStore.shared.addItem(content, contentType: type, imageData: imageData)
    }

    static func fullSizePNGData(from image: NSImage) -> (data: Data, width: Int, height: Int)? {
        let bitmap = image.representations
            .compactMap { $0 as? NSBitmapImageRep }
            .max { lhs, rhs in
                lhs.pixelsWide * lhs.pixelsHigh < rhs.pixelsWide * rhs.pixelsHigh
            }
            ?? image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:))

        guard let bitmap,
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        return (pngData, bitmap.pixelsWide, bitmap.pixelsHigh)
    }
}
