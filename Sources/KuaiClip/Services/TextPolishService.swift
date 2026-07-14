import Foundation

enum AIModel: String, CaseIterable, Identifiable {
    case openAIMini = "gpt-5.4-mini"
    case openAI = "gpt-5.4"
    case azureOpenAI = "Azure OpenAI"
    case geminiFlash = "gemini-3.5-flash"
    case deepSeekFlash = "deepseek-v4-flash"
    case deepSeekPro = "deepseek-v4-pro"

    var id: String { rawValue }
    var provider: String {
        if self == .azureOpenAI { return "Azure OpenAI" }
        if rawValue.hasPrefix("gemini") { return "Gemini" }
        if rawValue.hasPrefix("deepseek") { return "DeepSeek" }
        return "OpenAI"
    }
    var keyAccount: String { self == .azureOpenAI ? "azure-openai" : provider.lowercased() }
    var displayName: String { rawValue }
}

enum TextPolishError: LocalizedError {
    case missingKey, textTooLong(Int), invalidResponse(String)
    var errorDescription: String? {
        switch self {
        case .missingKey: return L10n.aiKeyMissing
        case .textTooLong(let limit): return L10n.polishTextTooLong(limit)
        case .invalidResponse(let message): return message
        }
    }
}

struct TextPolishService {
    static let maximumCharacterCount = 20_000

    static func availableModels() -> [AIModel] {
        AIModel.allCases.filter {
            guard !AIKeychain.read($0.keyAccount).isEmpty else { return false }
            if $0 == .azureOpenAI {
                return !azureSetting("azureOpenAIEndpoint").isEmpty
                    && !azureSetting("azureOpenAIDeployment").isEmpty
            }
            return true
        }
    }

    static func polish(_ text: String, using model: AIModel) async throws -> String {
        guard text.count <= maximumCharacterCount else {
            throw TextPolishError.textTooLong(maximumCharacterCount)
        }
        let key = AIKeychain.read(model.keyAccount)
        guard !key.isEmpty else { throw TextPolishError.missingKey }
        let prompt = """
        Polish the following email or workplace message. Automatically detect Chinese, English, or Japanese and keep the original language. Make it natural, concise, courteous, and professional. Preserve names, facts, dates, URLs, formatting, and intent. Do not translate. Return only the polished text without commentary or quotation marks.

        TEXT:
        \(text)
        """
        switch model.provider {
        case "Azure OpenAI": return try await callAzureOpenAI(prompt, key: key)
        case "OpenAI": return try await callOpenAI(prompt, model: model.rawValue, key: key)
        case "DeepSeek": return try await callDeepSeek(prompt, model: model.rawValue, key: key)
        default: return try await callGemini(prompt, model: model.rawValue, key: key)
        }
    }

    private static func callAzureOpenAI(_ input: String, key: String) async throws -> String {
        let endpoint = azureSetting("azureOpenAIEndpoint")
        let deployment = azureSetting("azureOpenAIDeployment")
        let url = try azureChatCompletionsURL(endpoint: endpoint, deployment: deployment)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": deployment,
            "messages": [["role": "user", "content": input]],
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        if let text = message?["content"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw TextPolishError.invalidResponse(L10n.aiInvalidResponse)
    }

    static func azureChatCompletionsURL(endpoint: String, deployment: String) throws -> URL {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !deployment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextPolishError.invalidResponse(L10n.azureConfigurationInvalid)
        }
        let base = trimmedEndpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = base.hasSuffix("/chat/completions") ? base : base + "/chat/completions"
        guard let components = URLComponents(string: urlString),
              let scheme = components.scheme, ["http", "https"].contains(scheme),
              components.host != nil,
              let url = components.url else {
            throw TextPolishError.invalidResponse(L10n.azureConfigurationInvalid)
        }
        return url
    }

    private static func azureSetting(_ key: String) -> String {
        UserDefaults.standard.string(forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func callOpenAI(_ input: String, model: String, key: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "input": input])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = json?["output_text"] as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let output = json?["output"] as? [[String: Any]] {
            let texts = output.flatMap { $0["content"] as? [[String: Any]] ?? [] }.compactMap { $0["text"] as? String }
            if !texts.isEmpty { return texts.joined().trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        throw TextPolishError.invalidResponse(L10n.aiInvalidResponse)
    }

    private static func callGemini(_ input: String, model: String, key: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/interactions")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "input": input, "store": false])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = json?["output_text"] as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        throw TextPolishError.invalidResponse(L10n.aiInvalidResponse)
    }

    private static func callDeepSeek(_ input: String, model: String, key: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": [["role": "user", "content": input]],
            "thinking": ["type": "disabled"],
            "stream": false,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        if let text = message?["content"] as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        throw TextPolishError.invalidResponse(L10n.aiInvalidResponse)
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let error = json?["error"] as? [String: Any]
            throw TextPolishError.invalidResponse(error?["message"] as? String ?? L10n.aiRequestFailed)
        }
    }
}
