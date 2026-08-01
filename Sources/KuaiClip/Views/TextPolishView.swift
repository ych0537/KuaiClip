import AppKit
import SwiftUI

struct TextPolishView: View {
    private enum Action: String, CaseIterable, Identifiable {
        case polish, translate
        var id: String { rawValue }
        var title: String { self == .polish ? L10n.polishAction : L10n.translateAction }
    }

    let source: String
    let onCopy: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @AppStorage("appLanguage") private var appLanguage = "en"
    @AppStorage(TextPolishService.defaultModelKey) private var defaultModelValue = ""
    @AppStorage(TextPolishService.translationTargetLanguageKey) private var targetLanguageValue = TranslationLanguage.english.rawValue
    @State private var result = ""
    @State private var action = Action.polish
    @State private var selectedModel: AIModel?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var theme: AppTheme { AppTheme(appearanceMode) }
    private var models: [AIModel] { TextPolishService.availableModels() }
    private var isOverLimit: Bool { source.count > TextPolishService.maximumCharacterCount }
    private var targetLanguage: Binding<TranslationLanguage> {
        Binding(
            get: { TranslationLanguage(rawValue: targetLanguageValue) ?? .english },
            set: { targetLanguageValue = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(action == .polish ? L10n.polishText : L10n.translateAction).font(.headline)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain)
            }
            textBox(source)
            HStack {
                if isOverLimit {
                    Label(
                        limitMessage,
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
            VStack(spacing: 10) {
                HStack {
                    Picker("", selection: $action) {
                        ForEach(Action.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .disabled(isLoading)
                    if action == .translate {
                        Picker(L10n.targetLanguage, selection: targetLanguage) {
                            ForEach(TranslationLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .frame(width: 210)
                        .disabled(isLoading)
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Picker(L10n.aiModel, selection: $selectedModel) {
                        ForEach(models) { Text($0.displayName).tag(Optional($0)) }
                    }.frame(width: 250)
                    Button { runPolish() } label: {
                        HStack(spacing: 6) {
                            if isLoading { ProgressView().controlSize(.small) }
                            Text(action.title)
                        }
                        .frame(minWidth: 72)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || selectedModel == nil || isOverLimit)
                }
            }
            if models.isEmpty {
                Text(L10n.configureAIKey).foregroundStyle(.orange).font(.caption)
            }
            ZStack(alignment: .bottomTrailing) {
                textBox(result.isEmpty ? resultPlaceholder : result)
                    .foregroundStyle(result.isEmpty ? .secondary : theme.foreground)
                if !result.isEmpty {
                    Button { copyResult() } label: { Image(systemName: "doc.on.doc") }
                        .buttonStyle(.borderless).padding(12)
                }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }
        }
        .padding(20).frame(width: 650, height: 480).background(theme.background)
        .onAppear {
            selectedModel = TextPolishService.defaultModel(
                storedValue: defaultModelValue,
                availableModels: models
            )
        }
        .onChange(of: action) { _, _ in
            result = ""
            errorMessage = nil
        }
    }

    private func textBox(_ text: String) -> some View {
        ScrollView { Text(text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(14) }
            .frame(maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(theme.foreground.opacity(0.06)))
    }

    private func runPolish() {
        guard let selectedModel, !isOverLimit else { return }
        if action == .polish { UsageMetrics.shared.recordPolishRun() }
        isLoading = true; errorMessage = nil
        Task {
            do {
                switch action {
                case .polish:
                    result = try await TextPolishService.polish(source, using: selectedModel)
                case .translate:
                    result = try await TextPolishService.translate(source, to: targetLanguage.wrappedValue, using: selectedModel)
                }
            }
            catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    private var resultPlaceholder: String {
        action == .polish ? L10n.polishedResultPlaceholder : L10n.translatedResultPlaceholder
    }

    private var limitMessage: String {
        action == .polish
            ? L10n.polishTextTooLong(TextPolishService.maximumCharacterCount)
            : L10n.translationTextTooLong(TextPolishService.maximumCharacterCount)
    }

    private func copyResult() {
        ClipboardMonitor.shared.setIgnoreNextCopy(true)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        HistoryStore.shared.addItem(result, contentType: .text)
        onCopy()
    }
}
