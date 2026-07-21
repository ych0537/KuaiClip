import Foundation
import FoundationModels

enum AIModel: String, CaseIterable, Identifiable {
    case appleIntelligence = "Apple Intelligence"
    case openAIMini = "gpt-5.4-mini"
    case openAI = "gpt-5.4"
    case geminiFlash = "gemini-3.5-flash"
    case deepSeekFlash = "deepseek-v4-flash"
    case deepSeekPro = "deepseek-v4-pro"
    case ollama = "Ollama"

    var id: String { rawValue }
    var provider: String {
        if self == .appleIntelligence { return "Apple Intelligence" }
        if self == .ollama { return "Ollama" }
        if rawValue.hasPrefix("gemini") { return "Gemini" }
        if rawValue.hasPrefix("deepseek") { return "DeepSeek" }
        return "OpenAI"
    }
    var keyAccount: String { provider.lowercased() }
    var displayName: String {
        if self == .ollama {
            return UserDefaults.standard.string(forKey: "ollamaModel") ?? rawValue
        }
        return rawValue
    }
}

enum TextPolishError: LocalizedError {
    case missingKey, appleIntelligenceUnavailable, textTooLong(Int), invalidResponse(String)
    var errorDescription: String? {
        switch self {
        case .missingKey: return L10n.aiKeyMissing
        case .appleIntelligenceUnavailable: return L10n.appleIntelligenceUnavailable
        case .textTooLong(let limit): return L10n.polishTextTooLong(limit)
        case .invalidResponse(let message): return message
        }
    }
}

struct TextPolishService {
    static let maximumCharacterCount = 20_000
    static let ollamaEndpoint = "http://127.0.0.1:11434"

    static func availableModels() -> [AIModel] {
        AIModel.allCases.filter {
            if $0 == .appleIntelligence {
                return isAppleIntelligenceAvailable
            }
            if $0 == .ollama {
                return !(UserDefaults.standard.string(forKey: "ollamaModel") ?? "").isEmpty
            }
            guard !AIKeychain.read($0.keyAccount).isEmpty else { return false }
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
        if model == .appleIntelligence {
            if #available(macOS 26.0, *) {
                return try await callAppleIntelligence(text)
            }
            throw TextPolishError.appleIntelligenceUnavailable
        }
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
        case "OpenAI": return try await callOpenAI(prompt, model: model.rawValue, key: key)
        case "DeepSeek": return try await callDeepSeek(prompt, model: model.rawValue, key: key)
        default: return try await callGemini(prompt, model: model.rawValue, key: key)
        }
    }

    static var isAppleIntelligenceAvailable: Bool {
        if #available(macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    @available(macOS 26.0, *)
    private static func callAppleIntelligence(_ input: String) async throws -> String {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw TextPolishError.appleIntelligenceUnavailable
        }
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are a professional copy editor for Chinese, English, and Japanese workplace writing.
            Rewrite the user's text so it is natural, concise, courteous, and professional.
            Always respond in the same language as the user's text. Never translate it.
            Preserve names, facts, dates, URLs, formatting, and intent.
            Return only the polished text without commentary or quotation marks.
            """
        )
        do {
            let response = try await session.respond(to: input)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw TextPolishError.invalidResponse(error.localizedDescription)
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
