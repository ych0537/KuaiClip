import Foundation

enum L10n {
    static var lang: String {
        get { UserDefaults.standard.string(forKey: "appLanguage") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "appLanguage") }
    }

    static var isJP: Bool { lang == "ja" }
    static var isZH: Bool { lang == "zh" }

    static func text(_ en: String, _ ja: String, _ zh: String? = nil) -> String {
        if isJP { return ja }
        if isZH { return zh ?? chineseTranslations[en] ?? en }
        return en
    }

    private static let chineseTranslations: [String: String] = [
        "General": "通用", "Shortcuts": "快捷键", "About": "关于",
        "AI Polish": "AI 润色", "AI Providers": "AI 服务商",
        "AI provider": "AI 服务商", "API key": "API Key", "Save API Key": "保存 API Key",
        "Apple Intelligence is ready.": "Apple Intelligence 已就绪。",
        "Apple Intelligence is unavailable on this Mac.": "这台 Mac 上的 Apple Intelligence 不可用。",
        "Apple Intelligence runs on device and does not require an API key.": "Apple Intelligence 在设备端运行，不需要 API Key。",
        "Ollama model": "Ollama 模型", "Refresh Ollama models": "刷新 Ollama 模型",
        "No local models found": "未找到本地模型", "Cannot connect to local Ollama.": "无法连接本地 Ollama。",
        "Ollama runs locally and does not require an API key.": "Ollama 在本机运行，不需要 API Key。",
        "Delete API Key": "删除 API Key", "API key deleted from macOS Keychain": "已从 macOS 钥匙串删除 API Key",
        "Save API Keys": "保存 API Key", "Saved securely in macOS Keychain": "已安全保存到 macOS 钥匙串",
        "Keys stay in macOS Keychain. Text is sent only to the provider selected when you polish it.": "Key 仅保存在 macOS 钥匙串。只有主动润色时，文本才会发送给所选服务商。",
        "Polish for work": "职场润色", "Professional polish": "职场润色", "AI model": "AI 模型",
        "Add an API key in Preferences → AI Polish first.": "请先在设置 → AI 润色中添加 API Key。",
        "The polished result will appear here.": "润色后的内容会显示在这里。",
        "The API key for this provider is missing.": "尚未设置此服务商的 API Key。",
        "The AI returned an unreadable response.": "AI 返回了无法读取的结果。",
        "The AI request failed.": "AI 请求失败。", "Behavior": "行为", "Data": "数据",
        "Max history": "最大历史记录", "Unpinned items kept (10–100)": "保留的未固定项目（10–100）",
        "Clipboard polling": "剪贴板检查间隔", "Launch at login": "登录时启动",
        "Strip formatting by default": "默认移除格式", "Language": "语言",
        "App & Menu Bar Icon": "App 与菜单栏图标", "Typing Panda": "打字熊猫",
        "Brick Panda": "搬砖熊猫", "Balloon Seal": "顶气球海豹", "Mail Fox": "邮件狐狸",
        "Checklist Owl": "清单猫头鹰", "Typing Otter": "打字水獭", "History items": "历史项目",
        "Clear All History": "清空全部历史", "Popup Activation": "弹窗启动",
        "Activation mode": "启动方式", "Double-tap Left ⌘": "双击左侧 ⌘",
        "Custom shortcut": "自定义快捷键", "Current shortcut": "当前快捷键", "Record": "录制",
        "Reset": "重置", "Press keys…": "请按快捷键…", "Popup Actions": "弹窗内操作",
        "Accessibility permission is required; fallback shortcut is active.": "需要辅助功能权限；当前正在使用备用快捷键。",
        "Search…": "搜索…", "No clipboard history yet": "暂无剪贴板历史",
        "No matching items": "没有匹配项目", "Copy something to get started": "复制一些内容即可开始",
        "Clear Unpinned Items": "清除未固定项目", "Clear All Items": "清除全部项目",
        "Preferences…": "设置…", "KuaiClip Preferences": "KuaiClip 设置", "Quit KuaiClip": "退出 KuaiClip",
        "Pin": "固定", "Unpin": "取消固定", "Show Content": "显示内容", "Hide Content": "隐藏内容",
        "Delete": "删除", "Pinned item limit reached": "已达到固定项目上限",
        "You can pin up to 10 items. Unpin an existing item before adding another.": "最多可以固定 10 个项目。请先取消一个已有固定项目，再添加新的项目。",
        "OK": "好", "Toggle appearance: light or dark": "切换浅色或深色外观",
        "Clipboard Manager for macOS": "macOS 剪贴板管理器", "(empty)": "（空）", "Image": "图片",
        "needs permission": "需要权限", "Copy selected": "复制所选项目", "Copy & paste": "复制并粘贴",
        "Paste without formatting": "无格式粘贴", "Copy unpinned item 1–9": "复制未固定项目 1–9",
        "Copy pinned item a–j": "复制固定项目 a–j", "Delete selected": "删除所选项目",
        "Pin / unpin": "固定 / 取消固定", "Dismiss": "关闭", "Enable Double-Tap ⌘?": "启用双击 ⌘？",
        "Open System Settings": "打开系统设置", "Use ⇧⌘C (Default)": "使用 ⇧⌘C（默认）",
        "Open Preferences": "打开设置", "Local Usage": "本机使用统计",
        "Popup opens": "主窗口打开次数", "Polish window opens": "润色窗口打开次数",
        "Polish runs": "实际润色次数", "Tracking since": "统计开始日期",
        "Not started yet": "尚未开始", "Copy Usage Data": "复制使用数据",
        "Reset Usage Data": "重置使用统计", "Usage data copied": "使用数据已复制",
        "Reset local usage data?": "重置本机使用统计？",
        "This clears only the local counters. Clipboard history and settings are not affected.": "只会清除本机计数，不影响剪贴板历史和设置。",
        "Usage counts stay on this Mac and are never uploaded automatically.": "使用次数仅保存在本机，绝不会自动上传。",
        "Cancel": "取消", "Format JSON and copy": "格式化 JSON 并复制",
        "Recognize Text": "识别文字", "Recognizing text…": "正在识别文字…",
        "Recognized Text": "识别结果", "Copy Text": "复制文字",
        "No text was found in this image.": "未在图片中识别到文字。",
        "Text Recognition Failed": "文字识别失败",
        "Unable to recognize text in this image.": "无法识别此图片中的文字。"
    ]

    static var general: String { text("General", "一般") }
    static var shortcuts: String { text("Shortcuts", "ショートカット") }
    static var about: String { text("About", "情報") }
    static var aiPolish: String { text("AI Polish", "AI文章校正") }
    static var aiProviders: String { text("AI Providers", "AIプロバイダー") }
    static var aiProvider: String { text("AI provider", "AIプロバイダー") }
    static var apiKey: String { text("API key", "APIキー") }
    static var ollamaModel: String { text("Ollama model", "Ollamaモデル") }
    static var refreshOllamaModels: String { text("Refresh Ollama models", "Ollamaモデルを更新") }
    static var noOllamaModels: String { text("No local models found", "ローカルモデルが見つかりません") }
    static var ollamaUnavailable: String { text("Cannot connect to local Ollama.", "ローカルOllamaに接続できません。") }
    static var ollamaLocalPrivacy: String { text("Ollama runs locally and does not require an API key.", "Ollamaはローカルで動作し、APIキーは不要です。") }
    static var saveAPIKey: String { text("Save API Key", "APIキーを保存") }
    static var deleteAPIKey: String { text("Delete API Key", "APIキーを削除") }
    static var saveAPIKeys: String { text("Save API Keys", "APIキーを保存") }
    static var savedInKeychain: String { text("Saved securely in macOS Keychain", "macOSキーチェーンに安全に保存しました") }
    static var deletedFromKeychain: String { text("API key deleted from macOS Keychain", "macOSキーチェーンからAPIキーを削除しました") }
    static var apiKeyPrivacy: String { text("Keys stay in macOS Keychain. Text is sent only to the provider selected when you polish it.", "キーはmacOSキーチェーンに保存されます。文章は校正時に選択したプロバイダーにのみ送信されます。") }
    static var polishText: String { text("Polish for work", "ビジネス文章を校正") }
    static var professionalPolish: String { text("Professional polish", "ビジネス文章校正") }
    static var polishAction: String { text("Polish", "校正する", "润色") }
    static var formatJSONAndCopy: String { text("Format JSON and copy", "JSONを整形してコピー", "格式化 JSON 并复制") }
    static var aiModel: String { text("AI model", "AIモデル") }
    static var configureAIKey: String { text("Add an API key in Preferences → AI Polish first.", "先に設定 → AI文章校正でAPIキーを追加してください。") }
    static var polishedResultPlaceholder: String { text("The polished result will appear here.", "校正した文章がここに表示されます。") }
    static var aiKeyMissing: String { text("The API key for this provider is missing.", "このプロバイダーのAPIキーが設定されていません。") }
    static var aiInvalidResponse: String { text("The AI returned an unreadable response.", "AIから読み取れない応答が返されました。") }
    static var aiRequestFailed: String { text("The AI request failed.", "AIへのリクエストに失敗しました。") }
    static var appleIntelligenceReady: String { text("Apple Intelligence is ready.", "Apple Intelligenceを使用できます。") }
    static var appleIntelligenceUnavailable: String { text("Apple Intelligence is unavailable on this Mac.", "このMacではApple Intelligenceを使用できません。") }
    static var appleIntelligencePrivacy: String { text("Apple Intelligence runs on device and does not require an API key.", "Apple Intelligenceはデバイス上で動作し、APIキーは不要です。") }
    static func polishTextTooLong(_ limit: Int) -> String {
        text(
            "This text is too long to polish. The limit is \(limit.formatted()) characters.",
            "文章が長すぎます。校正できる上限は\(limit.formatted())文字です。",
            "文本过长，最多可润色 \(limit.formatted()) 个字符。"
        )
    }
    static func characterCount(_ count: Int, limit: Int) -> String {
        text(
            "\(count.formatted()) / \(limit.formatted()) characters",
            "\(count.formatted()) / \(limit.formatted())文字",
            "\(count.formatted()) / \(limit.formatted()) 个字符"
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
    static var foxEnvelope: String { text("Mail Fox", "メールキツネ") }
    static var owlChecklist: String { text("Checklist Owl", "チェックフクロウ") }
    static var otterTyping: String { text("Typing Otter", "タイピングカワウソ") }
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
    static func itemCount(_ count: Int) -> String { text("\(count) items", "\(count) 件", "\(count) 项") }
    static func pinnedCount(_ count: Int) -> String { text("• \(count) pinned", "• 固定 \(count) 件", "• 已固定 \(count) 项") }
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
    static var themeHelp: String { text("Cycle color theme", "カラーテーマを切り替え", "循环切换颜色主题") }
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
            "左 Command のダブルタップにはアクセシビリティ権限が必要です。\n\n現在のショートカット：⇧⌘C（すぐに使用できます）\n\nシステム設定 → プライバシーとセキュリティ → アクセシビリティで権限を許可し、KuaiClip を再起動してください。\n\n設定（⌘,）でカスタムショートカットを選ぶこともできます。",
            "双击左侧 Command 需要辅助功能权限。\n\n当前快捷键：⇧⌘C（可立即使用）\n\n请前往系统设置 → 隐私与安全性 → 辅助功能授予权限，然后重启 KuaiClip。\n\n也可以在设置（⌘,）中选择自定义快捷键。"
        )
    }
    static var openSystemSettings: String { text("Open System Settings", "システム設定を開く") }
    static var useFallback: String { text("Use ⇧⌘C (Default)", "⇧⌘C を使用（デフォルト）") }
    static var openPreferences: String { text("Open Preferences", "設定を開く") }
    static var localUsage: String { text("Local Usage", "このMacでの利用状況") }
    static var popupOpens: String { text("Popup opens", "ポップアップ表示回数") }
    static var polishWindowOpens: String { text("Polish window opens", "校正画面の表示回数") }
    static var polishRuns: String { text("Polish runs", "校正実行回数") }
    static var trackingSince: String { text("Tracking since", "集計開始日") }
    static var notStartedYet: String { text("Not started yet", "まだ開始していません") }
    static var copyUsageData: String { text("Copy Usage Data", "利用データをコピー") }
    static var resetUsageData: String { text("Reset Usage Data", "利用データをリセット") }
    static var usageDataCopied: String { text("Usage data copied", "利用データをコピーしました") }
    static var resetUsageTitle: String { text("Reset local usage data?", "このMacの利用データをリセットしますか？") }
    static var resetUsageMessage: String {
        text(
            "This clears only the local counters. Clipboard history and settings are not affected.",
            "このMacのカウンターだけを消去します。クリップボード履歴と設定には影響しません。"
        )
    }
    static var usagePrivacy: String {
        text(
            "Usage counts stay on this Mac and are never uploaded automatically.",
            "利用回数はこのMacにのみ保存され、自動送信されることはありません。"
        )
    }
    static var cancel: String { text("Cancel", "キャンセル") }
    static var takeScreenshot: String { text("Take Screenshot…", "スクリーンショット…", "截图…") }
    static var screenshotShortcut: String { text("Screenshot", "スクリーンショット", "截图") }
    static var screenshotShortcutHelp: String { text("Opens a menu for region, window, or full-screen capture.", "範囲・ウィンドウ・全画面の撮影メニューを開きます。", "打开区域、窗口或全屏截图菜单。") }
    static var shortcutConflictTitle: String { text("Shortcut already in use", "ショートカットが重複しています", "快捷键已被使用") }
    static var shortcutConflictMessage: String { text("The clipboard popup and screenshot shortcuts must be different.", "クリップボードとスクリーンショットには異なるショートカットを設定してください。", "剪贴板窗口与截图不能使用相同的快捷键。") }
    static var captureRegion: String { text("Capture Region", "範囲を撮影", "区域截图") }
    static var captureWindow: String { text("Capture Window", "ウィンドウを撮影", "窗口截图") }
    static var captureFullScreen: String { text("Capture Full Screen", "全画面を撮影", "全屏截图") }
    static var screenshotEditor: String { text("Screenshot Editor", "スクリーンショット編集", "截图编辑") }
    static var screenshotFailed: String { text("Screenshot Failed", "スクリーンショットに失敗しました", "截图失败") }
    static var download: String { text("Download", "ダウンロード", "下载") }
    static var copy: String { text("Copy", "コピー", "复制") }
    static var undo: String { text("Undo", "取り消す", "撤销") }
    static var clearAnnotations: String { text("Clear annotations", "注釈をすべて消去", "清除标注") }
    static var enterText: String { text("Enter annotation text", "注釈テキストを入力", "输入标注文字") }
    static var annotationRectangle: String { text("Rectangle", "四角形", "矩形") }
    static var annotationEllipse: String { text("Ellipse", "楕円", "圆形") }
    static var annotationLine: String { text("Line", "直線", "直线") }
    static var annotationArrow: String { text("Arrow", "矢印", "箭头") }
    static var annotationPen: String { text("Pen", "ペン", "画笔") }
    static var annotationMosaic: String { text("Mosaic", "モザイク", "马赛克") }
    static var annotationText: String { text("Text", "テキスト", "文字") }
    static var annotationNumber: String { text("Number", "番号", "编号") }
    static var ocrAction: String { text("Recognize Text", "テキストを認識", "识别文字") }
    static var ocrRecognizing: String { text("Recognizing text…", "テキストを認識中…", "正在识别文字…") }
    static var ocrResultTitle: String { text("Recognized Text", "認識したテキスト", "识别结果") }
    static var ocrCopy: String { text("Copy Text", "テキストをコピー", "复制文字") }
    static var ocrNoText: String {
        text("No text was found in this image.", "画像内にテキストが見つかりませんでした。", "未在图片中识别到文字。")
    }
    static var ocrFailedTitle: String { text("Text Recognition Failed", "テキスト認識に失敗", "文字识别失败") }
    static var ocrFailed: String {
        text("Unable to recognize text in this image.", "画像内のテキストを認識できませんでした。", "无法识别此图片中的文字。")
    }

    static func timeAgo(_ interval: TimeInterval, date: Date) -> String {
        if interval < 60 { return text("Just now", "たった今", "刚刚") }
        if interval < 3600 { return text("\(Int(interval / 60))m ago", "\(Int(interval / 60))分前", "\(Int(interval / 60)) 分钟前") }
        if interval < 86400 { return text("\(Int(interval / 3600))h ago", "\(Int(interval / 3600))時間前", "\(Int(interval / 3600)) 小时前") }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJP ? "ja_JP" : (isZH ? "zh_CN" : "en_US"))
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
