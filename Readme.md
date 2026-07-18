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

<p align="center">
  <strong>English</strong> · <a href="Readme.ja.md">日本語</a> · <a href="Readme.zh-CN.md">简体中文</a>
</p>

---

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
- 📸 **Screenshot capture and annotation** — capture a region, window, or full screen; add shapes, arrows, freehand marks, mosaic, text, and numbered callouts

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

#### 5. Screenshots: capture, annotate, save, or copy

1. Press the screenshot shortcut, **⇧⌘S** by default. KuaiClip checks that it does not duplicate the clipboard popup shortcut.
2. Choose **Region**, **Window**, or **Full Screen**.
3. Annotate the capture with rectangles, ellipses, lines, arrows, pen strokes, mosaic, text, or numbered callouts. Undo or clear annotations when needed.
4. Click **Download** to save a PNG directly to `~/Downloads` without changing the clipboard or history.
5. Click **Copy** to place the PNG on the system clipboard and add it to KuaiClip history.

The screenshot shortcut can be changed in **Preferences → Shortcuts**. macOS requests **Screen Recording** permission the first time screen capture is used.

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
| Right-click menu | Preferences / Quit |
| Monitoring disabled indicator | Icon appears dimmed (40% opacity) |

#### Preferences (`⌘,`)

| Section | Options |
|---------|---------|
| **General** | Max history items (10–100), Polling interval (0.25–2.0 s), Launch at login, Strip formatting by default, Language (English / 日本語 / 简体中文) |
| **Shortcuts** | Clipboard popup activation, configurable screenshot shortcut, duplicate-shortcut validation, popup shortcut reference |
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
