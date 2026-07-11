import SwiftUI
import AppKit

enum AppTheme: String {
    case light
    case dark

    init(_ storedValue: String) {
        self = storedValue == AppTheme.dark.rawValue || storedValue == "gray" ? .dark : .light
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var background: Color {
        switch self {
        case .light: return Color(red: 1, green: 1, blue: 1)
        case .dark: return Color(red: 24.0 / 255, green: 24.0 / 255, blue: 24.0 / 255)
        }
    }

    var foreground: Color {
        switch self {
        case .light: return Color(red: 26.0 / 255, green: 28.0 / 255, blue: 31.0 / 255)
        case .dark: return .white
        }
    }

    var secondaryForeground: Color {
        foreground.opacity(0.7)
    }

    var selectionBackground: Color {
        switch self {
        case .light: return Color(red: 229.0 / 255, green: 243.0 / 255, blue: 1)
        case .dark: return Color(red: 0, green: 40.0 / 255, blue: 77.0 / 255)
        }
    }

    var accent: Color {
        switch self {
        case .light: return Color(red: 51.0 / 255, green: 156.0 / 255, blue: 1)
        case .dark: return Color(red: 153.0 / 255, green: 206.0 / 255, blue: 1)
        }
    }

    var border: Color {
        switch self {
        case .light: return foreground.opacity(0.20)
        case .dark: return .white.opacity(0.20)
        }
    }

    var divider: Color {
        switch self {
        case .light: return foreground.opacity(0.05)
        case .dark: return .white.opacity(0.04)
        }
    }

    func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    func codeFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    @MainActor
    static func migrateStoredAppearance(defaults: UserDefaults = .standard) -> String {
        let theme = AppTheme(defaults.string(forKey: "appearanceMode") ?? AppTheme.light.rawValue)
        defaults.set(theme.rawValue, forKey: "appearanceMode")
        return theme.rawValue
    }

    @MainActor
    static func applyAppearance(_ storedValue: String) {
        switch AppTheme(storedValue) {
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        }
    }
}
