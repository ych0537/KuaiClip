import SwiftUI

/// A single row in the clipboard history list
struct HistoryRowView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    let item: ClipboardItem
    let isSelected: Bool
    let shortcutLabel: String
    let onTap: () -> Void
    let onOptionTap: () -> Void
    let onOptionShiftTap: () -> Void
    let onToggleHide: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    let theme: AppTheme

    @State private var showTooltip: Bool = false
    @State private var tooltipWorkItem: DispatchWorkItem?

    var body: some View {
        HStack(spacing: 8) {
            Text(shortcutLabel)
                .font(theme.codeFont(size: shortcutLabel.count >= 3 ? 11 : 14, weight: .bold))
                .foregroundColor(
                    isSelected ? theme.foreground :
                    theme.accent.opacity(0.8)
                )
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 7))
                            .foregroundColor(isSelected ? theme.foreground.opacity(0.7) : .orange)
                    }
                    if item.isContentHidden {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 7))
                            .foregroundColor(isSelected ? theme.foreground.opacity(0.5) : .secondary)
                    }
                    Text(item.isContentHidden
                         ? String(repeating: "•", count: min(item.content.count, 20))
                         : item.preview)
                        .font(theme.uiFont(size: 12))
                        .lineLimit(2)
                        .foregroundColor(theme.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 6) {
                Text(item.timeAgo)
                    .font(theme.uiFont(size: 9))
                    .foregroundColor(isSelected ? theme.foreground.opacity(0.5) : theme.secondaryForeground.opacity(0.6))
                    .fixedSize()

                if item.isPinned {
                    Image(systemName: item.isContentHidden ? "eye" : "eye.slash")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? theme.foreground.opacity(0.7) : theme.secondaryForeground.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture { onToggleHide() }
                }

                if isSelected {
                    Button { onDelete() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.foreground.opacity(0.6))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 5).fill(isSelected ? theme.selectionBackground : Color.clear))
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.divider).frame(height: 0.5).padding(.leading, 36)
        }
        .contextMenu {
            Button { onTogglePin() } label: {
                Label(item.isPinned ? L10n.unpin : L10n.pin,
                      systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            if item.isPinned {
                Button { onToggleHide() } label: {
                    Label(item.isContentHidden ? L10n.showContent : L10n.hideContent,
                          systemImage: item.isContentHidden ? "eye" : "eye.slash")
                }
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
        .onTapGesture { onTap() }
        .onHover { h in if h { scheduleTooltip() } else { cancelTooltip(); showTooltip = false } }
        .popover(isPresented: $showTooltip, arrowEdge: .trailing) {
            ScrollView {
                Text(item.isContentHidden
                     ? String(repeating: "•", count: min(item.content.count, 40)) : item.content)
                    .font(theme.uiFont(size: 11)).padding(8)
                    .frame(minWidth: 220, maxWidth: 360, maxHeight: 180)
            }.frame(minWidth: 220, maxWidth: 360, maxHeight: 180)
        }
        .simultaneousGesture(TapGesture(count: 1).modifiers(.option).onEnded { onOptionTap() })
        .simultaneousGesture(TapGesture(count: 1).modifiers([.option, .shift]).onEnded { onOptionShiftTap() })
    }

    private func scheduleTooltip() {
        let workItem = DispatchWorkItem { DispatchQueue.main.async { self.showTooltip = true } }
        tooltipWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func cancelTooltip() {
        tooltipWorkItem?.cancel(); tooltipWorkItem = nil
    }
}
