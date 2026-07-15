import Foundation

enum PolishableTextClassifier {
    private static let shellCommands: Set<String> = [
        "alias", "aws", "brew", "cat", "cd", "chmod", "chown", "cp", "curl",
        "docker", "echo", "env", "find", "git", "grep", "head", "kubectl", "ls",
        "mkdir", "mv", "npm", "npx", "open", "pip", "python", "rm", "rsync",
        "sed", "ssh", "sudo", "swift", "tail", "tar", "touch", "wget", "yarn"
    ]

    static func shouldOfferPolish(for source: String) -> Bool {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              !isURLLike(text),
              !isAddressLike(text),
              !isPathLike(text),
              !isStructuredData(text),
              !isShellCommand(text),
              !isLikelyIdentifierOrSecret(text)
        else { return false }

        let scalars = text.unicodeScalars
        let cjkCount = scalars.filter { scalar in
            (0x3040...0x30ff).contains(scalar.value) ||
            (0x3400...0x4dbf).contains(scalar.value) ||
            (0x4e00...0x9fff).contains(scalar.value)
        }.count
        if cjkCount >= 8 { return true }

        let englishWords = text.split { !$0.isLetter }.filter {
            $0.unicodeScalars.allSatisfy { $0.value < 128 }
        }
        let englishLetterCount = englishWords.reduce(0) { $0 + $1.count }
        guard englishWords.count >= 4, englishLetterCount >= 20 else { return false }

        let naturalCharacters = scalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.whitespacesAndNewlines.contains($0) ||
            CharacterSet.punctuationCharacters.contains($0)
        }.count
        return Double(naturalCharacters) / Double(max(scalars.count, 1)) >= 0.65
    }

    private static func isURLLike(_ text: String) -> Bool {
        text.range(of: #"^(?:https?|ftp)://\S+$"#, options: [.regularExpression, .caseInsensitive]) != nil ||
        text.range(of: #"^(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)+(?:/\S*)?$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func isAddressLike(_ text: String) -> Bool {
        text.range(of: #"^(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?$"#, options: .regularExpression) != nil ||
        text.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    private static func isPathLike(_ text: String) -> Bool {
        text.hasPrefix("/") || text.hasPrefix("~/") || text.hasPrefix("./") ||
        text.hasPrefix("../") ||
        text.range(of: #"^[A-Za-z]:\\"#, options: .regularExpression) != nil
    }

    private static func isStructuredData(_ text: String) -> Bool {
        if let data = text.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil {
            return true
        }
        return text.range(of: #"(?m)^\s*(?:<[^>]+>|---\s*$)"#, options: .regularExpression) != nil
    }

    private static func isShellCommand(_ text: String) -> Bool {
        let firstToken = text.split(whereSeparator: \Character.isWhitespace).first.map(String.init)?.lowercased() ?? ""
        if shellCommands.contains(firstToken) { return true }
        return text.range(of: #"(?:^|\s)(?:--?[A-Za-z][\w-]*|&&|\|\||[|<>]|\$\(|`[^`]+`)"#, options: .regularExpression) != nil
    }

    private static func isLikelyIdentifierOrSecret(_ text: String) -> Bool {
        guard !text.contains(where: \Character.isWhitespace) else { return false }
        if text.allSatisfy(\.isNumber) { return true }
        guard text.count >= 12 else { return false }
        let scalars = text.unicodeScalars
        guard scalars.allSatisfy({ $0.value < 128 }) else { return false }
        let identifierCharacters = scalars.filter {
            CharacterSet.alphanumerics.contains($0) || "_-.:/+=@".unicodeScalars.contains($0)
        }.count
        return Double(identifierCharacters) / Double(max(scalars.count, 1)) >= 0.9
    }
}
