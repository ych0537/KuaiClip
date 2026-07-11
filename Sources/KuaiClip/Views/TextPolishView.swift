import AppKit
import SwiftUI

struct TextPolishView: View {
    let source: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @State private var result = ""
    @State private var selectedModel: AIModel?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var theme: AppTheme { AppTheme(appearanceMode) }
    private var models: [AIModel] { TextPolishService.availableModels() }
    private var isOverLimit: Bool { source.count > TextPolishService.maximumCharacterCount }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(L10n.polishText).font(.headline)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain)
            }
            textBox(source)
            HStack {
                if isOverLimit {
                    Label(
                        L10n.polishTextTooLong(TextPolishService.maximumCharacterCount),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.red)
                }
                Spacer()
                Text(L10n.characterCount(source.count, limit: TextPolishService.maximumCharacterCount))
                    .monospacedDigit()
                    .foregroundStyle(isOverLimit ? .red : .secondary)
            }
            .font(.caption)
            HStack {
                Label(L10n.professionalPolish, systemImage: "wand.and.stars")
                Spacer()
                Picker(L10n.aiModel, selection: $selectedModel) {
                    ForEach(models) { Text($0.displayName).tag(Optional($0)) }
                }.frame(width: 250)
                Button { runPolish() } label: {
                    if isLoading { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.up.circle.fill") }
                }.disabled(isLoading || selectedModel == nil || isOverLimit)
            }
            if models.isEmpty {
                Text(L10n.configureAIKey).foregroundStyle(.orange).font(.caption)
            }
            ZStack(alignment: .bottomTrailing) {
                textBox(result.isEmpty ? L10n.polishedResultPlaceholder : result)
                    .foregroundStyle(result.isEmpty ? .secondary : theme.foreground)
                if !result.isEmpty {
                    Button { copyResult() } label: { Image(systemName: "doc.on.doc") }
                        .buttonStyle(.borderless).padding(12)
                }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }
        }
        .padding(20).frame(width: 650, height: 480).background(theme.background)
        .onAppear { selectedModel = models.first }
    }

    private func textBox(_ text: String) -> some View {
        ScrollView { Text(text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(14) }
            .frame(maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(theme.foreground.opacity(0.06)))
    }

    private func runPolish() {
        guard let selectedModel, !isOverLimit else { return }
        isLoading = true; errorMessage = nil
        Task {
            do { result = try await TextPolishService.polish(source, using: selectedModel) }
            catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    private func copyResult() {
        ClipboardMonitor.shared.setIgnoreNextCopy(true)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
    }
}
