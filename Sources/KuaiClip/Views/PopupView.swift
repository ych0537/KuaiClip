import SwiftUI
import AppKit

/// The main popup window view with search and clipboard history list
struct PopupView: View {
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    @State private var keyboardScrollRequest: Int = 0
    @State private var isMouseScrolling: Bool = false
    @State private var showPinLimitAlert: Bool = false
    @State private var polishItem: ClipboardItem?
    private let historyStore = HistoryStore.shared
    @FocusState private var isSearchFocused: Bool

    @AppStorage("appearanceMode") private var appearanceMode: String = "light"
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    let onPinLimitAlertPresented: () -> Void
    let onDismiss: () -> Void

    private var theme: AppTheme { AppTheme(appearanceMode) }

    var filteredItems: [ClipboardItem] {
        let allItems = historyStore.allItemsOrdered
        if searchText.isEmpty {
            return allItems
        }
        return allItems.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.shortPreview.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()

            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }

            Divider()
            statusBar
        }
        .frame(minWidth: 340, minHeight: 400)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .preferredColorScheme(theme.colorScheme)
        .tint(theme.accent)
        .foregroundStyle(theme.foreground)
        .onAppear {
            AppTheme.applyAppearance(appearanceMode)
            isSearchFocused = true
            // Select first non-pinned item by default
            selectedIndex = filteredItems.firstIndex(where: { !$0.isPinned }) ?? 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = filteredItems.firstIndex(where: { !$0.isPinned }) ?? 0
        }
        .onChange(of: historyStore.items) { _, _ in
            if selectedIndex >= filteredItems.count {
                selectedIndex = max(0, filteredItems.count - 1)
            }
        }
        .alert(L10n.pinLimitTitle, isPresented: $showPinLimitAlert) {
            Button(L10n.ok, role: .cancel) {
                onDismiss()
            }
        } message: {
            Text(L10n.pinLimitMessage)
        }
        .sheet(item: $polishItem) { item in
            TextPolishView(source: item.content) {
                polishItem = nil
                DispatchQueue.main.async { onDismiss() }
            }
        }
        .modifier(PopupKeyboardHandler(
            selectedIndex: $selectedIndex,
            keyboardScrollRequest: $keyboardScrollRequest,
            isMouseScrolling: $isMouseScrolling,
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            isAlertPresented: $showPinLimitAlert,
            getFilteredItems: { filteredItems },
            onPinLimitReached: presentPinLimitAlert,
            onDismiss: onDismiss
        ))
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(theme.uiFont(size: 11))
            TextField(L10n.search, text: $searchText)
                .textFieldStyle(.plain)
                .font(theme.uiFont(size: 12))
                .focused($isSearchFocused)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryForeground).font(theme.uiFont(size: 10))
                }.buttonStyle(.plain)
            }
            Spacer()
            themeToggle
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
    }

    private var themeToggle: some View {
        Button {
            NSLog("[KuaiClip] themeToggle tapped, current: \(appearanceMode)")
            toggleAppearance()
        } label: {
            Image(systemName: appearanceIcon)
                .font(theme.uiFont(size: 14))
                .foregroundColor(theme.secondaryForeground)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(L10n.themeHelp)
    }

    private var appearanceIcon: String {
        theme == .dark ? "moon.fill" : "sun.max.fill"
    }


    private func toggleAppearance() {
        let old = appearanceMode
        appearanceMode = theme == .dark ? AppTheme.light.rawValue : AppTheme.dark.rawValue
        NSLog("[KuaiClip] appearanceMode toggled: \(old) → \(appearanceMode)")
        applyAppearance()
    }

    private func applyAppearance() {
        AppTheme.applyAppearance(appearanceMode)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))

            Text(historyStore.items.isEmpty
                 ? L10n.noHistory
                 : L10n.noMatches)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if historyStore.items.isEmpty {
                Text(L10n.copyToStart)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    private var itemList: some View {
        let pinnedCount = filteredItems.filter { $0.isPinned }.count
        return ScrollViewReader { proxy in
            List {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    // Divider between pinned and unpinned items
                    if index == pinnedCount, pinnedCount > 0, pinnedCount < filteredItems.count {
                        Divider()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                    HistoryRowView(
                        item: item,
                        isSelected: index == selectedIndex,
                        shortcutLabel: shortcutLabel(for: item, at: index),
                        onTap: { selectAndCopy(item) },
                        onOptionTap: { selectAndPaste(item) },
                        onOptionShiftTap: { selectAndPasteWithoutFormatting(item) },
                        onToggleHide: { toggleHideContent(item) },
                        onDelete: { deleteItem(item) },
                        onTogglePin: { togglePinSelected(item) },
                        onPolish: {
                            UsageMetrics.shared.recordPolishWindowOpened()
                            polishItem = item
                        },
                        theme: theme
                    )
                    .id(index)
                    .listRowInsets(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                    .listRowSeparator(.hidden)
                    .onHover { hovering in
                        if hovering && !isMouseScrolling {
                            selectedIndex = index
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .onChange(of: keyboardScrollRequest) { _, _ in
                withAnimation {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Text(L10n.itemCount(filteredItems.count))
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            if HistoryStore.shared.pinnedItems.count > 0 {
                Text(L10n.pinnedCount(HistoryStore.shared.pinnedItems.count))
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            }

            Spacer()

            Menu {
                Button(L10n.clearUnpinned) {
                    HistoryStore.shared.clearUnpinned()
                    if filteredItems.isEmpty { onDismiss() }
                }
                Button(L10n.clearAllItems) {
                    HistoryStore.shared.clearAll()
                    onDismiss()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private func toggleHideContent(_ item: ClipboardItem) {
        HistoryStore.shared.setContentHidden(item, hidden: !item.isContentHidden)
    }

    private func deleteItem(_ item: ClipboardItem) {
        HistoryStore.shared.removeItem(item)
    }

    private func togglePinSelected(_ item: ClipboardItem) {
        if HistoryStore.shared.togglePin(item) == .limitReached {
            presentPinLimitAlert()
        }
    }

    private func presentPinLimitAlert() {
        onPinLimitAlertPresented()
        showPinLimitAlert = true
    }

    private func shortcutLabel(for item: ClipboardItem, at index: Int) -> String {
        if item.isPinned {
            return item.shortcutKey ?? "-"
        }
        let unpinnedIndex = filteredItems[..<index].filter { !$0.isPinned }.count + 1
        return String(unpinnedIndex)
    }

    // MARK: - Helpers

    private var selectedItem: ClipboardItem? {
        guard selectedIndex < filteredItems.count else { return nil }
        return filteredItems[selectedIndex]
    }

    private func selectAndCopy(_ item: ClipboardItem) {
        selectedIndex = filteredItems.firstIndex(of: item) ?? selectedIndex
        PasteService.shared.copyToClipboard(item)
        onDismiss()
    }

    private func selectAndPaste(_ item: ClipboardItem) {
        selectedIndex = filteredItems.firstIndex(of: item) ?? selectedIndex
        let isHidden = item.isContentHidden
        PasteService.shared.copyAndPaste(item)
        if isHidden { HistoryStore.shared.removeItem(item) }
        onDismiss()
    }

    private func selectAndPasteWithoutFormatting(_ item: ClipboardItem) {
        selectedIndex = filteredItems.firstIndex(of: item) ?? selectedIndex
        let isHidden = item.isContentHidden
        PasteService.shared.copyAndPaste(item, pasteWithoutFormatting: true)
        if isHidden { HistoryStore.shared.removeItem(item) }
        onDismiss()
    }
}

// MARK: - Keyboard Handler

struct PopupKeyboardHandler: ViewModifier {
    @Binding var selectedIndex: Int
    @Binding var keyboardScrollRequest: Int
    @Binding var isMouseScrolling: Bool
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var isAlertPresented: Bool
    /// Closure that returns the current filtered items on demand,
    /// so the keyboard monitor always sees up-to-date data.
    let getFilteredItems: () -> [ClipboardItem]
    @AppStorage("appearanceMode") private var appearanceMode: String = "light"
    let onPinLimitReached: () -> Void
    let onDismiss: () -> Void

    @State private var localEventMonitor: Any? = nil
    @State private var scrollEndWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .onAppear {
                installKeyboardMonitor()
            }
            .onDisappear {
                removeKeyboardMonitor()
                scrollEndWorkItem?.cancel()
            }
    }

    /// Current filtered items, always computed fresh.
    private var filteredItems: [ClipboardItem] { getFilteredItems() }

    private func installKeyboardMonitor() {
        guard localEventMonitor == nil else { return }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .scrollWheel]) { event in
            guard !isAlertPresented else { return event }

            if event.type == .scrollWheel {
                handleMouseScroll()
                return event
            }

            guard event.characters != nil else { return event }
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if let shortcut = event.charactersIgnoringModifiers?.lowercased(),
               HistoryStore.pinnedShortcutLabels.contains(shortcut),
               modifiers.contains(.command) || modifiers.contains(.option) {
                if modifiers.contains([.option, .shift]) {
                    handlePinnedItem(shortcut, mode: .pasteWithoutFormatting)
                } else if modifiers.contains(.option) {
                    handlePinnedItem(shortcut, mode: .pasteWithFormatting)
                } else {
                    handlePinnedItem(shortcut, mode: .copy)
                }
                return nil
            }

            switch event.keyCode {
            // ENTER (36) or numpad ENTER (76)
            case 36, 76:
                if modifiers.contains([.command]) {
                    // CMD+ENTER → ignore (system)
                    return event
                }
                if modifiers.contains([.option, .shift]) {
                    handlePasteWithoutFormatting()
                } else if modifiers.contains(.option) {
                    handleCopyAndPaste()
                } else if modifiers.isEmpty || modifiers == .numericPad {
                    handleCopy()
                }
                return nil

            // ESC (53)
            case 53:
                if modifiers.isEmpty {
                    onDismiss()
                }
                return nil

            // DELETE / BACKSPACE (51)
            case 51:
                if modifiers.contains([.option, .command, .shift]) {
                    handleClearAll()
                } else if modifiers.contains([.option, .command]) {
                    handleClearUnpinned()
                } else if modifiers.contains(.option) {
                    handleDeleteSelected()
                } else {
                    return event
                }
                return nil

             // UP ARROW (126)
            case 126:
                moveSelection(up: true)
                return nil

              // DOWN ARROW (125)
            case 125:
                if modifiers.contains(.command) {
                    return event
                 }
                moveSelection(up: false)
                return nil

            // Number keys 1-9 with CMD/OPTION/OPTION+SHIFT combinations
            case 18...29:
                let keyMap: [UInt16: Int] = [
                    18: 1, 19: 2, 20: 3, 21: 4,
                    23: 5, 22: 6, 26: 7, 28: 8, 25: 9
                ]
                if let num = keyMap[event.keyCode] {
                    if modifiers.contains([.option, .shift]) {
                        handleNumberItem(num, mode: .pasteWithoutFormatting)
                    } else if modifiers.contains(.option) {
                        handleNumberItem(num, mode: .pasteWithFormatting)
                    } else if modifiers.contains(.command) {
                        handleNumberItem(num, mode: .copy)
                    } else {
                        return event
                    }
                    return nil
                }
                return event

            // P key (35)
            case 35:
                if modifiers.contains(.option) {
                    handleTogglePin()
                    return nil
                }
                return event

            // Comma key with CMD
            case 43:
                if modifiers.contains(.command) {
                    // Let system handle CMD+, for Preferences
                    return event
                }
                return event

            default:
                // Allow regular typing in search field
                return event
            }
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func handleMouseScroll() {
        isMouseScrolling = true
        scrollEndWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                self.isMouseScrolling = false
            }
        }
        scrollEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    // MARK: - Actions

    private func handleCopy() {
        guard let item = selectedItem else { return }
        PasteService.shared.copyToClipboard(item)
        onDismiss()
    }

    private func handleCopyAndPaste() {
        guard let item = selectedItem else { return }
        let isHidden = item.isContentHidden
        PasteService.shared.copyAndPaste(item)
        if isHidden { HistoryStore.shared.removeItem(item) }
        onDismiss()
    }

    private func handlePasteWithoutFormatting() {
        guard let item = selectedItem else { return }
        let isHidden = item.isContentHidden
        PasteService.shared.copyAndPaste(item, pasteWithoutFormatting: true)
        if isHidden { HistoryStore.shared.removeItem(item) }
        onDismiss()
    }

    private func handleDeleteSelected() {
        guard let item = selectedItem else { return }
        HistoryStore.shared.removeItem(item)
        if filteredItems.isEmpty {
            onDismiss()
        }
    }

    private func handleTogglePin() {
        guard let item = selectedItem else { return }
        if HistoryStore.shared.togglePin(item) == .limitReached {
            onPinLimitReached()
        }
    }

    private func handleClearUnpinned() {
        HistoryStore.shared.clearUnpinned()
        if filteredItems.isEmpty {
            onDismiss()
        }
    }

    private func handleClearAll() {
        HistoryStore.shared.clearAll()
        onDismiss()
    }

    private enum NumberItemMode {
        case copy
        case pasteWithFormatting
        case pasteWithoutFormatting
    }

    private func handleNumberItem(_ num: Int, mode: NumberItemMode) {
        let unpinnedItems = filteredItems.filter { !$0.isPinned }
        let index = num - 1
        guard index < unpinnedItems.count else { return }
        performAction(on: unpinnedItems[index], mode: mode)
    }

    private func handlePinnedItem(_ shortcut: String, mode: NumberItemMode) {
        guard let item = filteredItems.first(where: {
            $0.isPinned && $0.shortcutKey == shortcut
        }) else { return }
        performAction(on: item, mode: mode)
    }

    private func performAction(on item: ClipboardItem, mode: NumberItemMode) {
        let isHidden = item.isContentHidden

        switch mode {
        case .copy:
            PasteService.shared.copyToClipboard(item)
        case .pasteWithFormatting:
            PasteService.shared.copyAndPaste(item)
        case .pasteWithoutFormatting:
            PasteService.shared.copyAndPaste(item, pasteWithoutFormatting: true)
        }
        if isHidden { HistoryStore.shared.removeItem(item) }
        onDismiss()
    }

    private func moveSelection(up: Bool) {
        guard !filteredItems.isEmpty else { return }
        let oldIndex = selectedIndex
        if up {
            selectedIndex = max(0, selectedIndex - 1)
        } else {
            selectedIndex = min(filteredItems.count - 1, selectedIndex + 1)
        }
        if selectedIndex != oldIndex {
            keyboardScrollRequest += 1
        }
    }

    private var selectedItem: ClipboardItem? {
        guard selectedIndex < filteredItems.count else { return nil }
        return filteredItems[selectedIndex]
    }
}
