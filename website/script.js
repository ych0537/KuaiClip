const common = {
  zh: {
    navFeatures: "功能", navPrivacy: "隐私", navDownload: "下载", nativeBadge: "0.7 · 为 macOS 原生打造",
    headline: "让复制粘贴<br><span>快一点。</span>", lead: "在菜单栏中搜索、固定并快速粘贴剪贴板历史。轻巧、原生，重要内容留在你的 Mac 上。",
    downloadButton: "免费下载", sourceButton: "查看源代码 ↗", requirements: "适用于 macOS 14 Sonoma 及更高版本 · MIT 开源",
    shortcutHint: "双击左 Command，随时呼出", trustNative: "原生 Swift", trustNativeSub: "不是 Electron",
    trustLocal: "本地优先", trustLocalSub: "历史保存在设备上", trustLanguages: "三种语言", trustOpen: "开源免费",
    featureEyebrow: "更少打断，更多专注", featureTitle: "需要的内容，就在指尖。", searchTitle: "瞬间找到",
    searchText: "输入即筛选。文本、链接、文件路径和图片，都能快速回到手边。", keyboardTitle: "键盘优先",
    keyboardText: "方向键选择，Enter 复制，Option + Enter 直接粘贴。工作流无需离开键盘。",
    aiTitle: "更聪明的 AI 润色", aiText: "自动识别自然语言，命令、URL、代码与结构化数据不会出现不必要的润色按钮。",
    pinTitle: "常用内容置顶", pinText: "固定最多 10 条常用片段，以 A–J 快捷键随时取用。",
    jsonTitle: "JSON 一键整形", jsonText: "自动识别有效 JSON，一键格式化、复制并保存到剪贴板历史。",
    themeTitle: "六套柔和配色", themeText: "白色、浅蓝、薄荷绿、暖米色、淡紫与黑色主题，在右上角一键循环切换。",
    previewTitle: "清晰紧凑的预览", previewText: "更高效的列表布局、单行序号与放大图片缩略图，让窗口空间真正用于内容。",
    privacyEyebrow: "隐私不是附加功能", privacyTitle: "你的剪贴板，<br>留在你的 Mac。",
    privacyText: "历史数据存储在本机，不上传遥测或剪贴板内容。AI 润色仅在你主动点击时连接服务商，API 密钥由 macOS 钥匙串保护。",
    privacyLink: "阅读隐私说明 ↗", privacyOne: "无自动遥测上传", privacyTwo: "本地剪贴板历史",
    privacyThree: "敏感内容可隐藏", privacyFour: "AI 密钥存储在钥匙串", downloadTitle: "今天开始，让粘贴更快。",
    downloadText: "免费下载。原生、轻巧、开源。"
  },
  ja: {
    navFeatures: "機能", navPrivacy: "プライバシー", navDownload: "ダウンロード", nativeBadge: "0.7 · macOS のためのネイティブ設計",
    headline: "コピー＆ペーストを<br><span>もっと速く。</span>", lead: "メニューバーから履歴を検索、ピン留め、すぐにペースト。軽量でネイティブ。大切なデータは Mac の中に。",
    downloadButton: "無料でダウンロード", sourceButton: "ソースを見る ↗", requirements: "macOS 14 Sonoma 以降 · MIT オープンソース",
    shortcutHint: "左 Command を2回押して表示", trustNative: "Native Swift", trustNativeSub: "Electron 不使用",
    trustLocal: "ローカル優先", trustLocalSub: "履歴は端末内に保存", trustLanguages: "3言語対応", trustOpen: "無料・OSS",
    featureEyebrow: "中断を減らし、集中を深める", featureTitle: "欲しいものを、指先に。", searchTitle: "一瞬で見つかる",
    searchText: "入力と同時に絞り込み。テキスト、リンク、ファイルパス、画像をすぐに呼び戻せます。", keyboardTitle: "キーボード中心",
    keyboardText: "矢印で選択、Enter でコピー、Option + Enter で直接ペースト。",
    aiTitle: "賢い AI 文章校正", aiText: "自然言語だけを判定し、コマンド、URL、コード、構造化データには校正ボタンを表示しません。",
    pinTitle: "よく使う項目を固定", pinText: "最大10件をピン留めし、A〜Jのショートカットで呼び出せます。",
    jsonTitle: "JSON をワンクリック整形", jsonText: "有効な JSON を認識し、整形・コピーして履歴にも保存します。",
    themeTitle: "6つのやさしい配色", themeText: "ホワイト、スカイ、ミント、サンド、ラベンダー、ダークを順番に切り替えられます。",
    previewTitle: "見やすくコンパクト", previewText: "効率的なリスト、折り返さない番号、大きな画像サムネイルで内容を見やすくしました。",
    privacyEyebrow: "プライバシーは基本機能", privacyTitle: "クリップボードは、<br>あなたの Mac に。",
    privacyText: "履歴はローカル保存。テレメトリや内容を自動送信しません。AIは操作した時だけ接続し、APIキーはキーチェーンで保護します。",
    privacyLink: "プライバシーの詳細 ↗", privacyOne: "自動テレメトリなし", privacyTwo: "ローカル履歴",
    privacyThree: "機密内容を非表示", privacyFour: "APIキーはキーチェーンへ", downloadTitle: "今日から、ペーストを速く。",
    downloadText: "無料、ネイティブ、オープンソース。"
  },
  en: {
    navFeatures: "Features", navPrivacy: "Privacy", navDownload: "Download", nativeBadge: "0.7 · Native for macOS",
    headline: "Copy and paste.<br><span>Only faster.</span>", lead: "Search, pin, and instantly paste your clipboard history from the menu bar. Lightweight, native, and designed to keep important data on your Mac.",
    downloadButton: "Download free", sourceButton: "View source ↗", requirements: "Requires macOS 14 Sonoma or later · MIT open source",
    shortcutHint: "Double-tap Left Command, anytime", trustNative: "Native Swift", trustNativeSub: "No Electron",
    trustLocal: "Local-first", trustLocalSub: "History stays on-device", trustLanguages: "Three languages", trustOpen: "Free & open",
    featureEyebrow: "Fewer interruptions, more focus", featureTitle: "What you need, at your fingertips.", searchTitle: "Find it instantly",
    searchText: "Filter as you type. Text, links, file paths, and images are always easy to bring back.", keyboardTitle: "Keyboard-first",
    keyboardText: "Arrow keys to select, Enter to copy, Option + Enter to paste directly. Never leave the keyboard.",
    aiTitle: "Smarter AI polish", aiText: "Natural-language detection hides polish actions for commands, URLs, code, and structured data.",
    pinTitle: "Pin what matters", pinText: "Keep up to 10 frequent snippets ready with dedicated A–J shortcuts.",
    jsonTitle: "One-click JSON formatting", jsonText: "Recognize valid JSON, pretty-print it, copy it, and keep the formatted result in history.",
    themeTitle: "Six gentle color themes", themeText: "Cycle through White, Sky, Mint, Sand, Lavender, and Dark from the popup.",
    previewTitle: "Clear, compact previews", previewText: "A denser list, single-line numbering, and larger image thumbnails make better use of the window.",
    privacyEyebrow: "Privacy is not an add-on", privacyTitle: "Your clipboard stays<br>on your Mac.",
    privacyText: "History is stored locally with no telemetry or clipboard uploads. AI connects only when you ask, and API keys are protected by macOS Keychain.",
    privacyLink: "Read the privacy details ↗", privacyOne: "No automatic telemetry", privacyTwo: "Local clipboard history",
    privacyThree: "Hide sensitive content", privacyFour: "Keychain-protected API keys", downloadTitle: "Paste faster, starting today.",
    downloadText: "Free. Native. Open source."
  }
};

function setLanguage(lang) {
  document.documentElement.lang = lang === "zh" ? "zh-CN" : lang;
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const value = common[lang][element.dataset.i18n];
    if (value) element.innerHTML = value;
  });
  localStorage.setItem("kuaiclip-language", lang);
}

const language = document.querySelector("#language");
const browserLanguage = navigator.language || "";
language.value = localStorage.getItem("kuaiclip-language") || (browserLanguage.startsWith("ja") ? "ja" : browserLanguage.startsWith("zh") ? "zh" : "en");
setLanguage(language.value);
language.addEventListener("change", (event) => setLanguage(event.target.value));

const themeSlides = [...document.querySelectorAll("[data-theme-slide]")];
const themeButtons = [...document.querySelectorAll("[data-theme-target]")];
let activeTheme = "light";
let themeTimer;

function showTheme(theme) {
  activeTheme = theme;
  themeSlides.forEach((slide) => slide.classList.toggle("is-active", slide.dataset.themeSlide === theme));
  themeButtons.forEach((button) => {
    const selected = button.dataset.themeTarget === theme;
    button.classList.toggle("is-active", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
}

function startThemeRotation() {
  clearInterval(themeTimer);
  if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    themeTimer = setInterval(() => showTheme(activeTheme === "light" ? "dark" : "light"), 4200);
  }
}

themeButtons.forEach((button) => button.addEventListener("click", () => {
  showTheme(button.dataset.themeTarget);
  startThemeRotation();
}));
const themeCarousel = document.querySelector(".theme-carousel");
themeCarousel.addEventListener("mouseenter", () => clearInterval(themeTimer));
themeCarousel.addEventListener("mouseleave", startThemeRotation);
startThemeRotation();
