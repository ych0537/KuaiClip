import Foundation

enum AIModel: String, CaseIterable, Identifiable {
    case openAIMini = "gpt-5.4-mini"
    case openAI = "gpt-5.4"
    case azureOpenAI = "Azure OpenAI"
    case geminiFlash = "gemini-3.5-flash"
    case deepSeekFlash = "deepseek-v4-flash"
    case deepSeekPro = "deepseek-v4-pro"
    case ollama = "Ollama"

    var id: String { rawValue }
    var provider: String {
        if self == .azureOpenAI { return "Azure OpenAI" }
        if self == .ollama { return "Ollama" }
        if rawValue.hasPrefix("gemini") { return "Gemini" }
        if rawValue.hasPrefix("deepseek") { return "DeepSeek" }
        return "OpenAI"
    }
    var keyAccount: String { self == .azureOpenAI ? "azure-openai" : provider.lowercased() }
    var displayName: String {
        if self == .ollama {
            return UserDefaults.standard.string(forKey: "ollamaModel") ?? rawValue
        }
        return rawValue
    }
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
    static let ollamaEndpoint = "http://127.0.0.1:11434"

    struct CodexAzureConfiguration: Equatable {
        let baseURL: String
        let model: String
    }

    static func availableModels() -> [AIModel] {
        AIModel.allCases.filter {
            if $0 == .ollama {
                return !(UserDefaults.standard.string(forKey: "ollamaModel") ?? "").isEmpty
            }
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
        let prompt = """
        Polish the following email or workplace message. Automatically detect Chinese, English, or Japanese and keep the original language. Make it natural, concise, courteous, and professional. Preserve names, facts, dates, URLs, formatting, and intent. Do not translate. Return only the polished text without commentary or quotation marks.

        TEXT:
        \(text)
        """
        if model == .ollama {
            let ollamaModel = UserDefaults.standard.string(forKey: "ollamaModel") ?? ""
            guard !ollamaModel.isEmpty else {
                throw TextPolishError.invalidResponse(L10n.noOllamaModels)
            }
            return try await callOllama(prompt, model: ollamaModel)
        }
        let key = AIKeychain.read(model.keyAccount)
        guard !key.isEmpty else { throw TextPolishError.missingKey }
        switch model.provider {
        case "Azure OpenAI": return try await callAzureOpenAI(prompt, key: key)
        case "OpenAI": return try await callOpenAI(prompt, model: model.rawValue, key: key)
        case "DeepSeek": return try await callDeepSeek(prompt, model: model.rawValue, key: key)
        default: return try await callGemini(prompt, model: model.rawValue, key: key)
        }
    }

    static func fetchOllamaModels() async throws -> [String] {
        let url = URL(string: ollamaEndpoint + "/api/tags")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let models = json?["models"] as? [[String: Any]] ?? []
        return models.compactMap { ($0["name"] as? String) ?? ($0["model"] as? String) }
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func ollamaRequestBody(_ input: String, model: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": [["role": "user", "content": input]],
            "think": false,
            "stream": false,
        ])
    }

    private static func callOllama(_ input: String, model: String) async throws -> String {
        var request = URLRequest(url: URL(string: ollamaEndpoint + "/api/chat")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try ollamaRequestBody(input, model: model)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let message = json?["message"] as? [String: Any]
        if let text = message?["content"] as? String, !text.isEmpty {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw TextPolishError.invalidResponse(L10n.aiInvalidResponse)
    }

    private static func callAzureOpenAI(_ input: String, key: String) async throws -> String {
        let endpoint = azureSetting("azureOpenAIEndpoint")
        let deployment = azureSetting("azureOpenAIDeployment")
        return try await callAzureResponses(input, key: key, endpoint: endpoint, model: deployment)
    }

    private static func callAzureResponses(
        _ input: String,
        key: String,
        endpoint: String,
        model: String
    ) async throws -> String {
        let base = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !model.isEmpty, let url = URL(string: base + "/responses") else {
            throw TextPolishError.invalidResponse(L10n.azureConfigurationInvalid)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "input": input,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        return try responseText(from: data)
    }

    static func codexAzureConfiguration() -> CodexAzureConfiguration? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return parseCodexAzureConfiguration(contents)
    }

    static func parseCodexAzureConfiguration(_ contents: String) -> CodexAzureConfiguration? {
        var currentSection: String?
        var values: [String: String] = [:]

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                currentSection = line
                continue
            }
            guard !line.hasPrefix("#"),
                  let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            let isTopLevelModel = currentSection == nil && key == "model"
            let isAzureProviderValue = currentSection == "[model_providers.azure]"
                && key == "base_url"
            guard isTopLevelModel || isAzureProviderValue else { continue }
            var value = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespaces)
            if let comment = value.firstIndex(of: "#") {
                value = value[..<comment].trimmingCharacters(in: .whitespaces)
            }
            if value.count >= 2, value.first == "\"", value.last == "\"" {
                value.removeFirst()
                value.removeLast()
            }
            values[key] = value
        }

        let baseURL = values["base_url"] ?? ""
        let model = values["model"] ?? ""
        guard !baseURL.isEmpty || !model.isEmpty else { return nil }
        return CodexAzureConfiguration(baseURL: baseURL, model: model)
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
        return try responseText(from: data)
    }

    private static func responseText(from data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = json?["output_text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let output = json?["output"] as? [[String: Any]] {
            let texts = output.flatMap { $0["content"] as? [[String: Any]] ?? [] }
                .compactMap { $0["text"] as? String }
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
            let message = error?["message"] as? String ?? json?["error"] as? String
            throw TextPolishError.invalidResponse(message ?? L10n.aiRequestFailed)
        }
    }
}
