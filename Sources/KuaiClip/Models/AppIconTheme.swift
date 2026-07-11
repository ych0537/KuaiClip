import AppKit
import Foundation

enum AppIconTheme: String, CaseIterable, Identifiable {
    static let defaultsKey = "appIconTheme"

    case pandaTyping = "panda-typing"
    case pandaBricks = "panda-bricks"
    case sealBalloon = "seal-balloon"

    var id: String { rawValue }

    static var selected: AppIconTheme {
        let value = UserDefaults.standard.string(forKey: defaultsKey) ?? pandaTyping.rawValue
        return AppIconTheme(rawValue: value) ?? .pandaTyping
    }

    var title: String {
        switch self {
        case .pandaTyping: return L10n.pandaTyping
        case .pandaBricks: return L10n.pandaBricks
        case .sealBalloon: return L10n.sealBalloon
        }
    }

    var appImage: NSImage? { image(named: rawValue) }

    var menuBarImage: NSImage? {
        guard let image = image(named: "\(rawValue)-menubar") else { return nil }
        image.isTemplate = true
        return image
    }

    @MainActor
    func apply() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
        if let appImage { NSApp.applicationIconImage = appImage }
        MenuBarManager.shared.refreshIconTheme()
    }

    private func image(named name: String) -> NSImage? {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "IconThemes"
        ) else { return nil }
        return NSImage(contentsOf: url)
    }
}
