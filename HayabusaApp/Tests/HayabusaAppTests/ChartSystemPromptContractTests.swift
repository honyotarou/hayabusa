import XCTest

@testable import HayabusaApp

final class ChartSystemPromptContractTests: XCTestCase {
    func testSystemPrompt_mandatorySubjectiveNeverPlaceholder() {
        let p = Strings.Chat.systemPrompt
        XCTAssertTrue(p.contains("S（Subjective）は必ず作成"), p)
        XCTAssertTrue(p.contains("Sを「未記載」にしてはいけない"), p)
        XCTAssertTrue(p.contains("Sは空欄・未記載にしない"), p)
        XCTAssertTrue(p.contains("必ずSへ変換して記載する"), p)
    }

    func testSystemPrompt_distributesSOAPRoles() {
        let p = Strings.Chat.systemPrompt
        XCTAssertTrue(p.contains("Sに入れるべき情報をO・A・Pだけに移してはいけない"), p)
        XCTAssertTrue(p.contains("Oには、医師が確認した身体所見"), p)
        XCTAssertTrue(p.contains("Aには、診断・鑑別診断"), p)
        XCTAssertTrue(p.contains("Pには、検査、処方"), p)
    }

    func testSystemPrompt_technicalOutputGuardrails() {
        let p = Strings.Chat.systemPrompt
        XCTAssertTrue(p.contains("「S：」から始める"), p)
        XCTAssertTrue(p.contains("JSON"), p)
        XCTAssertTrue(p.contains("【S】【O】【P】"), p)
    }

    func testSystemPrompt_includesLadderCaseStyleExample() {
        let p = Strings.Chat.systemPrompt
        XCTAssertTrue(p.contains("56歳男性。昨日、脚立から転落して腰部を打撲"), p)
        XCTAssertTrue(p.contains("神経学的所見は要評価"), p)
    }
}
