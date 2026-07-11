import SwiftUI

struct AISettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    @State private var deepSeekKey = ""
    @State private var saved = false

    private var theme: AppTheme { AppTheme(appearanceMode) }

    var body: some View {
        Form {
            Section(L10n.aiProviders) {
                keyRow("OpenAI", key: $openAIKey, placeholder: "sk-…")
                keyRow("Gemini", key: $geminiKey, placeholder: "AIza…")
                keyRow("DeepSeek", key: $deepSeekKey, placeholder: "sk-…")
            }
            Section {
                Button(L10n.saveAPIKeys) {
                    AIKeychain.save(openAIKey.trimmingCharacters(in: .whitespacesAndNewlines), account: "openai")
                    AIKeychain.save(geminiKey.trimmingCharacters(in: .whitespacesAndNewlines), account: "gemini")
                    AIKeychain.save(deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines), account: "deepseek")
                    saved = true
                }
                if saved { Label(L10n.savedInKeychain, systemImage: "checkmark.shield.fill").foregroundStyle(.green) }
                Text(L10n.apiKeyPrivacy).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped).scrollContentBackground(.hidden).background(theme.background)
        .onAppear {
            openAIKey = AIKeychain.read("openai")
            geminiKey = AIKeychain.read("gemini")
            deepSeekKey = AIKeychain.read("deepseek")
        }
    }

    private func keyRow(_ provider: String, key: Binding<String>, placeholder: String) -> some View {
        LabeledContent(provider) {
            SecureField(placeholder, text: key).textFieldStyle(.roundedBorder).frame(width: 300)
        }
    }
}
