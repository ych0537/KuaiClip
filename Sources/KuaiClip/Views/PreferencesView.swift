import SwiftUI
import AppKit
import ServiceManagement

struct PreferencesView: View {
    private enum SettingsTab: String, CaseIterable {
        case general, shortcuts, ai, about
    }

    @AppStorage("maxHistoryItems") private var maxHistoryItems: Int = HistoryStore.defaultUnpinnedItems
    @AppStorage("pollingInterval") private var pollingInterval: Double = 0.5
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("stripFormattingByDefault") private var stripFormattingByDefault: Bool = false
    @AppStorage("hotkey_useDoubleTap") private var useDoubleTapCommand: Bool = true
    @AppStorage("hotkey_keyCode") private var hotkeyKeyCode: Int = 8
    @AppStorage("hotkey_modifiers") private var hotkeyModifiers: Int = 512 | 256
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appearanceMode") private var appearanceMode: String = "light"
    @AppStorage(AppIconTheme.defaultsKey) private var appIconTheme: String = AppIconTheme.pandaTyping.rawValue

    @State private var historyCount: Int = 0
    @State private var isRecording: Bool = false
    @State private var recordMonitor: Any?
    @State private var selectedTab: SettingsTab = .general

    private var theme: AppTheme { AppTheme(appearanceMode) }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text(L10n.general).tag(SettingsTab.general)
                Text(L10n.shortcuts).tag(SettingsTab.shortcuts)
                Text(L10n.aiPolish).tag(SettingsTab.ai)
                Text(L10n.about).tag(SettingsTab.about)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 430)
            .padding(.top, 12)
            .padding(.bottom, 8)

            selectedTabContent
        }
        .frame(width: 520, height: 520)
        .background(theme.background)
        .preferredColorScheme(theme.colorScheme)
        .tint(theme.accent)
        .foregroundStyle(theme.foreground)
        .onAppear {
            maxHistoryItems = min(max(maxHistoryItems, 10), HistoryStore.maxUnpinnedItems)
            HistoryStore.shared.updateMaxItems(maxHistoryItems)
            historyCount = HistoryStore.shared.items.count
        }
        .onDisappear { stopRecording() }
        .onChange(of: appLanguage) { _, _ in
            MenuBarManager.shared.refreshLocalization()
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .general: generalTab
        case .shortcuts: shortcutsTab
        case .ai: AISettingsView()
        case .about: aboutTab
        }
    }

    private var generalTab: some View {
        Form {
            Section(L10n.behavior) {
                LabeledContent {
                    HStack(spacing: 8) {
                        Text("\(maxHistoryItems)")
                            .monospacedDigit()
                            .frame(minWidth: 42, alignment: .trailing)
                        Stepper("", value: $maxHistoryItems, in: 10...HistoryStore.maxUnpinnedItems, step: 10)
                            .labelsHidden()
                            .fixedSize()
                    }
                } label: {
                    settingLabel(L10n.maxHistory, detail: L10n.maxHistoryDetail, icon: "clock.arrow.circlepath")
                }
                .onChange(of: maxHistoryItems) { _, value in
                    HistoryStore.shared.updateMaxItems(value)
                    historyCount = HistoryStore.shared.items.count
                }

                LabeledContent {
                    Picker("", selection: $pollingInterval) {
                        Text("0.25s").tag(0.25)
                        Text("0.5s").tag(0.5)
                        Text("1s").tag(1.0)
                        Text("2s").tag(2.0)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 105)
                } label: {
                    settingLabel(L10n.polling, icon: "waveform.path.ecg")
                }

                Toggle(isOn: $launchAtLogin) {
                    settingLabel(L10n.launchAtLogin, icon: "power")
                }
                .onChange(of: launchAtLogin) { _, value in setLoginItem(enabled: value) }

                Toggle(isOn: $stripFormattingByDefault) {
                    settingLabel(L10n.stripFmt, icon: "textformat")
                }
            }

            Section(L10n.language) {
                LabeledContent {
                    Picker("", selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                        Text("简体中文").tag("zh")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 265)
                } label: {
                    settingLabel(L10n.language, icon: "globe")
                }
            }

            Section(L10n.appIcon) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(AppIconTheme.allCases) { icon in
                        Button {
                            appIconTheme = icon.rawValue
                            icon.apply()
                        } label: {
                            VStack(spacing: 6) {
                                if let image = icon.appImage {
                                    Image(nsImage: image)
                                        .resizable()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Text(icon.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(7)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        appIconTheme == icon.rawValue ? theme.accent : theme.border,
                                        lineWidth: appIconTheme == icon.rawValue ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(L10n.data) {
                LabeledContent {
                    Text("\(historyCount)")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                } label: {
                    settingLabel(L10n.historyItems, icon: "list.clipboard")
                }

                Button(role: .destructive) {
                    HistoryStore.shared.clearAll()
                    historyCount = 0
                } label: {
                    Label(L10n.clearAll, systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }

    private var shortcutsTab: some View {
        Form {
            Section(L10n.popupActivation) {
                LabeledContent {
                    Picker("", selection: Binding(
                        get: { useDoubleTapCommand ? "double" : "custom" },
                        set: { value in
                            useDoubleTapCommand = value == "double"
                            HotkeyManager.shared.reregisterIfNeeded()
                        }
                    )) {
                        Text(L10n.doubleTap).tag("double")
                        Text(L10n.custom).tag("custom")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 265)
                } label: {
                    settingLabel(L10n.activationMode, icon: "command")
                }

                if useDoubleTapCommand && !AXIsProcessTrusted() {
                    Label(L10n.accWarning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if !useDoubleTapCommand {
                    LabeledContent {
                        HStack(spacing: 8) {
                            shortcutBadge(HotkeyManager.shared.carbonDescription(
                                keyCode: UInt32(hotkeyKeyCode),
                                modifiers: UInt32(hotkeyModifiers)
                            ))
                            if isRecording {
                                Text(L10n.pressKeys).font(.caption).foregroundColor(.accentColor)
                                    .onAppear { installRecordMonitor() }
                            } else {
                                Button(L10n.record) { isRecording = true }
                                Button(L10n.reset) { resetHotkey() }
                            }
                        }
                    } label: {
                        settingLabel(L10n.currentShortcut, icon: "keyboard")
                    }
                }
            }

            Section(L10n.withinPopup) {
                shortcutRow("↩", L10n.copySelected)
                shortcutRow("⌥↩", L10n.copyPaste)
                shortcutRow("⌥⇧↩", L10n.pastePlain)
                shortcutRow("⌘1–9", L10n.copyNumber)
                shortcutRow("⌘A–J", L10n.copyPinnedLetter)
                shortcutRow("⌥⌫", L10n.deleteSelected)
                shortcutRow("⌥P", L10n.pinUnpin)
                shortcutRow("⌥⌘⌫", L10n.clearUnpinned)
                shortcutRow("Esc", L10n.dismiss)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }

    private var aboutTab: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("KuaiClip").font(.title2).fontWeight(.semibold)
            Text(L10n.appDescription).foregroundColor(.secondary)
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                .font(.caption).foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.background)
    }

    private func settingLabel(_ title: String, detail: String? = nil, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let detail {
                    Text(detail).font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private func shortcutRow(_ key: String, _ description: String) -> some View {
        LabeledContent(description) {
            shortcutBadge(key)
        }
    }

    private func shortcutBadge(_ key: String) -> some View {
        Text(key)
            .font(theme.codeFont(size: 11, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
    }

    private func installRecordMonitor() {
        stopRecording()
        recordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = HotkeyManager.carbonModifiersFromNSEvent(event)
            guard mods != 0 else { stopRecording(); return nil }
            hotkeyKeyCode = Int(event.keyCode)
            hotkeyModifiers = Int(mods)
            HotkeyManager.shared.applyCustomFromStorage()
            isRecording = false
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = recordMonitor {
            NSEvent.removeMonitor(monitor)
            recordMonitor = nil
        }
        isRecording = false
    }

    private func resetHotkey() {
        hotkeyKeyCode = 8
        hotkeyModifiers = 512 | 256
        HotkeyManager.shared.applyCustomFromStorage()
    }

    private func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[KuaiClip] Login item error: %@", error.localizedDescription)
        }
    }
}
