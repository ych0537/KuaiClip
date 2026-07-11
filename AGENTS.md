# AGENTS.md

このドキュメントは、AI エージェントまたはレビュアーが `KuaiClip` を安全に理解・変更・レビューするための作業ガイドです。  
将来的に第三者レビューへ提出する前提で、プロジェクト構造、重要な設計、検証手順、注意点を日本語で整理しています。

## プロジェクト概要

`KuaiClip` は SwiftUI と AppKit で実装された macOS 向けメニューバー常駐型クリップボードマネージャーです。

- Dock アイコンを表示しないメニューバーアプリです。
- クリップボード履歴を監視し、検索・コピー・直接ペースト・固定・非表示化できます。
- UI は SwiftUI、メニューバー・浮動ウィンドウ・グローバルショートカットなどの macOS 連携は AppKit / Carbon / CoreGraphics を使います。
- 履歴データは `UserDefaults` に保存します。
- 英語・日本語・簡体字中国語の UI 切り替えをサポートします。

## ディレクトリ構成

```text
.
├── Package.swift
├── Readme.md
├── AGENTS.md
├── Sources/KuaiClip
│   ├── App
│   │   └── KuaiClipApp.swift
│   ├── MenuBar
│   │   ├── MenuBarManager.swift
│   │   └── PopupPanel.swift
│   ├── Models
│   │   └── ClipboardItem.swift
│   ├── Services
│   │   ├── ClipboardMonitor.swift
│   │   ├── HistoryStore.swift
│   │   ├── HotkeyManager.swift
│   │   └── PasteService.swift
│   ├── Views
│   │   ├── AppTheme.swift
│   │   ├── HistoryRowView.swift
│   │   ├── Localization.swift
│   │   ├── PopupView.swift
│   │   └── PreferencesView.swift
│   └── Resources
│       └── Assets.xcassets
├── Tests/KuaiClipTests
│   └── TestRunner.swift
├── docs/images
└── scripts
    ├── package.sh
    ├── release.sh
    └── test.sh
```

## 重要なファイル

### `Package.swift`

Swift Package Manager の設定です。

- macOS 14 以上を対象にしています。
- 実行可能ターゲットは `KuaiClip` です。
- ソースコードは `Sources/KuaiClip` にあります。
- App アイコンなどのリソースは `Sources/KuaiClip/Resources` から処理されます。

### `Sources/KuaiClip/App/KuaiClipApp.swift`

アプリケーションのエントリーポイントです。

- `@main struct KuaiClipApp: App` が SwiftUI 側の起動入口です。
- `AppDelegate` が AppKit 側のライフサイクルを管理します。
- 起動時に以下を行います。
  - Dock 非表示のアクセサリアプリ化
  - テーマ適用
  - メニューバー初期化
  - クリップボード監視開始
  - グローバルショートカット登録
  - 初回アクセシビリティ権限案内

### `Sources/KuaiClip/MenuBar/MenuBarManager.swift`

メニューバーアイコン、ポップアップ、設定ウィンドウを管理します。

- `NSStatusItem` でメニューバーアイコンを作成します。
- 左クリックでポップアップを表示します。
- 右クリックメニューから履歴削除、設定、終了を実行します。
- `PopupView` を `NSHostingView` に包み、`PopupPanel` として表示します。
- `PreferencesView` を通常の `NSWindow` として表示します。

レビュー時は、ウィンドウのライフサイクル、閉じ忘れ、フォーカス喪失時の挙動を確認してください。

### `Sources/KuaiClip/MenuBar/PopupPanel.swift`

ポップアップ用の `NSPanel` です。

- キーウィンドウになれるように `canBecomeKey` を上書きしています。
- `performDrag(with:)` により、ネイティブで滑らかなドラッグ移動を行います。

### `Sources/KuaiClip/Models/ClipboardItem.swift`

クリップボード履歴 1 件を表すモデルです。

主なプロパティ:

- `content`: クリップボード内容
- `contentType`: テキスト、画像、ファイル URL、その他
- `timestamp`: 取得日時
- `isPinned`: 固定済みかどうか
- `isContentHidden`: 内容を非表示にするかどうか
- `shortcutKey`: 固定項目用のショートカット
- `imageData`: 元のピクセル寸法を維持したPNG画像データ

表示用の `preview`、`shortPreview`、`timeAgo` もここで生成します。

### `Sources/KuaiClip/Services/ClipboardMonitor.swift`

システムクリップボードを監視します。

- `NSPasteboard.general.changeCount` を定期的に確認します。
- テキスト、RTF、HTML、URL、ファイル URL、画像、その他データを抽出します。
- 抽出後は `HistoryStore` に保存します。
- App 自身のコピー操作を履歴へ戻さないため、`ignoreNextCopy` を持ちます。

レビュー時は、機密情報が意図せず再登録されないか、画像データが大きくなりすぎないかを確認してください。

### `Sources/KuaiClip/Services/HistoryStore.swift`

履歴データの中心です。

- 履歴の追加
- 重複排除
- 使用した未固定項目を未固定一覧の先頭へ移動
- 固定・固定解除
- 固定項目と未固定項目の分離
- 最大履歴数による削除
- `UserDefaults` への保存・読み込み

特に重要な仕様:

- 固定済みの内容が再コピーされても、未固定履歴として再追加しません。
- 固定済み内容と同じ未固定履歴が残っている場合は掃除します。
- 固定項目は最大10件で、表示キーは固定グループ内の `a`～`j` です。
- 未固定項目は最大100件、デフォルト50件で、固定項目とは別に `1` から採番します。
- `UserDefaults` を注入できるため、テストでは実ユーザーデータを汚染しません。

### `Sources/KuaiClip/Services/HotkeyManager.swift`

ポップアップ表示用のショートカットを管理します。

- 左 Command のダブルタップ
- Carbon HotKey によるカスタムショートカット
- アクセシビリティ権限がない場合のフォールバック

レビュー時は、イベントモニタの登録・解除漏れがないか確認してください。

### `Sources/KuaiClip/Services/PasteService.swift`

選択した履歴をシステムクリップボードへ戻し、必要に応じて前面アプリへペーストします。

- 通常コピー
- コピーして直接ペースト
- 書式なしペースト
- 固定項目や非表示項目の再履歴化防止

### `Sources/KuaiClip/Views/PopupView.swift`

メインのポップアップ UI です。

- 検索欄
- 履歴一覧
- 空状態
- ステータスバー
- テーマ切り替え
- キーボード操作
- マウス hover 選択
- マウスホイールとキーボードスクロールの競合防止
- 固定上限到達時の英日アラート
- 固定 `a`～`j` / 未固定 `1`～ の独立採番

レビュー時は、リストスクロール、選択状態、キーボード操作、マウス操作が互いに干渉しないか確認してください。

### `Sources/KuaiClip/Views/HistoryRowView.swift`

履歴一覧の 1 行を描画します。

- 固定・未固定グループ別のショートカット番号
- 固定アイコン
- 非表示アイコン
- 内容プレビュー
- 経過時間
- 削除ボタン
- コンテキストメニュー
- 長文プレビュー popover

### `Sources/KuaiClip/Views/PreferencesView.swift`

設定画面です。

- 一般設定
- ショートカット設定
- データ操作
- アプリ情報
- 英語・日本語・簡体字中国語切り替え

言語切り替え時には `MenuBarManager.refreshLocalization()` を呼び、メニュー表記も更新します。

### `Sources/KuaiClip/Views/Localization.swift`

英語・日本語・簡体字中国語の文言を集中管理します。

- 画面表示テキスト
- メニュー項目
- アラート文言
- 経過時間
- 空内容表示
- 画像・データ種別ラベル

新しい表示文言を追加する場合は、各 View に直接文字列を埋め込まず、原則としてここに追加してください。

### `Sources/KuaiClip/Views/AppTheme.swift`

テーマ色と macOS appearance を管理します。

- Light（Codex Desktop と同じ白背景・濃色前景）
- Dark（Codex Desktop と同じ `#181818` 背景・白前景）

UI フォントは macOS system font、コード・ショートカット表記は SF Mono 系の monospaced font を使用します。旧 `system` / `gray` 保存値は起動時に Light / Dark へ移行します。

背景色、アクセント色、境界線、区切り線をここで定義します。

## データの流れ

通常の利用時の流れは以下です。

```text
ユーザーが何かをコピーする
  ↓
ClipboardMonitor が NSPasteboard の変化を検知する
  ↓
内容を ClipboardItem として抽出する
  ↓
HistoryStore が重複排除・固定項目保護・保存を行う
  ↓
PopupView が HistoryStore の内容を表示する
  ↓
ユーザーが項目を選択する
  ↓
PasteService がコピーまたは直接ペーストを実行する
```

## テスト

このプロジェクトでは、標準 XCTest に依存しない軽量テスト runner を使います。  
現在のローカル Command Line Tools 環境では `XCTest` / `Testing` モジュールが利用できないためです。

実行コマンド:

```bash
bash scripts/test.sh
```

テスト対象:

- 履歴の重複排除
- 固定項目が未固定履歴として再追加されないこと
- 固定項目と同じ未固定履歴の掃除
- `clearUnpinned()` が固定項目を保持すること
- 最大履歴数による古い未固定項目の削除
- 固定10件上限と `a`～`j` の再採番
- 未固定履歴のデフォルト50件・最大100件への正規化
- 英語・日本語・簡体字中国語の文言切り替え
- 空内容プレビューのローカライズ

## ビルド

Debug ビルド:

```bash
swift build
```

Release ビルド:

```bash
swift build -c release
```

現在の制限付き実行環境では SwiftPM が内部で `sandbox-exec` を呼び、失敗する場合があります。  
その場合は、非サンドボックス環境で同じコマンドを実行してください。

## App パッケージ化

Release ビルド済みのバイナリから `.app` を作る場合:

```bash
BUILD_DIR=.build/release VERSION=1.11.1 bash scripts/package.sh
```

`scripts/package.sh` は以下を行います。

- `.app` ディレクトリ作成
- バイナリコピー
- `Info.plist` 生成
- AppIcon 生成
- 拡張属性削除
- 実行権限付与
- ad-hoc codesign

注意:

- `iconutil` が生成済み iconset を拒否する環境があります。
- その場合は `sips -s format icns` に fallback します。
- App の配布前には必ず `codesign --verify --deep --strict KuaiClip.app` を確認してください。

## リリース

タグ `v*` が push されると GitHub Actions が `.app` をパッケージ化し、GitHub Release を作成します。

標準的な流れ:

```bash
bash scripts/test.sh
swift build
swift build -c release
BUILD_DIR=.build/release VERSION=x.y.z bash scripts/package.sh
git add ...
git commit -m "vx.y.z: ..."
git tag -a vx.y.z -m "vx.y.z: ..."
git push origin main
git push origin vx.y.z
```

リリース後に確認すること:

- GitHub Actions が成功していること
- Release に `KuaiClip.app.zip` がアップロードされていること
- ダウンロードした `.app` の `CFBundleShortVersionString` がタグと一致すること
- `codesign --verify --deep --strict` が通ること

## レビュー観点

### セキュリティ・プライバシー

- クリップボード内容を外部送信していないこと。
- 固定項目や非表示項目が履歴へ再追加されないこと。
- パスワードなどを想定した hidden / pinned の扱いが壊れていないこと。
- 画像データが過度に大きく保存されないこと。

### macOS 連携

- `NSEvent` monitor、Carbon HotKey、Timer が適切に解除されること。
- アクセシビリティ権限がない場合でも fallback ショートカットが機能すること。
- `NSPanel` のフォーカス喪失時にポップアップが正しく閉じること。
- リサイズ・ドラッグ・スクロールが滑らかで、調整後のPopupサイズが復元されること。

### UI / UX

- ポップアップの背景、境界線、右下メニューの表示が崩れないこと。
- マウスホイールによるスクロール時に選択行がちらつかないこと。
- キーボード上下移動時は選択行へ自然に追従すること。
- Preferences の英語・日本語・簡体字中国語表示が崩れないこと。
- 長い文字列がボタンや行からはみ出さないこと。

### ローカライズ

- 新しい UI 文言は `Localization.swift` に追加すること。
- 英語・日本語・簡体字中国語を必ず用意すること。
- メニューバー右クリックメニュー、アラート、コンテキストメニューも対象に含めること。

### データ永続化

- `HistoryStore` の変更時は `scripts/test.sh` を必ず実行すること。
- `UserDefaults` のキー変更は既存ユーザーのデータ移行に注意すること。
- テストでは実ユーザーの `UserDefaults.standard` を直接汚染しないこと。

## 変更時の注意

- 既存の SwiftUI / AppKit の分担を尊重してください。
- UI だけで完結する処理は View に置いてよいですが、履歴・監視・ペーストなどの業務ロジックは Services に置いてください。
- 文字列の直書きは避け、基本的に `L10n` を使ってください。
- 共有状態は `HistoryStore.shared` など既存 singleton を優先してください。
- リファクタリングは必要最小限にし、動作変更と構造変更を混ぜすぎないでください。
- リリース対象の変更では、テスト、ビルド、パッケージ、署名確認まで行ってください。

## よくある確認コマンド

```bash
# テスト
bash scripts/test.sh

# Debug ビルド
swift build

# Release ビルド
swift build -c release

# App パッケージ
BUILD_DIR=.build/release VERSION=1.11.1 bash scripts/package.sh

# 署名確認
codesign --verify --deep --strict KuaiClip.app

# バージョン確認
plutil -extract CFBundleShortVersionString raw KuaiClip.app/Contents/Info.plist
```

## レビュアー向け要約

`KuaiClip` は小規模ですが、macOS 連携の密度が高いアプリです。  
レビューでは SwiftUI の見た目だけでなく、`NSPasteboard`、`NSPanel`、`NSEvent`、Carbon HotKey、`UserDefaults` の境界を重点的に確認してください。  
特に、機密情報を扱う固定・非表示項目の再履歴化防止、イベントモニタのライフサイクル、英日ローカライズの一貫性が重要です。
