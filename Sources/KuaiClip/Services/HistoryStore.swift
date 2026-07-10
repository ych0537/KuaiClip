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

    private var maxItems: Int {
        let saved = userDefaults.integer(forKey: "maxHistoryItems")
        return min(saved > 0 ? saved : Self.defaultUnpinnedItems, Self.maxUnpinnedItems)
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        normalizeMaxItemsSetting()
        load()
        let didUpdateShortcuts = reassignPinnedShortcutKeys()
        let didTrimHistory = trimUnpinnedItemsIfNeeded()
        if didUpdateShortcuts || didTrimHistory { save() }
    }

    // MARK: - Public API

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
        if items.contains(where: { $0.isPinned && $0.content == content }) {
            let oldCount = items.count
            items.removeAll { !$0.isPinned && $0.content == content }
            if items.count != oldCount { save() }
            return
        }

        // Deduplicate: if identical content exists, move it to top
        if let existingIndex = items.firstIndex(where: { $0.content == content && !$0.isPinned }) {
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
                $0.id != updated.id && !$0.isPinned && $0.content == updated.content
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
        userDefaults.set(data, forKey: userDefaultsKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else {
            items = []
            return
        }
        items = decoded
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
