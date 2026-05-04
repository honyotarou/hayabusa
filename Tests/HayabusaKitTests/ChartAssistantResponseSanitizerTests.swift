import XCTest
import HayabusaKit

final class ChartAssistantResponseSanitizerTests: XCTestCase {
    let ladderCase =
        "56歳男性昨日、脚立から落ちて腰を打ったために、今日になって腰と右足が痛くなってきました。右太ももの外側が痛み、足に力が入りません。"

    /// Models often insert blank lines after 【S】/【O】; legacy substring check missed this.
    func testEmptyPlaceholder_detectsWithBlankLinesBetweenMarkerAndMikisa() {
        let bad = """
        【S】

        未記載

        【O】

        未記載

        【P】
        内服：希望なし
        """
        XCTAssertTrue(ChartAssistantResponseSanitizer.isEmptyPlaceholderChart(bad))
    }

    func testEmptyPlaceholder_contiguousStillDetected() {
        let bad = """
        【S】
        未記載
        【O】
        未記載
        【P】
        内服：希望なし
        """
        XCTAssertTrue(ChartAssistantResponseSanitizer.isEmptyPlaceholderChart(bad))
    }

    func testEmptyPlaceholder_falseWhenSHasHistory() {
        let ok = """
        【S】
        56歳男性。腰痛。

        【O】
        未記載
        【P】
        内服：希望なし
        """
        XCTAssertFalse(ChartAssistantResponseSanitizer.isEmptyPlaceholderChart(ok))
    }

    func testSanitize_replacesEmptyPlaceholderWithUserHistoryInS() {
        let modelOut = """
        【S】

        未記載

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
        let out = ChartAssistantResponseSanitizer.sanitize(
            raw: modelOut,
            fallbackLastUserMessage: ladderCase
        )
        XCTAssertTrue(out.hasPrefix("S："), out)
        XCTAssertTrue(out.contains("56歳男性昨日、脚立から"), out)
        XCTAssertTrue(out.contains("\n\nO："), out)
        XCTAssertTrue(out.contains("\n\nA："), out)
        XCTAssertTrue(out.contains("\n\nP："), out)
        XCTAssertFalse(out.contains("\"age\""), out)
    }

    /// Model appends a role-play script first, then an empty SOAP stub (common with long system prompts).
    func testSanitize_dialogueBeforePlaceholderSOAP_keepsNarrativeInS() {
        let dialogue = """
        **医師**
        「昨日、脚立から落ちたとのことですね。どのくらいの高さから落ちましたか？」

        **患者**
        「2段か3段くらいです。腰からドンと落ちました。」

        **医師**
        「右足にしびれはありますか？感覚が鈍い感じはあります？」
        """
        let tail = """

        【S】
        未記載

        【O】
        未記載

        【P】
        内服：希望なし
        """
        let raw = dialogue + tail
        let out = ChartAssistantResponseSanitizer.sanitize(raw: raw, fallbackLastUserMessage: ladderCase)
        XCTAssertTrue(out.contains("脚立から落ちた"), out)
        XCTAssertTrue(out.contains("2段か3段"), out)
        XCTAssertTrue(out.hasPrefix("S："), out)
        XCTAssertFalse(out.contains("S：\n\n未記載"), out)
    }

    func testSanitize_passesIdealShortChartUnchanged() {
        let ideal = """
        S：56歳男性。昨日脚立より転落し腰部打撲。受傷翌日より腰痛増悪し、右大腿外側痛、右下肢脱力感あり。

        O：右大腿外側痛あり。右下肢脱力感あり。腰椎・骨盤XP予定。神経学的所見要評価。

        A：腰部打撲後。腰椎圧迫骨折、横突起骨折、外傷後腰椎神経根障害、椎間板ヘルニア、骨盤・股関節周囲損傷を鑑別。

        P：腰椎XP、骨盤XP。神経脱落所見あればMRI/CTまたは高次医療機関紹介検討。
        """
        let out = ChartAssistantResponseSanitizer.sanitize(raw: ideal, fallbackLastUserMessage: nil)
        XCTAssertEqual(out.trimmingCharacters(in: .whitespacesAndNewlines), ideal.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Trailing chart JSON must be stripped before the ASCII-heavy `looksLikeEnglishThinking` gate.
    func testSanitize_shortSOAPIgnoresTrailingJSONForEnglishHeuristic() {
        let raw = """
        S：a

        O：b

        A：c

        P：d

        {
          "age": "",
          "diagnoses": [""]
        }
        """
        let out = ChartAssistantResponseSanitizer.sanitize(raw: raw, fallbackLastUserMessage: nil)
        XCTAssertTrue(out.hasPrefix("S："), out)
        XCTAssertTrue(out.contains("P：d"), out)
        XCTAssertFalse(out.contains("\"age\""), out)
    }

    func testExtractDemographics() {
        let d = ChartAssistantResponseSanitizer.extractDemographics(from: ladderCase)
        XCTAssertEqual(d.age, "56")
        XCTAssertEqual(d.gender, "男性")
        let d2 = ChartAssistantResponseSanitizer.extractDemographics(from: "72歳女性、膝痛")
        XCTAssertEqual(d2.age, "72")
        XCTAssertEqual(d2.gender, "女性")
    }
}
