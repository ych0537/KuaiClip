import SwiftUI

struct AISettingsView: View {
    private enum KeyOperationStatus {
        case saved, deleted
    }

    private enum Provider: String, CaseIterable, Identifiable {
        case openAI = "openai"
        case azureOpenAI = "azure-openai"
        case gemini
        case deepSeek = "deepseek"

        var id: String { rawValue }
        var title: String {
            switch self {
            case .openAI: return "OpenAI"
            case .azureOpenAI: return "Azure OpenAI"
            case .gemini: return "Gemini"
            case .deepSeek: return "DeepSeek"
            }
        }
        var placeholder: String {
            switch self {
            case .openAI: return "sk-proj-…"
            case .azureOpenAI: return L10n.azureAPIKeyPlaceholder
            case .gemini: return "AIza…"
            case .deepSeek: return "sk-…"
            }
        }
    }

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @AppStorage("aiSettingsProvider") private var providerValue = Provider.openAI.rawValue
    @State private var apiKey = ""
    @State private var hasStoredKey = false
    @State private var keyOperationStatus: KeyOperationStatus?
    @AppStorage("azureOpenAIEndpoint") private var azureEndpoint = ""
    @AppStorage("azureOpenAIDeployment") private var azureDeployment = ""

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

                settingsRow(L10n.apiKey) {
                    SecureField("", text: $apiKey, prompt: Text(provider.placeholder))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                }

                if provider == .azureOpenAI {
                    settingsRow(L10n.azureEndpoint) {
                        TextField(
                            "",
                            text: $azureEndpoint,
                            prompt: Text("https://example.openai.azure.com/openai/v1/")
                        )
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                    }
                    settingsRow(L10n.azureDeployment) {
                        TextField("", text: $azureDeployment, prompt: Text("gpt-4o"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

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
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .onAppear { loadKey() }
        .onChange(of: providerValue) { _, _ in loadKey() }
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
}
