import Foundation
import AppKit
import Observation

/// Persists and manages clipboard history items
@MainActor
@Observable
final class HistoryStore {
    static let shared = HistoryStore()
    static let maxPinnedItems = 10
    static let maxUnpinnedItems = 100
    static let defaultUnpinnedItems = 50
    static let pinnedShortcutLabels = "abcdefghij".map(String.init)

    enum PinToggleResult: Equatable {
        case pinned
        case unpinned
        case limitReached
        case itemNotFound
    }

    private(set) var items: [ClipboardItem] = []
    private let userDefaults: UserDefaults
    private let userDefaultsKey = "kuaiclip_history_items"
    private let historyFileURL: URL?

    private static var defaultHistoryFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("KuaiClip", isDirectory: true)
            .appendingPathComponent("clipboard-history.json", isDirectory: false)
    }

    private var maxItems: Int {
        let saved = userDefaults.integer(forKey: "maxHistoryItems")
        return min(saved > 0 ? saved : Self.defaultUnpinnedItems, Self.maxUnpinnedItems)
    }

    init(userDefaults: UserDefaults = .standard, historyFileURL: URL? = nil) {
        self.userDefaults = userDefaults
        // Isolated UserDefaults suites used by tests keep their existing
        // in-suite persistence unless a file URL is explicitly supplied.
        self.historyFileURL = historyFileURL ?? (userDefaults === UserDefaults.standard
            ? Self.defaultHistoryFileURL
            : nil)
        normalizeMaxItemsSetting()
        let didLoadLegacyDefaults = load()
        let didUpdateShortcuts = reassignPinnedShortcutKeys()
        let didTrimHistory = trimUnpinnedItemsIfNeeded()
        if didLoadLegacyDefaults || didUpdateShortcuts || didTrimHistory { save() }
    }

    // MARK: - Public API

    /// True when `item` carries the same copied content as the given
    /// (content, contentType, imageData) triple.
    ///
    /// Images are matched by their pixel data instead of the display label
    /// ("[Image: W×H]"), so two different screenshots with identical pixel
    /// dimensions are never collapsed into a single history entry.
    static func hasSameContent(
        _ item: ClipboardItem,
        asContent content: String,
        contentType: ClipboardContentType,
        imageData: Data?
    ) -> Bool {
        if contentType == .image || item.contentType == .image {
            guard contentType == .image, item.contentType == .image else { return false }
            if let imageData, let existingData = item.imageData {
                return imageData == existingData
            }
            // Image items whose pixel data could not be captured fall back to
            // their label for matching.
            return item.imageData == nil && item.content == content
        }
        return item.content == content
    }

    static func hasSameContent(_ lhs: ClipboardItem, _ rhs: ClipboardItem) -> Bool {
        hasSameContent(lhs, asContent: rhs.content, contentType: rhs.contentType, imageData: rhs.imageData)
    }

    var pinnedItems: [ClipboardItem] {
        items.filter { $0.isPinned }
    }

    var unpinnedItems: [ClipboardItem] {
        items.filter { !$0.isPinned }
    }

    var allItemsOrdered: [ClipboardItem] {
        items.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.timestamp > b.timestamp
        }
    }

    func addItem(_ content: String, contentType: ClipboardContentType = .text, imageData: Data? = nil) {
        guard !content.isEmpty else { return }
        if items.contains(where: {
            $0.isPinned && Self.hasSameContent($0, asContent: content, contentType: contentType, imageData: imageData)
        }) {
            let oldCount = items.count
            items.removeAll {
                !$0.isPinned && Self.hasSameContent($0, asContent: content, contentType: contentType, imageData: imageData)
            }
            if items.count != oldCount { save() }
            return
        }

        // Deduplicate: if identical content exists, move it to top
        if let existingIndex = items.firstIndex(where: {
            !$0.isPinned && Self.hasSameContent($0, asContent: content, contentType: contentType, imageData: imageData)
        }) {
            var updated = items[existingIndex]
            updated = ClipboardItem(
                id: updated.id,
                content: content,
                contentType: contentType,
                timestamp: Date(),
                isPinned: updated.isPinned,
                isContentHidden: updated.isContentHidden,
                shortcutKey: updated.shortcutKey,
                imageData: imageData ?? updated.imageData
            )
            items[existingIndex] = updated
        } else {
            let item = ClipboardItem(
                content: content,
                contentType: contentType,
                timestamp: Date(),
                imageData: imageData
            )
            items.append(item)
        }

        trimUnpinnedItemsIfNeeded()

        save()
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        reassignPinnedShortcutKeys()
        save()
    }

    func removeItems(_ toRemove: [ClipboardItem]) {
        let ids = Set(toRemove.map { $0.id })
        items.removeAll { ids.contains($0.id) }
        reassignPinnedShortcutKeys()
        save()
    }

    func markUsed(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              !items[index].isPinned else { return }

        var copy = items
        copy[index].timestamp = Date()
        items = copy
        save()
    }

    @discardableResult
    func togglePin(_ item: ClipboardItem) -> PinToggleResult {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return .itemNotFound
        }

        if !items[index].isPinned, pinnedItems.count >= Self.maxPinnedItems {
            return .limitReached
        }

        var updated = items[index]
        updated.isPinned.toggle()

        updated.shortcutKey = nil

        updated.timestamp = Date()
        // Reassign the whole array to trigger @Observable change notification
        var copy = items
        copy[index] = updated
        if updated.isPinned {
            copy.removeAll {
                $0.id != updated.id && !$0.isPinned && Self.hasSameContent($0, updated)
            }
        }
        items = copy
        reassignPinnedShortcutKeys()
        save()
        return updated.isPinned ? .pinned : .unpinned
    }

    func updateMaxItems(_ requestedValue: Int) {
        let value = min(max(requestedValue, 1), Self.maxUnpinnedItems)
        userDefaults.set(value, forKey: "maxHistoryItems")
        if trimUnpinnedItemsIfNeeded() { save() }
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    func setContentHidden(_ item: ClipboardItem, hidden: Bool) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        // Reassign the whole array to trigger @Observable change notification
        var copy = items
        copy[idx].isContentHidden = hidden
        items = copy
        save()
    }

    // MARK: - Persistence

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        guard let historyFileURL else {
            userDefaults.set(data, forKey: userDefaultsKey)
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: historyFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: historyFileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            // Remove the oversized legacy value only after the file write has
            // succeeded, so an upgrade cannot lose existing history.
            removeLegacyHistoryFromDefaults()
        } catch {
            NSLog("KuaiClip failed to save clipboard history: %@", error.localizedDescription)
        }
    }

    private func removeLegacyHistoryFromDefaults() {
        userDefaults.removeObject(forKey: userDefaultsKey)

        // CFPreferences can reject even a deletion when the existing domain
        // already exceeds its size limit. Replacing the persistent domain
        // without the large key makes that cleanup unambiguous.
        guard userDefaults === UserDefaults.standard,
              let domainName = Bundle.main.bundleIdentifier,
              var domain = userDefaults.persistentDomain(forName: domainName),
              domain.removeValue(forKey: userDefaultsKey) != nil else { return }
        userDefaults.setPersistentDomain(domain, forName: domainName)
        userDefaults.synchronize()
    }

    /// Returns true when data came from the legacy UserDefaults value and
    /// should be migrated to the history file.
    private func load() -> Bool {
        if let historyFileURL,
           let data = try? Data(contentsOf: historyFileURL),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            return false
        }

        if let data = userDefaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            return historyFileURL != nil
        }

        items = []
        return false
    }

    private func normalizeMaxItemsSetting() {
        let saved = userDefaults.integer(forKey: "maxHistoryItems")
        if saved <= 0 {
            userDefaults.set(Self.defaultUnpinnedItems, forKey: "maxHistoryItems")
        } else if saved > Self.maxUnpinnedItems {
            userDefaults.set(Self.maxUnpinnedItems, forKey: "maxHistoryItems")
        }
    }

    @discardableResult
    private func trimUnpinnedItemsIfNeeded() -> Bool {
        let unpinned = items.filter { !$0.isPinned }
        guard unpinned.count > maxItems else { return false }

        let idsToRemove = Set(
            unpinned
                .sorted(by: { $0.timestamp < $1.timestamp })
                .prefix(unpinned.count - maxItems)
                .map(\.id)
        )
        items.removeAll { idsToRemove.contains($0.id) }
        return true
    }

    @discardableResult
    private func reassignPinnedShortcutKeys() -> Bool {
        let orderedPinnedIDs = items
            .filter(\.isPinned)
            .sorted { $0.timestamp > $1.timestamp }
            .map(\.id)
        let shortcutsByID = Dictionary(uniqueKeysWithValues:
            orderedPinnedIDs.prefix(Self.pinnedShortcutLabels.count).enumerated().map { offset, id in
                (id, Self.pinnedShortcutLabels[offset])
            }
        )

        var changed = false
        for index in items.indices {
            let expectedKey = items[index].isPinned ? shortcutsByID[items[index].id] : nil
            if items[index].shortcutKey != expectedKey {
                items[index].shortcutKey = expectedKey
                changed = true
            }
        }
        return changed
    }
}
