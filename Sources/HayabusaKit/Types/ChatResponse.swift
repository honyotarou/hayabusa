import Foundation

struct ChatResponse: Encodable, Sendable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage

    struct Choice: Encodable, Sendable {
        let index: Int
        let message: ResponseMessage
        let finish_reason: String
    }

    struct ResponseMessage: Encodable, Sendable {
        let role: String
        let content: String
    }

    struct Usage: Encodable, Sendable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }

    init(
        id: String,
        model: String,
        content: String,
        promptTokens: Int,
        completionTokens: Int,
        fallbackSubject: String? = nil
    ) {
        self.id = id
        self.object = "chat.completion"
        self.created = Int(Date().timeIntervalSince1970)
        self.model = model
        let sanitizedContent = content.sanitizedChartResponse(fallbackSubject: fallbackSubject)
        self.choices = [
            Choice(
                index: 0,
                message: ResponseMessage(role: "assistant", content: sanitizedContent),
                finish_reason: "stop"
            )
        ]
        self.usage = Usage(
            prompt_tokens: promptTokens,
            completion_tokens: completionTokens,
            total_tokens: promptTokens + completionTokens
        )
    }
}

private extension String {
    func sanitizedChartResponse(fallbackSubject: String?) -> String {
        var result = self.trimmingCharacters(in: .whitespacesAndNewlines)

        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        result = result.normalizedChartMarkers

        if let soapStart = result.range(of: "【S】") {
            result = String(result[soapStart.lowerBound...])
            if result.containsBlockedThinkingText || result.looksLikeEnglishThinking || result.isEmptyPlaceholderChart {
                return Self.recoveredChartResponse(subject: fallbackSubject)
            }
        } else if result.containsBlockedThinkingText || result.looksLikeEnglishThinking {
            return Self.recoveredChartResponse(subject: fallbackSubject)
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
            "Diagnosis Formulation",
            "Treatment:",
            "Here's a thinking process",
            "Analyze the Request",
            "Drafting the Response",
            "Self-Correction",
            "Constraint Check",
            "Output Rules",
            "Specific rules"
        ]
        return markers.contains { self.localizedCaseInsensitiveContains($0) }
    }

    var normalizedChartMarkers: String {
        var result = self
        let replacements = [
            "[S]": "【S】",
            "[Ｏ]": "【O】",
            "[O]": "【O】",
            "[Ｐ]": "【P】",
            "[P]": "【P】"
        ]
        for (source, target) in replacements {
            result = result.replacingOccurrences(of: source, with: target)
        }
        return result
    }

    var isEmptyPlaceholderChart: Bool {
        let compact = self
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return compact.contains("【S】\n未記載")
            && compact.contains("【O】\n未記載")
    }

    var looksLikeEnglishThinking: Bool {
        let letters = self.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 20 else { return false }
        let asciiLetters = letters.filter { $0.value < 128 }
        return Double(asciiLetters.count) / Double(letters.count) > 0.45
    }

    static func recoveredChartResponse(subject: String?) -> String {
        let subjectText = subject?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        let safeSubject = subjectText?.isEmpty == false ? subjectText! : "未記載"

        return """
        【S】
        \(safeSubject)

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
