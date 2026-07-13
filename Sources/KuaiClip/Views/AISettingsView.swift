import SwiftUI

struct AISettingsView: View {
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
    @State private var saved = false
    @AppStorage("azureOpenAIEndpoint") private var azureEndpoint = ""
    @AppStorage("azureOpenAIDeployment") private var azureDeployment = ""
    @AppStorage("azureOpenAIAPIVersion") private var azureAPIVersion = "2024-10-21"

    private var theme: AppTheme { AppTheme(appearanceMode) }
    private var provider: Provider { Provider(rawValue: providerValue) ?? .openAI }

    var body: some View {
        Form {
            Section(L10n.aiProviders) {
                LabeledContent(L10n.aiProvider) {
                    Picker("", selection: $providerValue) {
                        ForEach(Provider.allCases) { provider in
                            Text(provider.title).tag(provider.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 220)
                }

                LabeledContent(L10n.apiKey) {
                    SecureField(provider.placeholder, text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                }

                if provider == .azureOpenAI {
                    LabeledContent(L10n.azureEndpoint) {
                        TextField("https://example.openai.azure.com", text: $azureEndpoint)
                            .textFieldStyle(.roundedBorder).frame(width: 300)
                    }
                    LabeledContent(L10n.azureDeployment) {
                        TextField("gpt-4o", text: $azureDeployment)
                            .textFieldStyle(.roundedBorder).frame(width: 300)
                    }
                    LabeledContent(L10n.azureAPIVersion) {
                        TextField("2024-10-21", text: $azureAPIVersion)
                            .textFieldStyle(.roundedBorder).frame(width: 300)
                    }
                }
            }

            Section {
                Button(L10n.saveAPIKey) {
                    AIKeychain.save(
                        apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                        account: provider.rawValue
                    )
                    saved = true
                }
                if saved {
                    Label(L10n.savedInKeychain, systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
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

    private func loadKey() {
        apiKey = AIKeychain.read(provider.rawValue)
        saved = false
    }
}
