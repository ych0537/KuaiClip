import Combine
import Foundation

struct UsageMetricsSnapshot: Equatable {
    let popupOpenCount: Int
    let polishWindowOpenCount: Int
    let polishRunCount: Int
    let trackingStartedAt: Date?
}

@MainActor
final class UsageMetrics: ObservableObject {
    static let shared = UsageMetrics()

    private enum Key {
        static let popupOpenCount = "usageMetrics_popupOpenCount"
        static let polishWindowOpenCount = "usageMetrics_polishWindowOpenCount"
        static let polishRunCount = "usageMetrics_polishRunCount"
        static let trackingStartedAt = "usageMetrics_trackingStartedAt"
    }

    @Published private(set) var popupOpenCount: Int
    @Published private(set) var polishWindowOpenCount: Int
    @Published private(set) var polishRunCount: Int
    @Published private(set) var trackingStartedAt: Date?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        popupOpenCount = max(0, defaults.integer(forKey: Key.popupOpenCount))
        polishWindowOpenCount = max(0, defaults.integer(forKey: Key.polishWindowOpenCount))
        polishRunCount = max(0, defaults.integer(forKey: Key.polishRunCount))
        trackingStartedAt = defaults.object(forKey: Key.trackingStartedAt) as? Date
    }

    var snapshot: UsageMetricsSnapshot {
        UsageMetricsSnapshot(
            popupOpenCount: popupOpenCount,
            polishWindowOpenCount: polishWindowOpenCount,
            polishRunCount: polishRunCount,
            trackingStartedAt: trackingStartedAt
        )
    }

    func recordPopupOpened() {
        ensureTrackingStarted()
        popupOpenCount += 1
        defaults.set(popupOpenCount, forKey: Key.popupOpenCount)
    }

    func recordPolishWindowOpened() {
        ensureTrackingStarted()
        polishWindowOpenCount += 1
        defaults.set(polishWindowOpenCount, forKey: Key.polishWindowOpenCount)
    }

    func recordPolishRun() {
        ensureTrackingStarted()
        polishRunCount += 1
        defaults.set(polishRunCount, forKey: Key.polishRunCount)
    }

    func reset() {
        popupOpenCount = 0
        polishWindowOpenCount = 0
        polishRunCount = 0
        trackingStartedAt = nil
        defaults.removeObject(forKey: Key.popupOpenCount)
        defaults.removeObject(forKey: Key.polishWindowOpenCount)
        defaults.removeObject(forKey: Key.polishRunCount)
        defaults.removeObject(forKey: Key.trackingStartedAt)
    }

    func surveyReport(appVersion: String) -> String {
        let startDate = trackingStartedAt.map(Self.isoDateFormatter.string) ?? "not started"
        return """
        KuaiClip version: \(appVersion)
        Popup opens: \(popupOpenCount)
        Polish window opens: \(polishWindowOpenCount)
        Polish runs: \(polishRunCount)
        Tracking since: \(startDate)
        """
    }

    private func ensureTrackingStarted() {
        guard trackingStartedAt == nil else { return }
        let now = Date()
        trackingStartedAt = now
        defaults.set(now, forKey: Key.trackingStartedAt)
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
