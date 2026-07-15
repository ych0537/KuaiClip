import SwiftUI
import AppKit

enum AppTheme: String, CaseIterable {
    case light
    case sky
    case mint
    case sand
    case lavender
    case dark

    init(_ storedValue: String) {
        self = storedValue == "gray" ? .dark : AppTheme(rawValue: storedValue) ?? .light
    }

    var next: AppTheme {
        let themes = Self.allCases
        let index = themes.firstIndex(of: self) ?? 0
        return themes[(index + 1) % themes.count]
    }

    private var isDark: Bool { self == .dark }

    var colorScheme: ColorScheme {
        isDark ? .dark : .light
    }

    var background: Color {
        switch self {
        case .light: return Color(red: 1, green: 1, blue: 1)
        case .sky: return Color(red: 246.0 / 255, green: 252.0 / 255, blue: 1)
        case .mint: return Color(red: 247.0 / 255, green: 252.0 / 255, blue: 249.0 / 255)
        case .sand: return Color(red: 1, green: 252.0 / 255, blue: 244.0 / 255)
        case .lavender: return Color(red: 252.0 / 255, green: 249.0 / 255, blue: 1)
        case .dark: return Color(red: 24.0 / 255, green: 24.0 / 255, blue: 24.0 / 255)
        }
    }

    var panelBackground: Color {
        switch self {
        case .light: return Color(red: 244.0 / 255, green: 248.0 / 255, blue: 250.0 / 255)
        case .sky: return Color(red: 233.0 / 255, green: 247.0 / 255, blue: 252.0 / 255)
        case .mint: return Color(red: 235.0 / 255, green: 248.0 / 255, blue: 241.0 / 255)
        case .sand: return Color(red: 249.0 / 255, green: 243.0 / 255, blue: 231.0 / 255)
        case .lavender: return Color(red: 245.0 / 255, green: 239.0 / 255, blue: 251.0 / 255)
        case .dark: return Color(red: 20.0 / 255, green: 21.0 / 255, blue: 23.0 / 255)
        }
    }

    var groupBackground: Color {
        isDark ? .white.opacity(0.055) : .white.opacity(0.76)
    }

    var foreground: Color {
        isDark ? .white : Color(red: 26.0 / 255, green: 28.0 / 255, blue: 31.0 / 255)
    }

    var secondaryForeground: Color {
        foreground.opacity(0.7)
    }

    var selectionBackground: Color {
        switch self {
        case .light: return Color(red: 218.0 / 255, green: 240.0 / 255, blue: 246.0 / 255)
        case .sky: return Color(red: 207.0 / 255, green: 236.0 / 255, blue: 247.0 / 255)
        case .mint: return Color(red: 211.0 / 255, green: 239.0 / 255, blue: 225.0 / 255)
        case .sand: return Color(red: 243.0 / 255, green: 230.0 / 255, blue: 200.0 / 255)
        case .lavender: return Color(red: 231.0 / 255, green: 218.0 / 255, blue: 246.0 / 255)
        case .dark: return Color(red: 32.0 / 255, green: 57.0 / 255, blue: 65.0 / 255)
        }
    }

    var accent: Color {
        switch self {
        case .light: return Color(red: 51.0 / 255, green: 156.0 / 255, blue: 1)
        case .sky: return Color(red: 30.0 / 255, green: 139.0 / 255, blue: 190.0 / 255)
        case .mint: return Color(red: 35.0 / 255, green: 148.0 / 255, blue: 101.0 / 255)
        case .sand: return Color(red: 184.0 / 255, green: 120.0 / 255, blue: 37.0 / 255)
        case .lavender: return Color(red: 132.0 / 255, green: 88.0 / 255, blue: 188.0 / 255)
        case .dark: return Color(red: 153.0 / 255, green: 206.0 / 255, blue: 1)
        }
    }

    var border: Color {
        isDark ? .white.opacity(0.12) : foreground.opacity(0.10)
    }

    var divider: Color {
        isDark ? .white.opacity(0.07) : foreground.opacity(0.075)
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
        case .light, .sky, .mint, .sand, .lavender: NSApp.appearance = NSAppearance(named: .aqua)
        }
    }
}
