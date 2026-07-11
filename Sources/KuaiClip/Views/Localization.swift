import Foundation

enum L10n {
    static var lang: String {
        get { UserDefaults.standard.string(forKey: "appLanguage") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "appLanguage") }
    }

    static var isJP: Bool { lang == "ja" }

    static func text(_ en: String, _ ja: String) -> String {
        isJP ? ja : en
    }

    static var general: String { text("General", "一般") }
    static var shortcuts: String { text("Shortcuts", "ショートカット") }
    static var about: String { text("About", "情報") }
    static var aiPolish: String { text("AI Polish", "AI文章校正") }
    static var aiProviders: String { text("AI Provider API Keys", "AIプロバイダーのAPIキー") }
    static var saveAPIKeys: String { text("Save API Keys", "APIキーを保存") }
    static var savedInKeychain: String { text("Saved securely in macOS Keychain", "macOSキーチェーンに安全に保存しました") }
    static var apiKeyPrivacy: String { text("Keys stay in macOS Keychain. Text is sent only to the provider selected when you polish it.", "キーはmacOSキーチェーンに保存されます。文章は校正時に選択したプロバイダーにのみ送信されます。") }
    static var polishText: String { text("Polish for work", "ビジネス文章を校正") }
    static var professionalPolish: String { text("Professional polish", "ビジネス文章校正") }
    static var aiModel: String { text("AI model", "AIモデル") }
    static var configureAIKey: String { text("Add an API key in Preferences → AI Polish first.", "先に設定 → AI文章校正でAPIキーを追加してください。") }
    static var polishedResultPlaceholder: String { text("The polished result will appear here.", "校正した文章がここに表示されます。") }
    static var aiKeyMissing: String { text("The API key for this provider is missing.", "このプロバイダーのAPIキーが設定されていません。") }
    static var aiInvalidResponse: String { text("The AI returned an unreadable response.", "AIから読み取れない応答が返されました。") }
    static var aiRequestFailed: String { text("The AI request failed.", "AIへのリクエストに失敗しました。") }
    static func polishTextTooLong(_ limit: Int) -> String {
        text(
            "This text is too long to polish. The limit is \(limit.formatted()) characters.",
            "文章が長すぎます。校正できる上限は\(limit.formatted())文字です。"
        )
    }
    static func characterCount(_ count: Int, limit: Int) -> String {
        text(
            "\(count.formatted()) / \(limit.formatted()) characters",
            "\(count.formatted()) / \(limit.formatted())文字"
        )
    }
    static var behavior: String { text("Behavior", "動作") }
    static var data: String { text("Data", "データ") }
    static var maxHistory: String { text("Max history", "最大履歴数") }
    static var maxHistoryDetail: String { text("Unpinned items kept (10–100)", "保持する未固定項目数（10～100）") }
    static var polling: String { text("Clipboard polling", "クリップボード監視間隔") }
    static var launchAtLogin: String { text("Launch at login", "ログイン時に起動") }
    static var stripFmt: String { text("Strip formatting by default", "デフォルトで書式なし貼り付け") }
    static var language: String { text("Language", "言語") }
    static var appIcon: String { text("App & Menu Bar Icon", "アプリとメニューバーのアイコン") }
    static var pandaTyping: String { text("Typing Panda", "タイピングパンダ") }
    static var pandaBricks: String { text("Brick Panda", "搬砖パンダ") }
    static var sealBalloon: String { text("Balloon Seal", "風船アザラシ") }
    static var historyItems: String { text("History items", "履歴項目") }
    static var clearAll: String { text("Clear All History", "すべての履歴を消去") }
    static var popupActivation: String { text("Popup Activation", "ポップアップ起動") }
    static var activationMode: String { text("Activation mode", "起動方法") }
    static var doubleTap: String { text("Double-tap Left ⌘", "左⌘をダブルタップ") }
    static var custom: String { text("Custom shortcut", "カスタムショートカット") }
    static var currentShortcut: String { text("Current shortcut", "現在のショートカット") }
    static var record: String { text("Record", "記録") }
    static var reset: String { text("Reset", "リセット") }
    static var pressKeys: String { text("Press keys…", "キーを押してください…") }
    static var withinPopup: String { text("Popup Actions", "ポップアップ内の操作") }
    static var accWarning: String { text("Accessibility permission is required; fallback shortcut is active.", "アクセシビリティ権限が必要です。現在は代替ショートカットを使用しています。") }
    static var search: String { text("Search…", "検索…") }
    static var noHistory: String { text("No clipboard history yet", "クリップボード履歴はまだありません") }
    static var noMatches: String { text("No matching items", "一致する項目がありません") }
    static var copyToStart: String { text("Copy something to get started", "何かをコピーすると履歴が始まります") }
    static func itemCount(_ count: Int) -> String { text("\(count) items", "\(count) 件") }
    static func pinnedCount(_ count: Int) -> String { text("• \(count) pinned", "• 固定 \(count) 件") }
    static var clearUnpinned: String { text("Clear Unpinned Items", "未固定項目を消去") }
    static var clearAllItems: String { text("Clear All Items", "すべての項目を消去") }
    static var preferences: String { text("Preferences…", "設定…") }
    static var preferencesTitle: String { text("KuaiClip Preferences", "KuaiClip 設定") }
    static var quit: String { text("Quit KuaiClip", "KuaiClip を終了") }
    static var pin: String { text("Pin", "固定") }
    static var unpin: String { text("Unpin", "固定解除") }
    static var showContent: String { text("Show Content", "内容を表示") }
    static var hideContent: String { text("Hide Content", "内容を隠す") }
    static var delete: String { text("Delete", "削除") }
    static var pinLimitTitle: String { text("Pinned item limit reached", "固定項目の上限") }
    static var pinLimitMessage: String { text("You can pin up to 10 items. Unpin an existing item before adding another.", "固定できる項目は10件までです。新しく固定する前に、既存の固定項目を解除してください。") }
    static var ok: String { text("OK", "OK") }
    static var themeHelp: String { text("Toggle appearance: light or dark", "外観を切り替え：ライト / ダーク") }
    static var appDescription: String { text("Clipboard Manager for macOS", "macOS用クリップボードマネージャー") }
    static var empty: String { text("(empty)", "（空）") }
    static var image: String { text("Image", "画像") }
    static var dataContent: String { text("Data", "データ") }
    static var doubleTapCommand: String { text("Double-tap Left ⌘", "左⌘をダブルタップ") }
    static var needsPermission: String { text("needs permission", "権限が必要") }

    static var copySelected: String { text("Copy selected", "選択項目をコピー") }
    static var copyPaste: String { text("Copy & paste", "コピーして貼り付け") }
    static var pastePlain: String { text("Paste without formatting", "書式なしで貼り付け") }
    static var copyNumber: String { text("Copy unpinned item 1–9", "未固定項目 1〜9 をコピー") }
    static var copyPinnedLetter: String { text("Copy pinned item a–j", "固定項目 a〜j をコピー") }
    static var deleteSelected: String { text("Delete selected", "選択項目を削除") }
    static var pinUnpin: String { text("Pin / unpin", "固定 / 固定解除") }
    static var dismiss: String { text("Dismiss", "閉じる") }

    static var accessibilityTitle: String { text("Enable Double-Tap ⌘?", "⌘ ダブルタップを有効にしますか？") }
    static var accessibilityBody: String {
        text(
            "Double-tap Left Command needs Accessibility permission.\n\nCurrent shortcut: ⇧⌘C (works immediately)\n\nGrant permission in System Settings → Privacy & Security → Accessibility, then restart KuaiClip.\n\nYou can also select a custom shortcut in Preferences (⌘,).",
            "左 Command のダブルタップにはアクセシビリティ権限が必要です。\n\n現在のショートカット：⇧⌘C（すぐに使用できます）\n\nシステム設定 → プライバシーとセキュリティ → アクセシビリティで権限を許可し、KuaiClip を再起動してください。\n\n設定（⌘,）でカスタムショートカットを選ぶこともできます。"
        )
    }
    static var openSystemSettings: String { text("Open System Settings", "システム設定を開く") }
    static var useFallback: String { text("Use ⇧⌘C (Default)", "⇧⌘C を使用（デフォルト）") }
    static var openPreferences: String { text("Open Preferences", "設定を開く") }

    static func timeAgo(_ interval: TimeInterval, date: Date) -> String {
        if interval < 60 { return text("Just now", "たった今") }
        if interval < 3600 { return text("\(Int(interval / 60))m ago", "\(Int(interval / 60))分前") }
        if interval < 86400 { return text("\(Int(interval / 3600))h ago", "\(Int(interval / 3600))時間前") }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJP ? "ja_JP" : "en_US")
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
