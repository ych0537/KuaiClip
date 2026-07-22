import AppKit
import Foundation

enum AppIconTheme: String, CaseIterable, Identifiable {
    static let defaultsKey = "appIconTheme"

    case pandaTyping = "panda-typing"
    case pandaBricks = "panda-bricks"
    case sealBalloon = "seal-balloon"
    case foxEnvelope = "fox-envelope"
    case owlChecklist = "owl-checklist"
    case otterTyping = "otter-typing"

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
        case .foxEnvelope: return L10n.foxEnvelope
        case .owlChecklist: return L10n.owlChecklist
        case .otterTyping: return L10n.otterTyping
        }
    }

    var appImage: NSImage? { image(named: rawValue) }

    var menuBarImage: NSImage? {
        guard let image = image(named: "\(rawValue)-menubar") else { return nil }
        // Menu bar assets are stored as 36 px Retina templates and displayed at
        // 18 pt. Setting the logical size explicitly prevents AppKit from
        // treating the backing pixels as points and resampling them softly.
        image.size = NSSize(width: 18, height: 18)
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
        let bundle = Self.resourceBundle
        let url = bundle.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "IconThemes"
        ) ?? bundle.url(forResource: name, withExtension: "png")
        guard let url else { return nil }
        return NSImage(contentsOf: url)
    }

    private static var resourceBundle: Bundle {
        if let resourcesURL = Bundle.main.resourceURL,
           let appBundle = Bundle(
               url: resourcesURL.appendingPathComponent("KuaiClip_KuaiClip.bundle")
           ) {
            return appBundle
        }
        return Bundle.module
    }
}
