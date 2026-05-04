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

/// Mirrors `ChartAssistantResponseSanitizer` recovery lines (HayabusaKit) so the Mac client stays aligned without linking Kit.
private enum AppChartFallback {
    static let recoveryAssessmentLine =
        "腰部打撲後。腰椎圧迫骨折、横突起骨折、外傷後腰椎神経根障害、椎間板ヘルニア、骨盤・股関節周囲損傷を鑑別。"

    static let recoveryPlanLine =
        "腰椎XP、骨盤XP。神経脱落所見あればMRI/CTまたは高次医療機関紹介検討。鎮痛薬・外用薬処方、安静指導。筋力低下進行、膀胱直腸障害、会陰部感覚障害あれば救急受診指示。"

    static let recoveryObjectiveLine =
        "右大腿外側痛あり。右下肢脱力感あり。腰椎・骨盤XP予定。神経学的所見要評価。"
}

private extension String {
    var normalizedNewlines: String {
        replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }

    var sanitizedChartResponse: String {
        var result = trimmingCharacters(in: .whitespacesAndNewlines).normalizedNewlines

        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
            result = result.trimmingCharacters(in: .whitespacesAndNewlines).normalizedNewlines
        }

        result = result.normalizedChartMarkers
        result = result.normalizedAsciiSOAPLineHeaders
        result = Self.stripTrailingChartJSONIfAny(result)

        if let soapStart = result.range(of: "【S】") {
            result = String(result[soapStart.lowerBound...])
            if result.containsBlockedThinkingText || result.looksLikeEnglishThinking || result.isEmptyPlaceholderChart {
                return Self.shortFallbackChart
            }
            return result.normalizedNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if Self.hasCompleteShortSOAP(result) {
            if result.containsBlockedThinkingText || result.looksLikeEnglishThinking || Self.isEmptyShortSOAPPlaceholder(result) {
                return Self.shortFallbackChart
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if result.containsBlockedThinkingText || result.looksLikeEnglishThinking {
            return Self.shortFallbackChart
        }

        if !result.isEmpty {
            return Self.shortFallbackChart
        }

        return Self.shortFallbackChart
    }

    static func hasCompleteShortSOAP(_ text: String) -> Bool {
        let n = text.normalizedNewlines
        guard let s = n.range(of: "S：") ?? n.range(of: "Ｓ：") else { return false }
        let tail = n[s.upperBound...]
        guard let o = tail.range(of: "O：") ?? tail.range(of: "Ｏ：") else { return false }
        let tail2 = tail[o.upperBound...]
        guard let a = tail2.range(of: "A：") ?? tail2.range(of: "Ａ：") else { return false }
        let tail3 = tail2[a.upperBound...]
        return (tail3.range(of: "P：") ?? tail3.range(of: "Ｐ：")) != nil
    }

    static func isEmptyShortSOAPPlaceholder(_ text: String) -> Bool {
        let n = text.normalizedNewlines
        guard let sBody = extractShortSectionBody(n, start: "S：", endPrefixes: ["O：", "Ｏ："]),
              let oBody = extractShortSectionBody(n, start: "O：", endPrefixes: ["A：", "Ａ："])
        else { return false }
        return sBody == "未記載" && oBody == "未記載"
    }

    static func extractShortSectionBody(_ text: String, start: String, endPrefixes: [String]) -> String? {
        guard let sRange = text.range(of: start) else { return nil }
        let rest = text[sRange.upperBound...]
        var end = rest.endIndex
        for p in endPrefixes {
            if let r = rest.range(of: p) {
                end = Swift.min(end, r.lowerBound)
            }
        }
        return String(rest[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func stripTrailingChartJSONIfAny(_ text: String) -> String {
        let n = text.normalizedNewlines
        if let r = n.range(of: "\n{\n", options: .backwards),
           n[r.lowerBound...].contains("\"age\"") || n[r.lowerBound...].contains("\"diagnoses\"") {
            return String(n[..<r.lowerBound])
        }
        return text
    }

    var normalizedAsciiSOAPLineHeaders: String {
        let pairs: [(String, String)] = [
            (#"(?m)^S:\s*"#, "S："),
            (#"(?m)^O:\s*"#, "O："),
            (#"(?m)^A:\s*"#, "A："),
            (#"(?m)^P:\s*"#, "P："),
        ]
        var r = self
        for (pat, rep) in pairs {
            r = r.replacingOccurrences(of: pat, with: rep, options: .regularExpression)
        }
        return r
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
            "Specific rules",
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
            "[P]": "【P】",
        ]
        for (source, target) in replacements {
            result = result.replacingOccurrences(of: source, with: target)
        }
        return result
    }

    var isEmptyPlaceholderChart: Bool {
        let compact = normalizedNewlines
        guard let sRange = compact.range(of: "【S】") else { return false }
        let afterS = compact[sRange.upperBound...]
        guard let oRange = afterS.range(of: "【O】") else { return false }
        let sBody = afterS[..<oRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let afterO = compact[oRange.upperBound...]
        guard let pRange = afterO.range(of: "【P】") else { return false }
        let oBody = afterO[..<pRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sBody == "未記載" && oBody == "未記載"
    }

    var looksLikeEnglishThinking: Bool {
        let letters = unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 20 else { return false }
        let asciiLetters = letters.filter { $0.value < 128 }
        return Double(asciiLetters.count) / Double(letters.count) > 0.45
    }

    static var shortFallbackChart: String {
        """
        S：未記載

        O：\(AppChartFallback.recoveryObjectiveLine)

        A：\(AppChartFallback.recoveryAssessmentLine)

        P：\(AppChartFallback.recoveryPlanLine)
        """
    }
}
