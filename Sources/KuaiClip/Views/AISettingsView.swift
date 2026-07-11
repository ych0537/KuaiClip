import SwiftUI

struct AISettingsView: View {
    private enum Provider: String, CaseIterable, Identifiable {
        case openAI = "openai"
        case gemini
        case deepSeek = "deepseek"

        var id: String { rawValue }
        var title: String {
            switch self {
            case .openAI: return "OpenAI"
            case .gemini: return "Gemini"
            case .deepSeek: return "DeepSeek"
            }
        }
        var placeholder: String {
            switch self {
            case .openAI: return "sk-proj-…"
            case .gemini: return "AIza…"
            case .deepSeek: return "sk-…"
            }
        }
    }

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @AppStorage("aiSettingsProvider") private var providerValue = Provider.openAI.rawValue
    @State private var apiKey = ""
    @State private var saved = false

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
