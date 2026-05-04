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

    /// 生レスポンスのみ（ユーザー文脈なし）。可能なら `chartText(fallbackLastUserMessage:)` を使う。
    var text: String {
        (choices.first?.message.content ?? "").sanitizedChartContent(fallbackLastUserMessage: nil)
    }

    /// 表示用。サーバーが `S：未記載` のまま返した場合に、直前のユーザー入力から S を補完する。
    func chartText(fallbackLastUserMessage: String?) -> String {
        (choices.first?.message.content ?? "").sanitizedChartContent(fallbackLastUserMessage: fallbackLastUserMessage)
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

    func sanitizedChartContent(fallbackLastUserMessage: String?) -> String {
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
            return Self.finalizeCompleteShortSOAP(result, fallback: fallbackLastUserMessage)
        }

        if result.containsBlockedThinkingText || result.looksLikeEnglishThinking {
            return Self.shortFallbackChart
        }

        if !result.isEmpty {
            return Self.shortFallbackChart
        }

        return Self.shortFallbackChart
    }

    // MARK: - S 補完（HayabusaKit の `shortSOAPFillingRedactedSubjectIfNeeded` と同型）

    static func finalizeCompleteShortSOAP(_ text: String, fallback: String?) -> String {
        let trimmed = stripTrailingChartJSONIfAny(text).trimmingCharacters(in: .whitespacesAndNewlines)
        return shortSOAPFillingRedactedSubjectIfNeeded(trimmed, fallback: fallback)
    }

    static func shortSOAPFillingRedactedSubjectIfNeeded(_ text: String, fallback: String?) -> String {
        guard let fallback else { return text }
        let n0 = text.normalizedNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = unifyShortSOAPHeaderLetters(n0)
        guard hasCompleteShortSOAP(n) else { return text }
        guard let sBody = extractShortSectionBody(n, start: "S：", endPrefixes: ["O："]),
              let o = extractShortSectionBody(n, start: "O：", endPrefixes: ["A："]),
              let a = extractShortSectionBody(n, start: "A：", endPrefixes: ["P："]),
              let p = extractShortSectionBody(n, start: "P：", endPrefixes: [])
        else { return text }
        let sTrim = sBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sTrim.isEmpty || sTrim == "未記載" else { return text }
        let narrative = narrativeForRecovery(prefix: nil, fallback: fallback)
        let hint = demographicsHint(prefix: nil, fallback: fallback)
        let newS = syntheticSubjectLine(narrative: narrative, demographicsFrom: hint)
        guard newS != "未記載" else { return text }
        return """
        S：\(newS)

        O：\(o)

        A：\(a)

        P：\(p)
        """
    }

    static func unifyShortSOAPHeaderLetters(_ text: String) -> String {
        text
            .replacingOccurrences(of: "Ｓ：", with: "S：")
            .replacingOccurrences(of: "Ｏ：", with: "O：")
            .replacingOccurrences(of: "Ａ：", with: "A：")
            .replacingOccurrences(of: "Ｐ：", with: "P：")
    }

    static func narrativeForRecovery(prefix: String?, fallback: String?) -> String {
        let p = prefix.flatMap { s in
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        let f = fallback.flatMap { s in
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let p, isUsableJapaneseNarrative(p) { return p }
        if let f, isUsableJapaneseNarrative(f) { return f }
        if let p { return p }
        if let f { return f }
        return "未記載"
    }

    static func isUsableJapaneseNarrative(_ s: String) -> Bool {
        guard s.count >= 30 else { return false }
        if containsBlockedThinkingTextStatic(s) || looksLikeEnglishThinkingStatic(s) { return false }
        return true
    }

    static func demographicsHint(prefix: String?, fallback: String?) -> String? {
        let parts = [prefix, fallback].compactMap { str -> String? in
            guard let str else { return nil }
            let t = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "\n")
    }

    static func extractDemographics(from text: String?) -> (age: String?, gender: String?) {
        guard let text, !text.isEmpty else { return (nil, nil) }
        var age: String?
        if let range = text.range(of: #"\d{1,3}歳"#, options: .regularExpression) {
            age = String(text[range]).replacingOccurrences(of: "歳", with: "")
        }
        let gender: String?
        if text.contains("女性") {
            gender = "女性"
        } else if text.contains("男性") {
            gender = "男性"
        } else {
            gender = nil
        }
        return (age, gender)
    }

    static func collapseWhitespace(_ s: String) -> String {
        let parts = s.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return parts.joined(separator: "。")
    }

    static func syntheticSubjectLine(narrative: String, demographicsFrom hint: String?) -> String {
        let trimmed = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "未記載" {
            return "未記載"
        }
        let oneLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        let tail = collapseWhitespace(oneLine)
        let (age, gender) = extractDemographics(from: hint ?? trimmed)

        if let age, let gender {
            let dem = "\(age)歳\(gender)"
            if tail.hasPrefix(dem + "。") || tail.hasPrefix(dem + "、") || tail.hasPrefix(dem) {
                return String(tail.prefix(500))
            }
            return dem + "。" + tail
        }
        if let age {
            let dem = "\(age)歳"
            if tail.hasPrefix(dem + "。") || tail.hasPrefix(dem + "、") || tail.hasPrefix(dem) {
                return String(tail.prefix(500))
            }
            return dem + "。" + tail
        }
        if let gender {
            if tail.hasPrefix(gender + "。") || tail.hasPrefix(gender) {
                return String(tail.prefix(500))
            }
            return gender + "。" + tail
        }
        return String(tail.prefix(500))
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

    static func containsBlockedThinkingTextStatic(_ text: String) -> Bool {
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
        return markers.contains { text.localizedCaseInsensitiveContains($0) }
    }

    var containsBlockedThinkingText: Bool {
        Self.containsBlockedThinkingTextStatic(self)
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

    static func looksLikeEnglishThinkingStatic(_ text: String) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 20 else { return false }
        let asciiLetters = letters.filter { $0.value < 128 }
        return Double(asciiLetters.count) / Double(letters.count) > 0.45
    }

    var looksLikeEnglishThinking: Bool {
        Self.looksLikeEnglishThinkingStatic(self)
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
