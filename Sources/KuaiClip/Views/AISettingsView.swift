import SwiftUI

struct AISettingsView: View {
    private enum KeyOperationStatus {
        case saved, deleted
    }

    private enum Provider: String, CaseIterable, Identifiable {
        case appleIntelligence = "apple-intelligence"
        case openAI = "openai"
        case gemini
        case deepSeek = "deepseek"
        case ollama

        var id: String { rawValue }
        var title: String {
            switch self {
            case .appleIntelligence: return "Apple Intelligence"
            case .openAI: return "OpenAI"
            case .gemini: return "Gemini"
            case .deepSeek: return "DeepSeek"
            case .ollama: return "Ollama"
            }
        }
        var placeholder: String {
            switch self {
            case .appleIntelligence: return ""
            case .openAI: return "sk-proj-…"
            case .gemini: return "AIza…"
            case .deepSeek: return "sk-…"
            case .ollama: return ""
            }
        }

        var requiresAPIKey: Bool {
            self != .appleIntelligence && self != .ollama
        }
    }

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @AppStorage("aiSettingsProvider") private var providerValue = Provider.openAI.rawValue
    @State private var apiKey = ""
    @State private var hasStoredKey = false
    @State private var keyOperationStatus: KeyOperationStatus?
    @AppStorage("ollamaModel") private var ollamaModel = ""
    @State private var ollamaModels: [String] = []
    @State private var isLoadingOllamaModels = false
    @State private var ollamaError: String?

    private var theme: AppTheme { AppTheme(appearanceMode) }
    private var provider: Provider { Provider(rawValue: providerValue) ?? .openAI }

    var body: some View {
        Form {
            Section(L10n.aiProviders) {
                settingsRow(L10n.aiProvider) {
                    Picker("", selection: $providerValue) {
                        ForEach(Provider.allCases) { provider in
                            Text(provider.title).tag(provider.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                if provider.requiresAPIKey {
                    settingsRow(L10n.apiKey) {
                        SecureField("", text: $apiKey, prompt: Text(provider.placeholder))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if provider == .ollama {
                    settingsRow(L10n.ollamaModel) {
                        HStack(spacing: 8) {
                            Picker("", selection: $ollamaModel) {
                                if ollamaModels.isEmpty {
                                    if ollamaModel.isEmpty {
                                        Text(L10n.noOllamaModels).tag("")
                                    } else {
                                        Text(ollamaModel).tag(ollamaModel)
                                    }
                                } else {
                                    ForEach(ollamaModels, id: \.self) { Text($0).tag($0) }
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Button { Task { await loadOllamaModels() } } label: {
                                if isLoadingOllamaModels {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .help(L10n.refreshOllamaModels)
                            .disabled(isLoadingOllamaModels)
                        }
                    }
                }
            }

            if provider.requiresAPIKey {
                Section {
                HStack(spacing: 12) {
                    Button(L10n.saveAPIKey) {
                        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        AIKeychain.save(trimmedKey, account: provider.rawValue)
                        apiKey = trimmedKey
                        hasStoredKey = true
                        keyOperationStatus = .saved
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button(L10n.deleteAPIKey, role: .destructive) {
                        AIKeychain.delete(provider.rawValue)
                        apiKey = ""
                        hasStoredKey = false
                        keyOperationStatus = .deleted
                    }
                    .disabled(!hasStoredKey)
                    Spacer()
                }
                if keyOperationStatus == .saved {
                    Label(L10n.savedInKeychain, systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                } else if keyOperationStatus == .deleted {
                    Label(L10n.deletedFromKeychain, systemImage: "trash.fill")
                        .foregroundStyle(.secondary)
                }
                Text(L10n.apiKeyPrivacy).font(.caption).foregroundStyle(.secondary)
                }
            } else if provider == .ollama {
                Section {
                    Label(TextPolishService.ollamaEndpoint, systemImage: "desktopcomputer")
                        .foregroundStyle(.secondary)
                    if let ollamaError {
                        Text(ollamaError).font(.caption).foregroundStyle(.red)
                    } else {
                        Text(L10n.ollamaLocalPrivacy).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    Label(
                        TextPolishService.isAppleIntelligenceAvailable
                            ? L10n.appleIntelligenceReady
                            : L10n.appleIntelligenceUnavailable,
                        systemImage: TextPolishService.isAppleIntelligenceAvailable
                            ? "checkmark.circle.fill"
                            : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(TextPolishService.isAppleIntelligenceAvailable ? .green : .orange)
                    Text(L10n.appleIntelligencePrivacy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .onAppear {
            loadKey()
            if provider == .ollama { Task { await loadOllamaModels() } }
        }
        .onChange(of: providerValue) { _, _ in
            loadKey()
            if provider == .ollama { Task { await loadOllamaModels() } }
        }
    }

    private func settingsRow<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .frame(width: 145, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loadKey() {
        apiKey = AIKeychain.read(provider.rawValue)
        hasStoredKey = !apiKey.isEmpty
        keyOperationStatus = nil
    }

    @MainActor
    private func loadOllamaModels() async {
        isLoadingOllamaModels = true
        ollamaError = nil
        defer { isLoadingOllamaModels = false }
        do {
            ollamaModels = try await TextPolishService.fetchOllamaModels()
            if !ollamaModels.contains(ollamaModel) {
                ollamaModel = ollamaModels.first(where: { $0 == "qwen3:1.7b" })
                    ?? ollamaModels.first ?? ""
            }
        } catch {
            ollamaModels = []
            ollamaError = L10n.ollamaUnavailable
        }
    }
}
