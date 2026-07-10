import Foundation
import AppKit

/// Represents the type of clipboard content
enum ClipboardContentType: String, Codable, CaseIterable {
    case text
    case image
    case fileURL
    case other
}

/// A single clipboard history item
struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var content: String
    let contentType: ClipboardContentType
    var timestamp: Date
    var isPinned: Bool
    var isContentHidden: Bool
    var shortcutKey: String?
    var imageData: Data?  // full-resolution PNG data

    init(
        id: UUID = UUID(),
        content: String,
        contentType: ClipboardContentType = .text,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        isContentHidden: Bool = false,
        shortcutKey: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.isContentHidden = isContentHidden
        self.shortcutKey = shortcutKey
        self.imageData = imageData
    }

    /// Truncated preview for the list display
    var preview: String {
        let trimmed = content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "…"
        }
        return trimmed.isEmpty ? L10n.empty : trimmed
    }

    /// Brief preview for narrow displays
    var shortPreview: String {
        let trimmed = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 60 {
            return String(trimmed.prefix(60)) + "…"
        }
        return trimmed.isEmpty ? L10n.empty : trimmed
    }

    /// Relative time description
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        return L10n.timeAgo(interval, date: timestamp)
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
