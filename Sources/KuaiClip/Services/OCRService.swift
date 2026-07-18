import Foundation
import Vision

enum OCRService {
    enum Error: LocalizedError {
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return L10n.ocrNoText
            }
        }
    }

    static func recognizeText(in imageData: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(data: imageData, options: [:])
            try handler.perform([request])

            let text = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else { throw Error.noTextFound }
            return text
        }.value
    }
}
