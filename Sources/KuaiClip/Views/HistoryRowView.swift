import AppKit
import SwiftUI

/// A single row in the clipboard history list
struct HistoryRowView: View {
    private static let thumbnailSize: CGFloat = 76

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
    let onPolish: () -> Void
    let onFormatJSON: () -> Void
    let theme: AppTheme

    @State private var showTooltip: Bool = false
    @State private var tooltipWorkItem: DispatchWorkItem?
    @State private var isTextTruncated: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(shortcutLabel)
                .font(theme.uiFont(size: 12, weight: .medium))
                .foregroundColor(theme.secondaryForeground)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 24, alignment: .leading)

            if item.contentType == .image, !item.isContentHidden {
                imageThumbnail
            }

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
                    Text(rowDisplayText)
                        .font(theme.uiFont(size: 12))
                        .lineLimit(2)
                        .foregroundColor(theme.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear { updateTruncation(for: geometry.size.width) }
                                    .onChange(of: geometry.size.width) { _, width in
                                        updateTruncation(for: width)
                                    }
                            }
                        }
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

                if shouldShowPolishButton {
                    Button { onPolish() } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? theme.foreground : theme.accent)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.polishText)
                }

                if isJSON, !item.isContentHidden {
                    Button { onFormatJSON() } label: {
                        Image(systemName: "curlybraces")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isSelected ? theme.foreground : theme.accent)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.formatJSONAndCopy)
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
        .padding(.horizontal, 2).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 9).fill(isSelected ? theme.selectionBackground : Color.clear))
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.divider).frame(height: 0.5).padding(.leading, 28)
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
        .onHover { hovering in
            if hovering && needsTextTooltip {
                scheduleTooltip()
            } else {
                cancelTooltip()
                showTooltip = false
            }
        }
        .popover(isPresented: $showTooltip, arrowEdge: .trailing) {
            ScrollView {
                Text(item.content)
                    .font(theme.uiFont(size: 12))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(width: tooltipSize.width, height: tooltipSize.height)
        }
        .simultaneousGesture(TapGesture(count: 1).modifiers(.option).onEnded { onOptionTap() })
        .simultaneousGesture(TapGesture(count: 1).modifiers([.option, .shift]).onEnded { onOptionShiftTap() })
    }

    private var needsTextTooltip: Bool {
        item.contentType != .image && !item.isContentHidden && isTextTruncated
    }

    private var shouldShowPolishButton: Bool {
        guard item.contentType != .image, !item.isContentHidden else { return false }
        return PolishableTextClassifier.shouldOfferPolish(for: item.content)
    }

    private var isJSON: Bool {
        JSONTextFormatter.formatted(item.content) != nil
    }

    private var tooltipSize: CGSize {
        let font = NSFont.systemFont(ofSize: 12)
        let maxTextWidth: CGFloat = 400
        let bounds = (item.content as NSString).boundingRect(
            with: NSSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return CGSize(
            width: min(max(220, ceil(bounds.width) + 32), 432),
            height: min(max(70, ceil(bounds.height) + 32), 300)
        )
    }

    private var rowDisplayText: String {
        if item.isContentHidden {
            return String(repeating: "•", count: min(item.content.count, 20))
        }
        return item.content
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateTruncation(for width: CGFloat) {
        guard item.contentType != .image, !item.isContentHidden, width > 0 else {
            isTextTruncated = false
            return
        }
        let font = NSFont.systemFont(ofSize: 12)
        let bounds = (rowDisplayText as NSString).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        let truncated = ceil(bounds.height) > ceil(font.boundingRectForFont.height * 2) + 1
        if isTextTruncated != truncated {
            isTextTruncated = truncated
            if !truncated {
                cancelTooltip()
                showTooltip = false
            }
        }
    }

    private var imageThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.foreground.opacity(0.05))
            if let data = item.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .foregroundColor(theme.secondaryForeground.opacity(0.55))
            }
        }
        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).stroke(theme.border, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
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
