import Foundation

/// Normalizes assistant chart output (SOAP + trailing JSON) and recovers when the model returns filler.
package enum ChartAssistantResponseSanitizer {
    package static func sanitize(raw: String, fallbackLastUserMessage: String?) -> String {
        var result = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        result = normalizeChartMarkers(result)

        if let soapStart = result.range(of: "【S】") {
            result = String(result[soapStart.lowerBound...])
            if containsBlockedThinkingText(result) || looksLikeEnglishThinking(result) || isEmptyPlaceholderChart(result) {
                return recoveredChartResponse(subject: fallbackLastUserMessage)
            }
        } else if containsBlockedThinkingText(result) || looksLikeEnglishThinking(result) {
            return recoveredChartResponse(subject: fallbackLastUserMessage)
        } else if !result.isEmpty {
            result = "【S】\n" + result
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Recovery

    package static func recoveredChartResponse(subject: String?) -> String {
        let subjectText = subject?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        let safeSubject = subjectText.flatMap { $0.isEmpty ? nil : $0 } ?? "未記載"
        let (age, gender) = extractDemographics(from: subjectText)

        let ageJson = age.map { "\"\($0)\"" } ?? "\"\""
        let genderJson = gender.map { "\"\($0)\"" } ?? "\"\""

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
          "age": \(ageJson),
          "gender": \(genderJson),
          "diagnoses": ["", "", "", "", "", ""],
          "rehab": false,
          "remarks": "なし"
        }
        """
    }

    package static func extractDemographics(from text: String?) -> (age: String?, gender: String?) {
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

    // MARK: - Detection

    package static func isEmptyPlaceholderChart(_ text: String) -> Bool {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        guard let sRange = normalized.range(of: "【S】") else { return false }
        let afterS = normalized[sRange.upperBound...]
        guard let oRange = afterS.range(of: "【O】") else { return false }
        let sBody = afterS[..<oRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let afterO = normalized[oRange.upperBound...]
        guard let pRange = afterO.range(of: "【P】") else { return false }
        let oBody = afterO[..<pRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sBody == "未記載" && oBody == "未記載"
    }

    package static func containsBlockedThinkingText(_ text: String) -> Bool {
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

    package static func normalizeChartMarkers(_ text: String) -> String {
        var result = text
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

    package static func looksLikeEnglishThinking(_ text: String) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 20 else { return false }
        let asciiLetters = letters.filter { $0.value < 128 }
        return Double(asciiLetters.count) / Double(letters.count) > 0.45
    }
}
