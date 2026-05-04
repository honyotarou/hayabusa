import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

struct ChatRequest: Codable {
    let messages: [[String: String]]
    let model: String?
    let max_tokens: Int?
    let temperature: Double?
    let priority: String?
}

struct ChatResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Decodable {
        let index: Int
        let message: Message
        let finish_reason: String?
    }

    struct Message: Decodable {
        let role: String
        let content: String
    }

    struct Usage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }

    var text: String {
        (choices.first?.message.content ?? "").sanitizedChartResponse
    }
}

private extension String {
    var sanitizedChartResponse: String {
        var result = self.trimmingCharacters(in: .whitespacesAndNewlines)

        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let soapStart = result.range(of: "【S】") {
            result = String(result[soapStart.lowerBound...])
            if result.containsBlockedThinkingText || result.looksLikeEnglishThinking {
                return Self.fallbackChartResponse
            }
        } else if result.containsBlockedThinkingText || result.looksLikeEnglishThinking {
            return Self.fallbackChartResponse
        } else if !result.isEmpty {
            result = "【S】\n" + result
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var containsBlockedThinkingText: Bool {
        let markers = [
            "No text before",
            "thinking process",
            "English explanations",
            "Output format",
            "Diagnosis logic",
            "Input Analysis",
            "Input Analysis:",
            "Diagnosis Formulation:",
            "Treatment:",
            "Here's a thinking process",
            "Analyze the Request",
            "Drafting the Response",
            "Self-Correction",
            "Constraint Check",
            "Output Rules:",
            "Specific rules"
        ]
        return markers.contains { self.localizedCaseInsensitiveContains($0) }
    }

    var looksLikeEnglishThinking: Bool {
        let letters = self.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 20 else { return false }
        let asciiLetters = letters.filter { $0.value < 128 }
        return Double(asciiLetters.count) / Double(letters.count) > 0.45
    }

    static var fallbackChartResponse: String {
        """
        【S】
        出力形式が崩れたため、再生成が必要です。

        【O】
        未記載

        【P】
        内服：希望なし
        外用：希望なし
        リハビリ介入：希望なし
        来週再診：希望なし

        {
          "age": "",
          "gender": "",
          "diagnoses": ["", "", "", "", "", ""],
          "rehab": false,
          "remarks": "なし"
        }
        """
    }
}
