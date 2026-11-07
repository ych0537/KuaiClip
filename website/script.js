const common = {
  zh: {
    navFeatures: "功能", navKeys: "快捷键", navPrivacy: "隐私", langLabel: "语言",
    headline: "复制粘贴，<br>再快<em>一点</em>",
    lead: "在菜单栏中搜索、固定并快速粘贴剪贴板历史。原生 Swift 编写，数据只留在你的 Mac 上。",
    downloadButton: "下载最新版", sourceButton: "查看源代码", copy: "复制", copied: "已复制",
    shortcutHint: "双击左 Command 呼出",
    specRuntime: "原生 Swift · 不是 Electron", specStorage: "本地优先 · 历史保存在设备上", specLicense: "MIT · 免费开源",
    featureTitle: "需要的内容，就在指尖。",
    searchTitle: "瞬间找到", searchText: "输入即筛选。文本、链接、文件路径和图片，都能快速回到手边。",
    keyboardTitle: "键盘优先", keyboardText: "方向键选择，Enter 复制，Option + Enter 直接粘贴。工作流无需离开键盘。",
    aiTitle: "聪明的 AI 润色", aiText: "只对自然语言显示润色按钮；命令、URL、代码与结构化数据不会被打扰。",
    pinTitle: "常用内容置顶", pinText: "固定最多 10 条常用片段，以 A–J 快捷键随时取用。",
    jsonTitle: "JSON 一键整形", jsonText: "自动识别有效 JSON，一键格式化、复制并保存到剪贴板历史。",
    ocrTitle: "本机图片识别", ocrText: "使用 Apple Vision 在本机提取图片中的文字，原图不上传。",
    themeTitle: "六套配色", themeText: "白色、浅蓝、薄荷绿、暖米色、淡紫与黑色主题，一键循环切换。",
    screenshotTitle: "截图与标注", screenshotText: "截取区域、窗口或全屏，添加图形、箭头、画笔、马赛克、文字和编号，再保存或复制。",
    keysTitle: "手不用离开键盘。",
    keySummon: "呼出剪贴板历史（双击左 Command）", keySelect: "选择条目", keyCopy: "复制到剪贴板",
    keyPaste: "直接粘贴到当前应用", keyPinned: "取用固定的片段",
    privacyTitle: "你的剪贴板，<br>留在你的 Mac。",
    privacyText: "历史数据存储在本机，不上传遥测或剪贴板内容。AI 润色仅在你主动点击时连接服务商，API 密钥由 macOS 钥匙串保护。",
    privacyLink: "阅读隐私说明 ↗",
    popTitle: "新作：KuaiPop", popTag: "选中文字，一键翻译・润色・ToDo",
    popLead: "在任意应用中选中文字，旁边立刻弹出图标条。结果直接显示在原文下方，不打断你的工作。",
    popTranslate: "日语・英语 → 中文，中文 → 日语；一键切换 中 / 日 / EN",
    popPolish: "润色为商务日语，输入框中可直接替换原文",
    popTodo: "静默加入 ToDo，AI 自动提取标题与期限",
    popAI: "Mac 本机 AI（Apple Intelligence）/ Azure OpenAI / DeepSeek / Ollama",
    popDownload: "下载 KuaiPop", popReq: "macOS 13 及更高版本 · 免费 · MIT 开源",
    popKeys: "没有自动弹出时，用快捷键呼出",
    downloadTitle: "今天开始，让粘贴更快。",
    requirements: "macOS 14 Sonoma 及更高版本 · 免费 · MIT 开源"
  },
  ja: {
    navFeatures: "機能", navKeys: "ショートカット", navPrivacy: "プライバシー", langLabel: "言語",
    headline: "コピペを、<br>もっと<em>速く</em>",
    lead: "メニューバーから履歴を検索、ピン留め、すぐにペースト。ネイティブ Swift 製で、データは Mac の中だけに。",
    downloadButton: "最新版をダウンロード", sourceButton: "ソースを見る", copy: "コピー", copied: "コピー済",
    shortcutHint: "左 Command を2回押して表示",
    specRuntime: "ネイティブ Swift · Electron 不使用", specStorage: "ローカル優先 · 履歴は端末内に保存", specLicense: "MIT · 無料・OSS",
    featureTitle: "欲しいものを、指先に。",
    searchTitle: "一瞬で見つかる", searchText: "入力と同時に絞り込み。テキスト、リンク、ファイルパス、画像をすぐに呼び戻せます。",
    keyboardTitle: "キーボード中心", keyboardText: "矢印で選択、Enter でコピー、Option + Enter で直接ペースト。",
    aiTitle: "賢い AI 文章校正", aiText: "自然言語にだけ校正ボタンを表示。コマンド、URL、コード、構造化データには出しません。",
    pinTitle: "よく使う項目を固定", pinText: "最大10件をピン留めし、A〜J のショートカットで呼び出せます。",
    jsonTitle: "JSON をワンクリック整形", jsonText: "有効な JSON を認識し、整形・コピーして履歴にも保存します。",
    ocrTitle: "ローカル画像 OCR", ocrText: "Apple Vision で画像内の文字を端末内で抽出。画像はアップロードしません。",
    themeTitle: "6つの配色", themeText: "ホワイト、スカイ、ミント、サンド、ラベンダー、ダークをワンクリックで切り替え。",
    screenshotTitle: "スクリーンショットと注釈", screenshotText: "範囲・ウィンドウ・全画面を撮影し、図形、矢印、手描き、モザイク、文字、番号を追加して保存またはコピー。",
    keysTitle: "手はキーボードのままで。",
    keySummon: "履歴を表示（左 Command を2回）", keySelect: "項目を選択", keyCopy: "クリップボードにコピー",
    keyPaste: "前面のアプリへ直接ペースト", keyPinned: "ピン留めした項目を呼び出す",
    privacyTitle: "クリップボードは、<br>あなたの Mac に。",
    privacyText: "履歴は端末内に保存され、テレメトリやクリップボード内容は送信しません。AI 校正はクリックした時だけ接続し、API キーは macOS キーチェーンで保護されます。",
    privacyLink: "プライバシーについて ↗",
    popTitle: "新作：KuaiPop", popTag: "選ぶだけで、翻訳・推敲・ToDo",
    popLead: "どのアプリでもテキストを選択すると、すぐ近くにアイコンバーが表示されます。結果は原文のすぐ下に表示され、作業を中断しません。",
    popTranslate: "日本語・英語 → 中国語、中国語 → 日本語。「中 / 日 / EN」でワンクリック切り替え",
    popPolish: "ビジネス日本語に推敲。入力欄なら原文と置き換え",
    popTodo: "通知なしで ToDo に追加。AI がタイトルと期限を抽出",
    popAI: "Mac 本体の AI（Apple Intelligence）/ Azure OpenAI / DeepSeek / Ollama",
    popDownload: "KuaiPop をダウンロード", popReq: "macOS 13 以降 · 無料 · MIT オープンソース",
    popKeys: "自動で出ないときはショートカットで呼び出し",
    downloadTitle: "今日から、ペーストをもっと速く。",
    requirements: "macOS 14 Sonoma 以降 · 無料 · MIT オープンソース"
  },
  en: {
    navFeatures: "features", navKeys: "keymap", navPrivacy: "privacy", langLabel: "Language",
    headline: "Copy &amp; paste,<br>just <em>faster</em>",
    lead: "Search, pin, and paste your clipboard history from the menu bar. Written in native Swift. Your data never leaves your Mac.",
    downloadButton: "Download latest", sourceButton: "View source", copy: "copy", copied: "copied",
    shortcutHint: "double-tap left Command",
    specRuntime: "native Swift · not Electron", specStorage: "local-first · history stays on device", specLicense: "MIT · free & open source",
    featureTitle: "What you need, at your fingertips.",
    searchTitle: "Find it instantly", searchText: "Filter as you type. Text, links, file paths, and images come right back.",
    keyboardTitle: "Keyboard first", keyboardText: "Arrow keys to select, Enter to copy, Option + Enter to paste directly.",
    aiTitle: "Smarter AI polish", aiText: "Polish only appears for natural language — never for commands, URLs, code, or structured data.",
    pinTitle: "Pin what you reuse", pinText: "Pin up to 10 snippets and recall them with A–J shortcuts.",
    jsonTitle: "One-click JSON format", jsonText: "Valid JSON is detected, formatted, copied, and saved to history.",
    ocrTitle: "On-device OCR", ocrText: "Extract text from images locally with Apple Vision. Images are never uploaded.",
    themeTitle: "Six themes", themeText: "White, sky, mint, sand, lavender, and dark — cycle with one click.",
    screenshotTitle: "Capture and annotate", screenshotText: "Capture a region, window, or full screen; add shapes, arrows, freehand, mosaic, text, and numbered callouts, then save or copy.",
    keysTitle: "Hands stay on the keyboard.",
    keySummon: "Open clipboard history (double-tap left Command)", keySelect: "Select an item", keyCopy: "Copy to clipboard",
    keyPaste: "Paste directly into the front app", keyPinned: "Recall a pinned snippet",
    privacyTitle: "Your clipboard stays<br>on your Mac.",
    privacyText: "History is stored locally with no telemetry or clipboard uploads. AI connects only when you ask, and API keys are protected by macOS Keychain.",
    privacyLink: "Read the privacy details ↗",
    popTitle: "New: KuaiPop", popTag: "Select text — translate, polish, or save as a ToDo",
    popLead: "Select text in any app and a small icon bar appears right next to it. Results show up just below the original, without breaking your flow.",
    popTranslate: "Japanese/English → Chinese, Chinese → Japanese; switch 中 / 日 / EN in one click",
    popPolish: "Polish into business Japanese, and replace the original in text fields",
    popTodo: "Quietly add ToDos — AI extracts the title and due date",
    popAI: "On-device Mac AI (Apple Intelligence) / Azure OpenAI / DeepSeek / Ollama",
    popDownload: "Download KuaiPop", popReq: "macOS 13 or later · free · MIT open source",
    popKeys: "summon it with a shortcut anytime",
    downloadTitle: "Paste faster, starting today.",
    requirements: "macOS 14 Sonoma or later · free · MIT open source"
  }
};

const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* ignore */ } }
};

let currentLang = "zh";

function setLanguage(lang) {
  if (!common[lang]) lang = "zh";
  currentLang = lang;
  document.documentElement.lang = { zh: "zh-CN", ja: "ja", en: "en" }[lang];
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const value = common[lang][element.dataset.i18n];
    // Values come only from the static dictionary above.
    if (value) element.innerHTML = value;
  });
  store.set("kuaiclip-language", lang);
}

const language = document.querySelector("#language");
const browserLanguage = (navigator.language || "").toLowerCase();
const initial = store.get("kuaiclip-language")
  || (browserLanguage.startsWith("ja") ? "ja" : browserLanguage.startsWith("zh") ? "zh" : "en");
language.value = common[initial] ? initial : "zh";
setLanguage(language.value);
language.addEventListener("change", () => setLanguage(language.value));

// Screenshot tabs
const tabs = document.querySelectorAll("[data-shot]");
const shots = document.querySelectorAll("[data-shot-img]");
function showShot(name) {
  tabs.forEach((t) => {
    const on = t.dataset.shot === name;
    t.classList.toggle("is-active", on);
    t.setAttribute("aria-selected", String(on));
  });
  shots.forEach((s) => s.classList.toggle("is-active", s.dataset.shotImg === name));
}
tabs.forEach((t) => t.addEventListener("click", () => { showShot(t.dataset.shot); stopAuto(); }));
let autoTimer = null;
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
function stopAuto() { if (autoTimer) { clearInterval(autoTimer); autoTimer = null; } }
if (!reduceMotion) {
  let current = "dark";
  autoTimer = setInterval(() => { current = current === "dark" ? "light" : "dark"; showShot(current); }, 5000);
}

// Copy git clone command
const copyButton = document.querySelector("#copy-clone");
copyButton.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(copyButton.dataset.copy);
    copyButton.textContent = common[currentLang].copied;
    copyButton.classList.add("done");
    setTimeout(() => {
      copyButton.textContent = common[currentLang].copy;
      copyButton.classList.remove("done");
    }, 1600);
  } catch { /* clipboard unavailable */ }
});
