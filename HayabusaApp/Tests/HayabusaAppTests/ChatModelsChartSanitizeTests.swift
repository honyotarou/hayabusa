import Foundation
import XCTest

@testable import HayabusaApp

final class ChatModelsChartSanitizeTests: XCTestCase {
    func testChatResponseText_passesThroughShortSOAPWithoutBracketPrefix() throws {
        let ideal = """
        S：56歳男性。昨日脚立より転落し腰部打撲。

        O：右大腿外側痛あり。

        A：腰部打撲後。鑑別。

        P：腰椎XP。
        """
        let response = try decodeChatResponse(content: ideal)
        XCTAssertTrue(response.text.hasPrefix("S："), response.text)
        XCTAssertFalse(response.text.contains("【S】"), response.text)
    }

    func testChatResponseText_normalizesAsciiSOAPColons() throws {
        let raw = """
        S: 56歳男性。テスト。

        O: 所見。

        A: 鑑別。

        P: 計画。
        """
        let response = try decodeChatResponse(content: raw)
        XCTAssertTrue(response.text.contains("S：56歳男性"), response.text)
        XCTAssertTrue(response.text.contains("O：所見"), response.text)
    }

    func testChatResponseText_stripsTrailingJSONBlock() throws {
        let withJSON = """
        S：a

        O：b

        A：c

        P：d

        {
          "age": "",
          "diagnoses": [""]
        }
        """
        let response = try decodeChatResponse(content: withJSON)
        XCTAssertFalse(response.text.contains("\"age\""), response.text)
        XCTAssertTrue(response.text.contains("P：d"), response.text)
    }

    func testChatResponseText_fallsBackToShortSOAPWhenOnlyNoise() throws {
        let response = try decodeChatResponse(content: "Input Analysis: foo bar baz extra english")
        XCTAssertTrue(response.text.hasPrefix("S：未記載"), response.text)
        XCTAssertTrue(response.text.contains("P："), response.text)
        XCTAssertFalse(response.text.contains("【S】"), response.text)
    }

    func testChartText_fillsSubjectWhenSMikisaUsingUserFallback() throws {
        let raw = """
        S：未記載

        O：右大腿外側痛あり。右下肢脱力感あり。腰椎・骨盤XP予定。神経学的所見は要評価。

        A：腰部打撲後。腰椎圧迫骨折、横突起骨折、外傷後腰椎神経根障害、椎間板ヘルニア、骨盤・股関節周囲損傷を鑑別。

        P：腰椎XP、骨盤XP。神経脱落所見あればMRI/CTまたは高次医療機関紹介検討。鎮痛薬・外用薬処方、安静指導。筋力低下進行、膀胱直腸障害、会陰部感覚障害あれば救急受診指示。
        """
        let response = try decodeChatResponse(content: raw)
        let user = "56歳男性、昨日脚立より転落し腰部打撲。右大腿外側痛・右下肢脱力感。"
        let out = response.chartText(fallbackLastUserMessage: user)
        XCTAssertFalse(out.contains("S：未記載"), out)
        XCTAssertTrue(out.contains("脚立"), out)
        XCTAssertTrue(out.hasPrefix("S：56"), out)
    }

    private func decodeChatResponse(content: String) throws -> ChatResponse {
        let payload: [String: Any] = [
            "id": "x",
            "object": "chat.completion",
            "created": 0,
            "model": "m",
            "choices": [
                [
                    "index": 0,
                    "message": ["role": "assistant", "content": content],
                    "finish_reason": "stop",
                ],
            ],
            "usage": [
                "prompt_tokens": 1,
                "completion_tokens": 2,
                "total_tokens": 3,
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
}
