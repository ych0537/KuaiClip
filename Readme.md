# KuaiClip

<p align="center">
  <img src="Sources/KuaiClip/Resources/Assets.xcassets/AppIcon.appiconset/appicon-256.png" width="128" alt="KuaiClip icon" />
</p>

<p align="center">
  <strong>A lightweight, native macOS clipboard manager that lives in your menu bar.</strong><br>
  <sub>SwiftUI + AppKit • macOS 14+ • No Electron, no bloat</sub>
</p>

<p align="center">
  <a href="https://github.com/ych0537/KuaiClip/releases/latest"><img src="https://img.shields.io/github/v/release/ych0537/KuaiClip?label=latest&color=blue" alt="Latest Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/language-Swift%205.9%2B-orange" alt="Swift">
</p>

---

## English

### Overview

**KuaiClip** is a lightweight, native macOS clipboard manager built with SwiftUI and AppKit. It lives in the menu bar and lets you search, copy, paste, pin, and manage your clipboard history — all from the keyboard.

- **Target OS**: macOS 14 Sonoma or later
- **Architecture**: SwiftUI + AppKit (`NSStatusBar`, `NSPanel`, Carbon `HotKey`, `CGEvent`)
- **Storage**: `UserDefaults` (persists across restarts)
- **No Electron**: Native performance, minimal resource usage

### Features

- 🔍 **Instant search** — type to filter clipboard history
- 📌 **Pin items** — keep passwords, snippets, and frequent text always available
- 👁 **Hide sensitive content** — pin an item and toggle content visibility with the eye button; hidden content never leaks back into history after use
- 🎨 **6 color themes** — White, Sky, Mint, Sand, Lavender, and Dark, cycled from the popup
- 🖱 **Mouse hover selection** — move the mouse to instantly select any item
- ⌨️ **Fully keyboard-driven** — every action has a shortcut
- 📋 **Rich format detection** — text, RTF, HTML, URLs, file paths, images
- 🔄 **Recent-use ordering** — identical copies and recently used unpinned items move to the top
- ⚡ **Direct paste** — copy + paste into the frontmost app in one action
- 🚀 **Launch at login** — optional, configurable in Preferences
- 🌐 **Multi-language** — English / 日本語 / 简体中文 interface
- ↔️ **Remembered popup size** — resize once and the next popup restores that size
- ✨ **Content-aware AI workplace polish** — natural-language detection hides the action for commands, URLs, code, and structured data
- `{ }` **JSON format & copy** — pretty-print valid JSON, copy it, and keep the formatted result in history
- 🖼 **Large image thumbnails** — preview copied images in clear 76 × 76 thumbnails
- 🐼 **Selectable app icons** — switch the app and menu bar icon between six monochrome mascots
- 📊 **Private local usage counters** — count popup opens, polish-window opens, and polish runs on this Mac; copy the totals into an optional survey without automatic telemetry

### Quick Manual

KuaiClip remembers content copied on the Mac. Instead of returning to the original document or website, open the popup and reuse an earlier item.

#### 1. Basic workflow: open, select, paste

1. Copy text, links, or other content normally. Each copy appears in the history.
2. Open the popup with **double-tap Left ⌘** or the fallback shortcut **⇧⌘C**.
3. Select an item with `↑` / `↓` or the mouse.
4. Press `Enter` to copy it, then paste with `⌘V`. To paste directly into the previous app, press `⌥Enter` instead.

![Basic workflow: open the clipboard history and select an item](docs/images/manual-basic.png)

#### 2. Pinned items: keep frequently reused content

1. Select a frequently used item, such as a standard greeting, internal URL, or template name.
2. Press `⌥P`, or right-click and choose **Pin**.
3. Pinned items remain at the top and use the separate labels `a`–`j`. Use `⌘A`–`⌘J` to copy one directly while the popup is open.
4. Up to 10 items can be pinned. Unpin an old item before adding an 11th.

![Pinned items stay above regular clipboard history](docs/images/manual-pinned.png)

#### 3. Hidden items: conceal sensitive text in the popup

1. Pin the item first.
2. Click the crossed-eye button on the right, or right-click and choose **Hide Content**.
3. The popup replaces the content with dots. Click the eye button to reveal it again.
4. Direct paste (`⌥Enter`) removes a hidden item after use so it does not remain in history.

![A hidden pinned item is masked with dots](docs/images/manual-hidden.png)

> Hidden mode prevents shoulder-surfing in the popup; it is not encryption. Clipboard data is stored locally in macOS `UserDefaults`, so use the clear commands when sensitive history is no longer needed.

#### 4. AI polish: improve workplace messages

1. Open Preferences with `⌘,`, select **AI Polish**, and enter an API key for OpenAI, Gemini, or DeepSeek. Keys are stored in macOS Keychain.
2. Open the clipboard popup and click the wand button beside a text item. Image items and hidden items do not expose this action.
3. Choose any model whose provider has a configured key, then click the send button.
4. KuaiClip detects Chinese, English, or Japanese automatically, preserves the original language and meaning, and returns only the professionally polished text.
5. Copy the result with the copy button. AI polish accepts up to **20,000 characters** per request; regular clipboard history is not subject to this limit.

> AI polish sends the selected text to the provider you choose and may incur provider API charges. KuaiClip does not send clipboard content automatically.

### Installation

#### Download (Recommended)

Download `KuaiClip.app.zip` from [GitHub Releases](https://github.com/ych0537/KuaiClip/releases/latest), extract it, move `KuaiClip.app` to `/Applications/`, and launch it.

Official release assets are signed with **Developer ID**, notarized by Apple, and include a stapled notarization ticket. Gatekeeper can therefore verify the developer and integrity without requiring users to remove quarantine attributes. KuaiClip appears only in the menu bar and does not show a Dock icon.

#### Build from Source

```bash
git clone https://github.com/ych0537/KuaiClip.git
cd KuaiClip
swift build -c release
BUILD_DIR=.build/release bash scripts/package.sh
open KuaiClip.app
```

### Usage

#### Popup Window

| Action | Shortcut |
|--------|----------|
| Show / hide popup | **Double-tap Left ⌘** (default) or **⇧⌘C** (fallback) |
| Dismiss popup | `Esc` or click outside |

> **Note**: Double-tap requires **Accessibility** permission. If not granted, the app automatically falls back to ⇧⌘C.

#### Inside the Popup

| Action | Shortcut / Gesture |
|--------|--------------------|
| Search / filter | Type in the search field |
| Navigate list | `↑` / `↓` arrow keys |
| Select item | Hover mouse over item |
| Copy selected item | `↩` Enter / Click / `⌘1-9` (unpinned) / `⌘A-J` (pinned) |
| Copy & Paste directly | `⌥↩` / ⌥Click / `⌥1-9` (unpinned) / `⌥A-J` (pinned) |
| Paste without formatting | `⌥⇧↩` / ⌥⇧Click / `⌥⇧1-9` (unpinned) / `⌥⇧A-J` (pinned) |
| Delete selected item | `⌥⌫` |
| Pin / Unpin item | `⌥P` |
| Toggle content visibility (pinned) | Click 👁 button |
| Clear all unpinned items | `⌥⌘⌫` |
| Clear all items (incl. pinned) | `⌥⇧⌘⌫` |
| Preview full text | Hover over any item (~1 second) |
| Open Preferences | `⌘,` |

#### Menu Bar Icon

| Action | How |
|--------|-----|
| Show popup | Left-click the icon |
| Disable / Enable monitoring | `⌥` + Left-click |
| Ignore next copy only | `⌥⇧` + Left-click |
| Right-click menu | Clear unpinned / Clear all / Preferences / Quit |
| Monitoring disabled indicator | Icon appears dimmed (40% opacity) |

#### Preferences (`⌘,`)

| Section | Options |
|---------|---------|
| **General** | Max history items (10–100), Polling interval (0.25–2.0 s), Launch at login, Strip formatting by default, Language (English / 日本語 / 简体中文) |
| **Shortcuts** | Activation mode (Double-tap ⌘ / Custom hotkey with Record button), Shortcut reference |
| **AI Polish** | OpenAI, Gemini, and DeepSeek API keys stored in macOS Keychain |
| **About** | App icon, version, local usage totals, copy-for-survey, and reset controls |

![Local usage counters in the About tab](docs/images/preferences-about-usage.png)

Usage counters are stored only in local `UserDefaults`. KuaiClip never uploads them automatically. Copying the report is an explicit user action intended for optional surveys.

### Themes

KuaiClip supports 6 appearance modes, cycled by clicking the palette button in the popup's search bar:

| Mode | Icon | Description |
|------|------|-------------|
| **White / Sky / Mint / Sand / Lavender** | 🎨 | Low-saturation light palettes with dark foreground text |
| **Dark** | 🎨 | `#181818` background with a light foreground |

Existing `System` and `Gray` preferences are migrated automatically to Light and Dark respectively.

### Clipboard Monitoring

- Polls `NSPasteboard.general` at configurable intervals (0.25–2.0 s)
- Detects text, RTF, HTML, URLs, file paths, and images
- Recent-use ordering — identical content and used unpinned items move to the top
- Non-text items show type badges: 🖼 image, 📁 file, 📦 other

### History Management

- **Pinned items**: Up to 10, labeled `a–j`. Attempting to pin an 11th item shows an alert. Pinned items always appear above regular history.
- **Max history**: Configurable 10–100 unpinned items (default 50), numbered separately from `1`. Oldest items are trimmed automatically.
- **Hidden content**: Pinned items can have their content hidden (👁). When used, hidden content is never re-added to clipboard history — ideal for passwords and secrets.
- Persists across app restarts via `UserDefaults`.

### Security & Permissions

| Feature | Permission Required | Why |
|---------|-------------------|-----|
| Clipboard read/write | None | Standard `NSPasteboard` API |
| Double-tap Left ⌘ | **Accessibility** | `NSEvent.addGlobalMonitorForEvents` |
| Paste simulation (`⌥↩`) | **Accessibility** | `CGEvent` post to `kCGHIDEventTap` |
| Custom Carbon hotkey | None | Carbon `RegisterEventHotKey` API |

**How to grant Accessibility permission:**
1. Open **System Settings → Privacy & Security → Accessibility**
2. Click the **+** button and add `KuaiClip.app`
3. Toggle the switch ON

> If Accessibility is not granted, KuaiClip automatically falls back to `⇧⌘C` for the popup shortcut. Paste simulation (`⌥↩`) requires Accessibility — without it, use `↩` (copy only) then `⌘V` manually.

### Privacy

- **Local history**: Clipboard history is stored in `UserDefaults` on your device.
- **Opt-in AI requests only**: KuaiClip connects to OpenAI, Gemini, or DeepSeek only after you click the polish button. Only the selected text is sent to the selected provider.
- **Keychain protection**: AI API keys are stored in macOS Keychain, not `UserDefaults`.
- **No analytics or telemetry uploads**: Local counters for popup opens and AI-polish use remain on this Mac and are shared only when the user explicitly copies them into a survey. Clipboard data is never included.
- **No separate clipboard-content files**: Clipboard content is not written to standalone files; persistent history lives in the app preferences plist.
- **Hidden content stays hidden**: Pinned items marked as hidden are removed from history immediately after use and never re-added by the clipboard monitor.

### Security, Rights & Distribution Review

This is a repository-level review, not legal advice. Before broad external distribution, confirm the license and signing requirements with the project owner.

| Area | Result | Notes |
|------|--------|-------|
| Local data handling | Pass | Clipboard history is stored locally via `UserDefaults`; no database or remote storage is used. |
| Network access | User initiated | Network access occurs only for AI polish requests explicitly initiated by the user; there is no analytics or telemetry path. |
| Permissions | Pass with user consent | Accessibility is only needed for double-tap detection and paste simulation. The fallback shortcut works without it. |
| Sensitive pinned content | Pass | Hidden pinned content is removed from history after use and is not re-added by the clipboard monitor. |
| Persistence risk | Review | Text history, including pinned entries, remains in `~/Library/Preferences/com.kuaiclip.clipboard.plist` until cleared. Users should clear sensitive data when needed. |
| Third-party dependencies | Pass | `Package.swift` declares no external package dependencies. |
| License rights | Pass | MIT license text is included in the repository-level `LICENSE` file. |
| Distribution trust | Pass | Official release assets are Developer ID signed, Apple notarized, stapled, and verified with `codesign`, `stapler`, and Gatekeeper (`spctl`). |

### Troubleshooting

<details>
<summary><strong>“KuaiClip.app is damaged and can't be opened”</strong></summary>

Download the asset again from the official GitHub Release and verify that it was fully extracted before moving it to `/Applications`. Official release assets are notarized; do not disable Gatekeeper or remove quarantine as a routine installation step. If the warning persists, report the release version and downloaded ZIP checksum in a GitHub issue.
</details>

<details>
<summary><strong>Double-tap ⌘ doesn't work</strong></summary>

Double-tap requires Accessibility permission:
1. **System Settings → Privacy & Security → Accessibility**
2. Add `KuaiClip.app` and enable it
3. Restart KuaiClip

Alternatively, switch to a custom hotkey in Preferences (`⌘,` → Shortcuts).
</details>

<details>
<summary><strong>⌥↩ (paste directly) doesn't work</strong></summary>

Paste simulation also requires **Accessibility** permission (see above). Without it, use `↩` to copy, then `⌘V` manually.
</details>

<details>
<summary><strong>How do I uninstall?</strong></summary>

1. Quit KuaiClip from the menu bar icon right-click menu
2. Delete `KuaiClip.app` from `/Applications`
3. (Optional) Clear saved data:
   ```bash
   defaults delete com.kuaiclip.clipboard
   ```
</details>

<details>
<summary><strong>Theme toggle button doesn't respond</strong></summary>

Make sure you're running the latest version (v0.5+). If the issue persists, try:
1. Quit and restart KuaiClip
2. Delete preferences: `defaults delete com.kuaiclip.clipboard`
</details>

### Building from Source

```bash
# Clone
git clone https://github.com/ych0537/KuaiClip.git
cd KuaiClip

# Build (debug)
swift build

# Run tests
bash scripts/test.sh

# Build (release) + package as .app
swift build -c release
BUILD_DIR=.build/release bash scripts/package.sh

# Run
open KuaiClip.app
```

**Requirements**: Xcode 15+ (Swift 5.9), macOS 14+

### Development & Review Tools

| Purpose | Tools |
|---------|-------|
| Coding toolset | Ollama + Qwen3.6 + Gemma4 + Codex |
| Review, testing, audit | Codex + GPT5.5 |

### License

[MIT](LICENSE)

---


### Data Storage & Privacy

**Where is data stored?**

All clipboard history is stored in macOS UserDefaults:

```
~/Library/Preferences/com.kuaiclip.clipboard.plist
```

**Important notes:**

| Item | Detail |
|------|--------|
| **Text** | Stored as-is (UTF-8) |
| **Images** | Stored as full-resolution PNG data so copied images retain their original dimensions |
| **Max items** | Configurable (10–100, default 50). Oldest unpinned items are auto-removed |
| **Pinned items** | Up to 10 and never auto-deleted |

**Privacy**: History stays on your device. Text is sent over the network only when you explicitly run AI polish with a configured provider.

**To clear all data**:
- Right-click menu bar icon → Clear All Items, or
- Run: `defaults delete com.kuaiclip.clipboard`


---

## 日本語

### 概要

**KuaiClip** は、SwiftUI と AppKit で構築された軽量でネイティブな macOS 用クリップボードマネージャーです。メニューバーに常駐し、クリップボード履歴の検索・コピー・貼り付け・ピン留め・管理をすべてキーボードから行えます。

- **対応 OS**: macOS 14 Sonoma 以降
- **アーキテクチャ**: SwiftUI + AppKit（`NSStatusBar`、`NSPanel`、Carbon `HotKey`、`CGEvent`）
- **保存方式**: `UserDefaults`（再起動後も保持）
- **Electron 不使用**: ネイティブパフォーマンス、最小限のリソース消費

### 機能

- 🔍 **インスタント検索** — 入力するだけで履歴を絞り込み
- 📌 **ピン留め** — パスワードや定型文などを常に利用可能に
- 👁 **センシティブな内容の非表示** — ピン留めした項目の目アイコンで表示/非表示を切替。非表示にした内容は使用後も履歴に再追加されません
- 🎨 **Codex Desktop準拠の2テーマ** — ライト / ダーク、ポップアップから切替可能
- 🖱 **マウスホバー選択** — マウスを動かすだけで項目を即座に選択
- ⌨️ **完全キーボード操作** — すべての操作にショートカットあり
- 📋 **リッチフォーマット検出** — テキスト、RTF、HTML、URL、ファイルパス、画像
- 🔄 **最近使用した順に整列** — 同一内容と使用済みの未固定項目は先頭に移動
- ⚡ **ダイレクトペースト** — コピー＋貼り付けをワンアクションで
- 🚀 **ログイン時起動** — 設定からオン/オフ可能
- 🌐 **多言語対応** — English / 日本語 / 简体中文
- ↔️ **ポップアップサイズ記憶** — 調整した幅と高さを次回表示時に復元
- ✨ **AIビジネス文章校正** — OpenAI、Gemini、DeepSeekで中国語・英語・日本語のメール文章を自然に校正
- 🖼 **統一サイズの画像サムネイル** — コピーした画像を履歴内で同じサイズに揃えて表示
- 🐼 **選べるアプリアイコン** — アプリとメニューバーのアイコンを6種類のモノクロマスコットから選択
- 📊 **ローカル利用回数** — Popup表示、校正画面表示、校正実行をこのMacだけで集計。自動送信せず、任意アンケート用に明示的にコピー可能

### かんたん操作マニュアル

KuaiClipは、Macでコピーした内容を履歴として覚えるアプリです。元の資料やWebページへ戻らなくても、Popupから以前のコピー内容を選んで再利用できます。

#### 1. 基本操作：開く → 選ぶ → 貼り付ける

1. テキストやURLなどを普段どおりコピーします。コピーするたびに履歴へ追加されます。
2. **左⌘をダブルタップ**、または代替ショートカット **⇧⌘C** でPopupを開きます。
3. `↑` / `↓` キー、またはマウスで使いたい項目を選びます。
4. `Enter`でコピーし、貼り付け先で`⌘V`を押します。直前のアプリへすぐ貼り付ける場合は`⌥Enter`を使います。

![基本操作：クリップボード履歴を開いて項目を選択](docs/images/manual-basic.png)

#### 2. 固定（Pinned）：よく使う内容を残す

1. 定型挨拶、社内URL、テンプレート名など、繰り返し使う項目を選びます。
2. `⌥P`を押すか、右クリックメニューから**固定**を選びます。
3. 固定項目は常に上部へ表示され、通常履歴とは別に`a`～`j`で採番されます。Popup表示中は`⌘A`～`⌘J`で直接コピーできます。
4. 固定できるのは最大10件です。11件目を追加する場合は、不要な固定項目を先に解除します。

![固定項目は通常の履歴より上に表示](docs/images/manual-pinned.png)

#### 3. 非表示：機密文字列を画面上で隠す

1. 対象項目を先に固定します。
2. 右側の斜線付き目アイコンをクリックするか、右クリックメニューから**内容を隠す**を選びます。
3. 内容が点（••••）に置き換わります。再表示するときは目アイコンをクリックします。
4. 非表示項目を`⌥Enter`で直接貼り付けると、使用後に履歴から削除されます。

![非表示にした固定項目は点でマスキングされる](docs/images/manual-hidden.png)

> 非表示は、Popupを見られたときの覗き見を防ぐための表示上のマスキングであり、暗号化ではありません。履歴はmacOSの`UserDefaults`へローカル保存されるため、機密情報が不要になったら消去機能を利用してください。

#### 4. AI文章校正：ビジネスメールを自然に整える

1. `⌘,`で設定を開き、**AI文章校正**からOpenAI、Gemini、DeepSeekのいずれかのAPIキーを入力します。キーはmacOSキーチェーンに保存されます。
2. クリップボードのPopupを開き、テキスト項目の右側にある魔法の杖ボタンをクリックします。画像と非表示項目には表示されません。
3. APIキーを設定済みのモデルを選び、送信ボタンをクリックします。
4. 中国語・英語・日本語を自動判定し、元の言語と意味を維持したまま、自然で丁寧なビジネス文章へ校正します。
5. 結果はコピーボタンからコピーできます。AI校正は1回につき最大**20,000文字**です。通常のクリップボード履歴にはこの制限はありません。

> AI校正では、選択した文章が指定したAIプロバイダーへ送信され、プロバイダー側のAPI料金が発生する場合があります。KuaiClipが自動的にクリップボード内容を送信することはありません。

### インストール

#### ダウンロード（推奨）

[GitHub Releases](https://github.com/ych0537/KuaiClip/releases/latest) から `KuaiClip.app.zip` をダウンロードして展開し、`KuaiClip.app` を `/Applications/` へ移動して起動してください。

公式Releaseは **Developer ID署名**、Apple notarization、チケットのstapleを完了しています。通常はquarantine属性の手動削除やGatekeeperの無効化は不要です。KuaiClipはメニューバーにのみ表示され、Dockアイコンは表示しません。

#### ソースからビルド

```bash
git clone https://github.com/ych0537/KuaiClip.git
cd KuaiClip
swift build -c release
BUILD_DIR=.build/release bash scripts/package.sh
open KuaiClip.app
```

### 使い方

#### ポップアップウィンドウ

| 操作 | ショートカット |
|------|----------------|
| ポップアップ表示 / 非表示 | **左⌘ダブルタップ**（初期設定）または **⇧⌘C**（フォールバック） |
| ポップアップを閉じる | `Esc` またはポップアップ外をクリック |

> **注意**: ダブルタップには **アクセシビリティ** 権限が必要です。権限がない場合、自動的に ⇧⌘C にフォールバックします。

#### ポップアップ内の操作

| 操作 | ショートカット / 操作 |
|------|----------------------|
| 検索 / フィルタ | 検索フィールドに入力 |
| リスト移動 | `↑` / `↓` 矢印キー |
| 項目を選択 | マウスホバー |
| 選択項目をコピー | `↩` Enter / クリック / `⌘1-9`（未固定）/ `⌘A-J`（固定） |
| コピーして直接貼り付け | `⌥↩` / ⌥クリック / `⌥1-9`（未固定）/ `⌥A-J`（固定） |
| 書式なしで貼り付け | `⌥⇧↩` / ⌥⇧クリック / `⌥⇧1-9`（未固定）/ `⌥⇧A-J`（固定） |
| 選択項目を削除 | `⌥⌫` |
| ピン留め / 解除 | `⌥P` |
| 表示/非表示切替（ピン留め項目） | 👁 ボタンをクリック |
| ピン留め以外を全削除 | `⌥⌘⌫` |
| すべて削除（ピン含む） | `⌥⇧⌘⌫` |
| 全文プレビュー | 項目にホバー（約1秒） |
| 設定を開く | `⌘,` |

#### メニューバーアイコン

| 操作 | 方法 |
|------|------|
| ポップアップ表示 | アイコンを左クリック |
| 監視の無効化 / 再有効化 | `⌥` + 左クリック |
| 次のコピーのみ無視 | `⌥⇧` + 左クリック |
| 右クリックメニュー | ピン留め以外を消去 / すべて消去 / 設定 / 終了 |
| 監視無効時の表示 | アイコンが薄くなる（不透明度 40%） |

#### 設定（`⌘,`）

| セクション | 項目 |
|------------|------|
| **一般** | 最大履歴数（10～100）、ポーリング間隔（0.25～2.0秒）、ログイン時起動、デフォルトで書式なし貼り付け、言語（English / 日本語 / 简体中文） |
| **ショートカット** | 起動モード（ダブルタップ⌘ / カスタムホットキー＋録音ボタン）、ショートカット一覧 |
| **AI文章校正** | macOSキーチェーンに保存するOpenAI、Gemini、DeepSeekのAPIキー |
| **情報** | アプリアイコン、バージョン、ローカル利用回数、アンケート用コピー、リセット |

![情報タブに表示されるローカル利用回数](docs/images/preferences-about-usage.png)

利用回数はこのMacの`UserDefaults`だけに保存され、自動送信されません。アンケートへ共有する場合も、利用者が明示的に「利用データをコピー」を押します。

### テーマ

ポップアップの検索バーにあるテーマボタン（☀/🌙）をクリックすると、2つの外観モードを切り替えられます。どちらもCodex Desktopと同じメイン背景色・前景色・ネイティブフォント構成です：

| モード | アイコン | 説明 |
|------|------|------|
| **ライト** | ☀ | 背景 `#FFFFFF`、前景 `#1A1C1F`、system UIフォント、SF Monoコードフォント |
| **ダーク** | 🌙 | 背景 `#181818`、前景 `#FFFFFF`、system UIフォント、SF Monoコードフォント |

既存の「システム」はライトへ、「グレー」はダークへ自動移行します。

### クリップボード監視

- `NSPasteboard.general` を設定可能な間隔（0.25～2.0秒）でポーリング
- テキスト、RTF、HTML、URL、ファイルパス、画像を検出
- 最近使用した順に整列 — 同一内容と使用済みの未固定項目は先頭に移動
- 非テキスト項目はタイプバッジで表示：🖼 画像、📁 ファイル、📦 その他

### 履歴管理

- **ピン留め**: 最大10件、`a～j` で採番します。11件目を固定しようとするとアラートを表示します。
- **最大履歴数**: 未固定項目は10～100件（デフォルト50）で、固定項目とは別に `1` から採番します。超過分は古い順に自動削除します。
- **非表示コンテンツ**: ピン留め項目の内容を非表示にできます（👁）。非表示項目を使用すると、その内容はクリップボード履歴に再追加されません — パスワードや機密情報に最適です。
- UserDefaults により再起動後も保持。

### セキュリティと権限

| 機能 | 必要な権限 | 理由 |
|------|-----------|------|
| クリップボードの読み書き | 不要 | 標準 `NSPasteboard` API |
| 左⌘ダブルタップ | **アクセシビリティ** | `NSEvent.addGlobalMonitorForEvents` |
| 貼り付けシミュレーション（`⌥↩`） | **アクセシビリティ** | `CGEvent` を `kCGHIDEventTap` に送信 |
| カスタム Carbon ホットキー | 不要 | Carbon `RegisterEventHotKey` API |

**アクセシビリティ権限の付与手順:**
1. **システム設定 → プライバシーとセキュリティ → アクセシビリティ** を開く
2. **＋** ボタンをクリックして `KuaiClip.app` を追加
3. スイッチをオンにする

> アクセシビリティ権限がない場合、KuaiClip は自動的に `⇧⌘C` をポップアップショートカットとして使用します。貼り付けシミュレーション（`⌥↩`）にはアクセシビリティが必要です。権限がない場合は `↩`（コピーのみ）＋手動 `⌘V` を使用してください。

### プライバシー

- **履歴はローカル保存**: クリップボード履歴はデバイス上の `UserDefaults` に保存されます。
- **明示操作時のみAI通信**: AI校正ボタンを押した場合のみ、選択した文章をOpenAI、Gemini、DeepSeekの指定プロバイダーへ送信します。
- **キーチェーン保護**: AIのAPIキーは`UserDefaults`ではなくmacOSキーチェーンに保存します。
- **解析・テレメトリーの自動送信なし**: Popup表示回数とAI校正利用回数はこのMacだけに保存され、利用者が任意アンケートへ明示的にコピーした場合のみ共有されます。クリップボード内容は統計に含めません。
- **クリップボード内容の個別ファイル保存なし**: クリップボード内容は個別ファイルとして保存されず、永続化される履歴はアプリの設定 plist に保存されます。
- **非表示コンテンツの保護**: 非表示設定されたピン留め項目は使用後すぐに履歴から削除され、クリップボードモニターによって再追加されることもありません。

### セキュリティ・権利・配布審査

これはリポジトリレベルの審査結果であり、法的助言ではありません。広く外部配布する前に、ライセンスと署名要件をプロジェクトオーナー側で最終確認してください。

| 項目 | 結果 | メモ |
|------|------|------|
| ローカルデータ処理 | 合格 | クリップボード履歴は `UserDefaults` にローカル保存され、データベースやリモート保存は使っていません。 |
| ネットワークアクセス | ユーザー操作時のみ | 明示的に実行したAI校正だけが通信します。解析・テレメトリー経路はありません。 |
| 権限 | ユーザー許可前提で合格 | アクセシビリティ権限はダブルタップ検出と貼り付けシミュレーションにのみ必要です。フォールバックショートカットは権限なしで動作します。 |
| センシティブなピン留め内容 | 合格 | 非表示のピン留め内容は使用後に履歴から削除され、クリップボード監視でも再追加されません。 |
| 永続化リスク | 要確認 | テキスト履歴やピン留め項目は、削除するまで `~/Library/Preferences/com.kuaiclip.clipboard.plist` に残ります。必要に応じてユーザーが消去してください。 |
| サードパーティ依存 | 合格 | `Package.swift` に外部パッケージ依存はありません。 |
| ライセンス権利 | 合格 | MIT ライセンス本文をリポジトリ直下の `LICENSE` ファイルに含めています。 |
| 配布の信頼性 | 合格 | 公式ReleaseはDeveloper ID署名、Apple notarization、stapleを完了し、`codesign`、`stapler`、Gatekeeper（`spctl`）で検証します。 |

### トラブルシューティング

<details>
<summary><strong>「KuaiClip.appは壊れているため開けません」と表示される</strong></summary>

公式GitHub Releaseからもう一度ダウンロードし、ZIPを完全に展開してから`/Applications`へ移動してください。公式Releaseは公証済みのため、通常のインストールでGatekeeperを無効化したりquarantine属性を削除したりしないでください。警告が続く場合は、ReleaseバージョンとZIPのチェックサムをGitHub Issueへ報告してください。
</details>

<details>
<summary><strong>ダブルタップ⌘が効かない</strong></summary>

ダブルタップにはアクセシビリティ権限が必要です：
1. **システム設定 → プライバシーとセキュリティ → アクセシビリティ**
2. `KuaiClip.app` を追加して有効にする
3. KuaiClip を再起動

または、設定（`⌘,` → ショートカット）でカスタムホットキーに切り替えてください。
</details>

<details>
<summary><strong>⌥↩（直接貼り付け）が効かない</strong></summary>

貼り付けシミュレーションにも **アクセシビリティ** 権限が必要です（上記参照）。権限がない場合は `↩` でコピー後、手動で `⌘V` してください。
</details>

<details>
<summary><strong>アンインストール方法は？</strong></summary>

1. メニューバーアイコンの右クリックメニューから KuaiClip を終了
2. `/Applications` から `KuaiClip.app` を削除
3. （任意）保存データの消去：
   ```bash
   defaults delete com.kuaiclip.clipboard
   ```
</details>

<details>
<summary><strong>テーマ切替ボタンが反応しない</strong></summary>

最新バージョン（v0.5以降）を使用していることを確認してください。それでも問題が発生する場合：
1. KuaiClip を終了して再起動
2. 設定をリセット：`defaults delete com.kuaiclip.clipboard`
</details>

### ソースからビルド

```bash
# クローン
git clone https://github.com/ych0537/KuaiClip.git
cd KuaiClip

# ビルド（デバッグ）
swift build

# テスト
bash scripts/test.sh

# ビルド（リリース）+ .app にパッケージ
swift build -c release
BUILD_DIR=.build/release bash scripts/package.sh

# 実行
open KuaiClip.app
```

**要件**: Xcode 15+（Swift 5.9）、macOS 14+


### データ保存とプライバシー

**データの保存場所**

すべてのクリップボード履歴は macOS の UserDefaults に保存されます：

```
~/Library/Preferences/com.kuaiclip.clipboard.plist
```

**重要な注意点：**

| 項目 | 詳細 |
|------|------|
| **テキスト** | UTF-8 でそのまま保存 |
| **画像** | 元のピクセル寸法を維持したフル解像度PNGとして保存 |
| **最大件数** | 設定可能（10～100、初期値 50）。古いピン留めなし項目は自動削除 |
| **ピン留め** | 最大10件、自動削除されません |

**プライバシー**: 履歴はデバイス上に保存されます。AI校正を明示的に実行した場合のみ、選択した文章が指定プロバイダーへ送信されます。

**データを消去する方法**:
- メニューバーアイコンを右クリック → Clear All Items
- または `defaults delete com.kuaiclip.clipboard` を実行


### 開発・レビュー支援ツール

| 用途 | ツール |
|------|--------|
| Codingツール集 | Ollama + Qwen3.6 + Gemma4 + Codex |
| レビュー・テスト・審査 | Codex + GPT5.5 |

### ライセンス

[MIT](LICENSE)

---

## 简体中文

### 简介

**KuaiClip** 是一款基于 SwiftUI 与 AppKit 开发的原生 macOS 菜单栏剪贴板管理器，支持搜索、复制、直接粘贴、固定、隐藏、图片预览和 AI 职场文本润色。

- **系统要求**：macOS 14 Sonoma 或更高版本
- **界面语言**：English / 日本語 / 简体中文
- **本地存储**：剪贴板历史和使用次数保存在本机 `UserDefaults`
- **原生实现**：不使用 Electron，无第三方 Swift Package 依赖

### 主要功能

- 即时搜索剪贴板历史，支持键盘与鼠标操作
- 固定最多 10 个常用项目，并使用 `a`–`j` 独立编号
- 隐藏固定项目内容，减少屏幕窥视风险
- 支持文本、RTF、HTML、URL、文件路径和图片
- 支持复制、直接粘贴以及无格式粘贴
- 支持浅色与深色主题、六种 App 与菜单栏图标
- 使用 OpenAI、Gemini 或 DeepSeek 润色中文、英文和日文职场文本
- 在“关于”页面显示本机累计使用次数，便于用户主动填写问卷

![KuaiClip 0.5 主窗口](docs/images/manual-basic.png)

### 安装

1. 从 [GitHub Releases](https://github.com/ych0537/KuaiClip/releases/latest) 下载 `KuaiClip.app.zip`。
2. 解压后将 `KuaiClip.app` 移动到 `/Applications/`。
3. 启动 KuaiClip；它只显示在菜单栏，不显示 Dock 图标。

官方 Release 已完成 Developer ID 签名、Apple 公证和票据 staple，并经过 Gatekeeper 验证。正常安装不需要关闭 Gatekeeper，也不需要手动删除 quarantine 属性。

### 基本操作

| 操作 | 快捷键或方式 |
|------|--------------|
| 打开或关闭主窗口 | 双击左侧 `⌘`，或备用快捷键 `⇧⌘C` |
| 搜索 | 直接在搜索框输入 |
| 上下选择 | `↑` / `↓` |
| 复制 | `Enter`、点击、`⌘1–9` 或 `⌘A–J` |
| 复制并直接粘贴 | `⌥Enter` |
| 无格式粘贴 | `⌥⇧Enter` |
| 固定或取消固定 | `⌥P` |
| 删除所选项目 | `⌥Delete` |
| 打开设置 | `⌘,` |

左侧 `⌘` 双击检测与直接粘贴需要“辅助功能”权限；没有权限时仍可使用 Carbon 备用快捷键打开窗口，并通过 `Enter` 复制后手动按 `⌘V`。

### AI 润色

1. 打开“设置 → AI 润色”，保存 OpenAI、Gemini 或 DeepSeek API Key。Key 存储在 macOS 钥匙串。
2. 在剪贴板项目右侧点击魔法棒按钮。
3. 选择已配置的模型并点击“润色”。每次最多处理 20,000 个字符。

只有用户主动点击“润色”时，所选文本才会发送到相应 AI 服务商；KuaiClip 不会在后台自动上传剪贴板内容。

### 本机使用统计

0.5 版本开始记录以下本机计数：

- 主窗口实际打开次数
- 润色窗口打开次数
- 实际发起润色请求次数
- 统计开始日期

统计结果位于“设置 → 关于”，支持复制为问卷文本或单独重置。

![“关于”页面中的本机使用统计](docs/images/preferences-about-usage.png)

这些计数不会自动上传，不包含剪贴板内容、润色文本、API Key、模型名称或每次使用的具体时间。只有用户主动复制并提交问卷时才会分享。

### 数据与隐私

- 剪贴板历史保存在 `~/Library/Preferences/com.kuaiclip.clipboard.plist`。
- AI API Key 保存在 macOS 钥匙串，不保存在 `UserDefaults`。
- 隐藏功能是界面遮挡，不是加密；不再需要敏感内容时请及时清除历史。
- “清空剪贴板历史”不会清除使用统计；使用统计只能从“关于”页面单独重置。
- KuaiClip 不包含自动分析或遥测上传通道。

### 从源码构建

```bash
git clone https://github.com/ych0537/KuaiClip.git
cd KuaiClip
bash scripts/test.sh
swift build -c release
BUILD_DIR=.build/release VERSION=0.5 bash scripts/package.sh
open KuaiClip.app
```

### 许可证

[MIT](LICENSE)
