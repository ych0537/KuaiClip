import Foundation
import AppKit

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): return message
        }
    }
}

@main
struct TestRunner {
    static func main() async {
        do {
            try await MainActor.run {
                try runHistoryStoreTests()
                try runLocalizationTests()
                try runUsageMetricsTests()
                try imageEncodingPreservesOriginalDimensions()
            }
            try await textPolishRejectsOversizedInput()
            try azureV1EndpointBuildsChatCompletionsURL()
            try expect(AIModel.deepSeekFlash.displayName == "deepseek-v4-flash", "AI model picker should show only the model ID")
            print("All KuaiClip tests passed")
        } catch {
            fputs("Test failed: \(error)\n", stderr)
            exit(1)
        }
    }

    private static func textPolishRejectsOversizedInput() async throws {
        let oversized = String(repeating: "a", count: TextPolishService.maximumCharacterCount + 1)
        do {
            _ = try await TextPolishService.polish(oversized, using: .openAIMini)
            throw TestFailure.failed("oversized polish request should be rejected")
        } catch TextPolishError.textTooLong(let limit) {
            try expect(limit == TextPolishService.maximumCharacterCount, "polish limit should be reported")
        } catch {
            throw TestFailure.failed("expected textTooLong, got \(error)")
        }
    }

    private static func azureV1EndpointBuildsChatCompletionsURL() throws {
        let url = try TextPolishService.azureChatCompletionsURL(
            endpoint: "https://example.internal/openai/v1/",
            deployment: "company-gpt"
        )
        try expect(
            url.absoluteString == "https://example.internal/openai/v1/chat/completions",
            "Azure v1 endpoint should append chat/completions without a legacy deployments path"
        )
    }

    @MainActor
    private static func runHistoryStoreTests() throws {
        try addingDuplicateUnpinnedItemDeduplicates()
        try pinnedContentIsNotReaddedAsHistory()
        try pinnedDuplicateCleanupRemovesExistingUnpinnedCopy()
        try clearUnpinnedPreservesPinnedItems()
        try maxHistoryTrimsOldestUnpinnedItems()
        try defaultAndMaximumHistorySettingsAreEnforced()
        try pinnedItemsUseSeparateLabelsAndRespectLimit()
        try usedUnpinnedItemMovesToTopWithoutReorderingPinnedItems()
    }

    private static func runLocalizationTests() throws {
        try withLanguage("en") {
            try expect(L10n.search == "Search…", "English search text")
            try expect(L10n.clearUnpinned == "Clear Unpinned Items", "English menu text")
            try expect(L10n.pinLimitTitle == "Pinned item limit reached", "English pin limit title")
            try expect(L10n.timeAgo(30, date: Date()) == "Just now", "English relative time")
            try expect(L10n.localUsage == "Local Usage", "English local usage title")
        }

        try withLanguage("ja") {
            try expect(L10n.search == "検索…", "Japanese search text")
            try expect(L10n.clearUnpinned == "未固定項目を消去", "Japanese menu text")
            try expect(L10n.pinLimitTitle == "固定項目の上限", "Japanese pin limit title")
            try expect(L10n.timeAgo(30, date: Date()) == "たった今", "Japanese relative time")
            try expect(L10n.localUsage == "このMacでの利用状況", "Japanese local usage title")
        }

        try withLanguage("zh") {
            try expect(L10n.search == "搜索…", "Chinese search text")
            try expect(L10n.clearUnpinned == "清除未固定项目", "Chinese menu text")
            try expect(L10n.pinLimitTitle == "已达到固定项目上限", "Chinese pin limit title")
            try expect(L10n.timeAgo(30, date: Date()) == "刚刚", "Chinese relative time")
            try expect(L10n.polishAction == "润色", "Chinese polish action")
            try expect(L10n.localUsage == "本机使用统计", "Chinese local usage title")
        }

        let item = ClipboardItem(content: "")
        try withLanguage("en") {
            try expect(item.preview == "(empty)", "English empty preview")
        }
        try withLanguage("ja") {
            try expect(item.preview == "（空）", "Japanese empty preview")
        }
        try withLanguage("zh") {
            try expect(item.preview == "（空）", "Chinese empty preview")
        }
    }

    @MainActor
    private static func runUsageMetricsTests() throws {
        let suiteName = "KuaiClipTests.UsageMetrics.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed("expected isolated usage metrics defaults")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let metrics = UsageMetrics(defaults: defaults)
        try expect(metrics.snapshot == UsageMetricsSnapshot(
            popupOpenCount: 0,
            polishWindowOpenCount: 0,
            polishRunCount: 0,
            trackingStartedAt: nil
        ), "usage metrics should start empty")

        metrics.recordPopupOpened()
        metrics.recordPopupOpened()
        metrics.recordPolishWindowOpened()
        metrics.recordPolishRun()

        try expect(metrics.popupOpenCount == 2, "popup opens should be counted")
        try expect(metrics.polishWindowOpenCount == 1, "polish windows should be counted")
        try expect(metrics.polishRunCount == 1, "polish runs should be counted")
        try expect(metrics.trackingStartedAt != nil, "first use should set tracking date")

        let reloaded = UsageMetrics(defaults: defaults)
        try expect(reloaded.snapshot == metrics.snapshot, "usage metrics should persist")
        try expect(reloaded.surveyReport(appVersion: "0.5").contains("Popup opens: 2"), "survey report should contain counters")

        reloaded.reset()
        try expect(reloaded.popupOpenCount == 0 && reloaded.trackingStartedAt == nil, "reset should clear only usage metrics")
    }

    @MainActor
    private static func imageEncodingPreservesOriginalDimensions() throws {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 488,
            pixelsHigh: 272,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw TestFailure.failed("expected test bitmap")
        }

        let image = NSImage(size: NSSize(width: 488, height: 272))
        image.addRepresentation(bitmap)

        guard let payload = ClipboardMonitor.fullSizePNGData(from: image),
              let encodedBitmap = NSBitmapImageRep(data: payload.data)
        else {
            throw TestFailure.failed("expected full-size PNG payload")
        }

        try expect(payload.width == 488 && payload.height == 272, "image payload should keep original dimensions")
        try expect(
            encodedBitmap.pixelsWide == 488 && encodedBitmap.pixelsHigh == 272,
            "encoded PNG should keep original pixel dimensions"
        )
    }

    @MainActor
    private static func addingDuplicateUnpinnedItemDeduplicates() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("alpha")
        store.addItem("beta")
        store.addItem("alpha")

        try expect(store.items.count == 2, "duplicate unpinned item should not create a new row")
        try expect(store.unpinnedItems.filter { $0.content == "alpha" }.count == 1, "duplicate content should stay unique")
        try expect(store.allItemsOrdered.first?.content == "alpha", "duplicate item should move to top")
    }

    @MainActor
    private static func pinnedContentIsNotReaddedAsHistory() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("secret")
        guard let item = store.items.first else {
            throw TestFailure.failed("expected initial item")
        }

        store.togglePin(item)
        store.addItem("secret")

        try expect(store.items.count == 1, "pinned content should not be re-added")
        try expect(store.pinnedItems.first?.content == "secret", "pinned item should remain")
        try expect(store.unpinnedItems.isEmpty, "pinned duplicate should not appear as unpinned")
    }

    @MainActor
    private static func pinnedDuplicateCleanupRemovesExistingUnpinnedCopy() throws {
        let context = TestContext()
        defer { context.cleanUp() }

        let pinned = ClipboardItem(content: "token", isPinned: true, shortcutKey: "1")
        let duplicate = ClipboardItem(content: "token")
        context.defaults.set(
            try JSONEncoder().encode([pinned, duplicate]),
            forKey: "kuaiclip_history_items"
        )
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("token")

        try expect(store.items.count == 1, "adding pinned content should clean old unpinned duplicate")
        try expect(store.pinnedItems.count == 1, "pinned item should be preserved")
        try expect(store.unpinnedItems.isEmpty, "unpinned duplicate should be removed")
    }

    @MainActor
    private static func clearUnpinnedPreservesPinnedItems() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("keep")
        store.addItem("remove")
        guard let keep = store.items.first(where: { $0.content == "keep" }) else {
            throw TestFailure.failed("expected keep item")
        }

        store.togglePin(keep)
        store.clearUnpinned()

        try expect(store.items.count == 1, "clearUnpinned should keep one item")
        try expect(store.items.first?.content == "keep", "clearUnpinned should preserve pinned item")
        try expect(store.items.first?.isPinned == true, "remaining item should be pinned")
    }

    @MainActor
    private static func maxHistoryTrimsOldestUnpinnedItems() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        context.defaults.set(2, forKey: "maxHistoryItems")
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("one")
        store.addItem("two")
        store.addItem("three")

        try expect(store.unpinnedItems.count == 2, "max history should keep only two items")
        try expect(store.items.first { $0.content == "one" } == nil, "oldest unpinned item should be trimmed")
    }

    @MainActor
    private static func defaultAndMaximumHistorySettingsAreEnforced() throws {
        let defaultContext = TestContext()
        defer { defaultContext.cleanUp() }
        _ = HistoryStore(userDefaults: defaultContext.defaults)
        try expect(
            defaultContext.defaults.integer(forKey: "maxHistoryItems") == HistoryStore.defaultUnpinnedItems,
            "missing max history setting should default to 50"
        )

        let cappedContext = TestContext()
        defer { cappedContext.cleanUp() }
        cappedContext.defaults.set(500, forKey: "maxHistoryItems")
        _ = HistoryStore(userDefaults: cappedContext.defaults)
        try expect(
            cappedContext.defaults.integer(forKey: "maxHistoryItems") == HistoryStore.maxUnpinnedItems,
            "max history setting should be capped at 100"
        )
    }

    @MainActor
    private static func pinnedItemsUseSeparateLabelsAndRespectLimit() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        let store = HistoryStore(userDefaults: context.defaults)

        for index in 0...HistoryStore.maxPinnedItems {
            store.addItem("item-\(index)")
        }

        for index in 0..<HistoryStore.maxPinnedItems {
            guard let item = store.items.first(where: { $0.content == "item-\(index)" }) else {
                throw TestFailure.failed("expected item to pin")
            }
            try expect(store.togglePin(item) == .pinned, "first ten items should pin successfully")
        }

        let orderedPinned = store.allItemsOrdered.filter(\.isPinned)
        try expect(orderedPinned.count == 10, "exactly ten pinned items should be allowed")
        try expect(
            orderedPinned.compactMap(\.shortcutKey) == HistoryStore.pinnedShortcutLabels,
            "pinned items should be labeled a through j"
        )

        guard let eleventh = store.items.first(where: { $0.content == "item-10" }) else {
            throw TestFailure.failed("expected eleventh item")
        }
        try expect(store.togglePin(eleventh) == .limitReached, "eleventh pin should report the limit")
        try expect(
            store.items.first(where: { $0.id == eleventh.id })?.isPinned == false,
            "eleventh item should remain unpinned"
        )

        store.togglePin(orderedPinned[4])
        let relabeled = store.allItemsOrdered.filter(\.isPinned)
        try expect(
            relabeled.compactMap(\.shortcutKey) == Array(HistoryStore.pinnedShortcutLabels.prefix(9)),
            "remaining pinned items should be relabeled after unpinning"
        )

        store.removeItem(relabeled[2])
        try expect(
            store.allItemsOrdered.filter(\.isPinned).compactMap(\.shortcutKey) ==
                Array(HistoryStore.pinnedShortcutLabels.prefix(8)),
            "remaining pinned items should be relabeled after deletion"
        )
    }

    @MainActor
    private static func usedUnpinnedItemMovesToTopWithoutReorderingPinnedItems() throws {
        let context = TestContext()
        defer { context.cleanUp() }
        let store = HistoryStore(userDefaults: context.defaults)

        store.addItem("oldest")
        store.addItem("pinned")
        store.addItem("newest")

        guard let oldest = store.items.first(where: { $0.content == "oldest" }),
              let pinned = store.items.first(where: { $0.content == "pinned" })
        else {
            throw TestFailure.failed("expected history items")
        }

        store.togglePin(pinned)
        let pinnedOrder = store.pinnedItems.map(\.id)
        store.markUsed(oldest)

        try expect(store.unpinnedItems.sorted { $0.timestamp > $1.timestamp }.first?.id == oldest.id,
                   "used unpinned item should move to the first unpinned position")
        try expect(store.pinnedItems.map(\.id) == pinnedOrder,
                   "using an unpinned item should not reorder pinned items")
    }

    private static func withLanguage(_ language: String, _ body: () throws -> Void) throws {
        let originalLanguage = UserDefaults.standard.string(forKey: "appLanguage")
        UserDefaults.standard.set(language, forKey: "appLanguage")
        defer {
            if let originalLanguage {
                UserDefaults.standard.set(originalLanguage, forKey: "appLanguage")
            } else {
                UserDefaults.standard.removeObject(forKey: "appLanguage")
            }
        }
        try body()
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw TestFailure.failed(message)
        }
    }
}

private final class TestContext {
    let suiteName: String
    let defaults: UserDefaults

    init() {
        suiteName = "kuaiclip.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
