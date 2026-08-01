import AppKit
import Foundation

enum AppIconTheme: String, CaseIterable, Identifiable {
    static let defaultsKey = "appIconTheme"
    private static let squirrelDefaultMigrationKey = "didMigrateToSquirrelDefaultIcon"

    case foxSolid = "fox-solid"
    case squirrelSolid = "squirrel-solid"
    case pandaSolid = "panda-solid"

    var id: String { rawValue }

    static var selected: AppIconTheme {
        if !UserDefaults.standard.bool(forKey: squirrelDefaultMigrationKey) {
            UserDefaults.standard.set(squirrelSolid.rawValue, forKey: defaultsKey)
            UserDefaults.standard.set(true, forKey: squirrelDefaultMigrationKey)
            return .squirrelSolid
        }
        let value = UserDefaults.standard.string(forKey: defaultsKey) ?? squirrelSolid.rawValue
        guard let theme = AppIconTheme(rawValue: value) else {
            UserDefaults.standard.set(squirrelSolid.rawValue, forKey: defaultsKey)
            return .squirrelSolid
        }
        return theme
    }

    var title: String {
        switch self {
        case .foxSolid: return L10n.foxSolid
        case .squirrelSolid: return L10n.squirrelSolid
        case .pandaSolid: return L10n.pandaSolid
        }
    }

    var appImage: NSImage? { image(named: rawValue) }

    var menuBarImage: NSImage? {
        guard let image = image(named: "\(rawValue)-menubar") else { return nil }
        // Menu bar assets are stored as Retina templates and displayed at
        // 18 pt high. Setting the logical size explicitly prevents AppKit from
        // treating the backing pixels as points and resampling them softly.
        image.size = self == .squirrelSolid
            ? NSSize(width: 30, height: 18)
            : NSSize(width: 18, height: 18)
        image.isTemplate = self != .pandaSolid
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
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle.main
#endif
    }
}
