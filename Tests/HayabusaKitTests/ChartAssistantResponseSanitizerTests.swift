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
        XCTAssertTrue(out.contains("【S】"), out)
        XCTAssertTrue(out.contains(ladderCase), out)
        XCTAssertFalse(out.contains("【S】\n未記載"), out)
        XCTAssertTrue(out.contains("\"age\": \"56\""), out)
        XCTAssertTrue(out.contains("\"gender\": \"男性\""), out)
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
