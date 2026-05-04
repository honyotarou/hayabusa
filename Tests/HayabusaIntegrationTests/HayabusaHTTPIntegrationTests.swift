import HTTPTypes
import HayabusaKit
import HummingbirdTesting
import NIOCore
import XCTest

final class HayabusaHTTPIntegrationTests: XCTestCase {
    func testGETHealthLive() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let app = server.makeApplication()
        try await app.test(.live) { client in
            _ = try await client.execute(uri: "/health", method: .get) { response in
                XCTAssertEqual(response.status, .ok)
                let text = String(buffer: response.body)
                XCTAssertTrue(text.contains("ok"), text)
            }
        }
    }

    func testPOSTChatCompletionsReturnsMockContent() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(fixedReply: "mock-reply"),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let app = server.makeApplication()
        let bodyJson = """
        {"messages":[{"role":"user","content":"hi"}],"max_tokens":16}
        """
        let postBody: ByteBuffer = {
            var b = ByteBufferAllocator().buffer(capacity: bodyJson.utf8.count)
            b.writeString(bodyJson)
            return b
        }()
        try await app.test(.live) { client in
            _ = try await client.execute(
                uri: "/v1/chat/completions",
                method: .post,
                headers: [.contentType: "application/json"],
                body: postBody
            ) { response in
                XCTAssertEqual(response.status, .ok, "body: \(String(buffer: response.body))")
                let text = String(buffer: response.body)
                XCTAssertTrue(text.contains("mock-reply"), text)
            }
        }
    }

    func testPOSTChatCompletionsFiltersEnglishThinkingAfterSOAPMarker() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(fixedReply: """
            【S】`.
            *   No content before `【S】`.
            *   No thinking process, analysis, drafts, self-correction, or English explanations in the output.
            2.  **Analyze the Input:**
            *   **Patient:** 56-year-old male.
            """),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let text = try await postChat(server: server, bodyJson: """
        {"messages":[{"role":"user","content":"56歳男性、脚立から落ちて腰痛と右足痛"}],"max_tokens":16}
        """)

        XCTAssertFalse(text.contains("出力形式が崩れたため、再生成が必要です。"), text)
        XCTAssertTrue(text.contains("【S】"), text)
        XCTAssertTrue(text.contains("56歳男性、脚立から落ちて腰痛と右足痛"), text)
        XCTAssertTrue(text.contains("【O】"), text)
        XCTAssertTrue(text.contains("未記載"), text)
        XCTAssertFalse(text.contains("No content before"), text)
        XCTAssertFalse(text.contains("Analyze the Input"), text)
        XCTAssertFalse(text.contains("56-year-old male"), text)
    }

    func testPOSTChatCompletionsFiltersEnglishThinkingWithoutSOAPMarker() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(fixedReply: """
            1. **Analyze the Input:**
            * **Patient:** 56-year-old male.
            * **Chief Complaint:** waist and right leg pain.
            2. **Drafting the Content:**
            """),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let text = try await postChat(server: server, bodyJson: """
        {"messages":[{"role":"user","content":"56歳男性、脚立から落ちて腰痛と右足痛"}],"max_tokens":16}
        """)

        XCTAssertFalse(text.contains("出力形式が崩れたため、再生成が必要です。"), text)
        XCTAssertTrue(text.contains("【S】"), text)
        XCTAssertTrue(text.contains("56歳男性、脚立から落ちて腰痛と右足痛"), text)
        XCTAssertTrue(text.contains("【P】"), text)
        XCTAssertFalse(text.contains("Analyze the Input"), text)
        XCTAssertFalse(text.contains("Drafting the Content"), text)
        XCTAssertFalse(text.contains("Chief Complaint"), text)
    }

    func testPOSTChatCompletionsKeepsJapaneseSOAPFromMarker() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(fixedReply: """
            余計な前置き
            【S】
            56歳男性。昨日脚立から転落し腰部を打撲。

            【O】
            腰痛、右下肢痛あり。
            """),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let text = try await postChat(server: server, bodyJson: """
        {"messages":[{"role":"user","content":"56歳男性、脚立から落ちて腰痛と右足痛"}],"max_tokens":16}
        """)

        XCTAssertFalse(text.contains("余計な前置き"), text)
        XCTAssertTrue(text.contains("【S】"), text)
        XCTAssertTrue(text.contains("56歳男性"), text)
        XCTAssertTrue(text.contains("【O】"), text)
    }

    func testPOSTChatCompletionsValidationRejectsBadTemperature() async throws {
        let server = HayabusaServer(
            engine: MockInferenceEngine(),
            port: 0,
            bindAddress: "127.0.0.1"
        )
        let app = server.makeApplication()
        let bodyJson = """
        {"messages":[{"role":"user","content":"hi"}],"max_tokens":16,"temperature":99}
        """
        let postBody: ByteBuffer = {
            var b = ByteBufferAllocator().buffer(capacity: bodyJson.utf8.count)
            b.writeString(bodyJson)
            return b
        }()
        try await app.test(.live) { client in
            _ = try await client.execute(
                uri: "/v1/chat/completions",
                method: .post,
                headers: [.contentType: "application/json"],
                body: postBody
            ) { response in
                XCTAssertEqual(response.status, .badRequest)
            }
        }
    }

    private func postChat(server: HayabusaServer, bodyJson: String) async throws -> String {
        let postBody: ByteBuffer = {
            var b = ByteBufferAllocator().buffer(capacity: bodyJson.utf8.count)
            b.writeString(bodyJson)
            return b
        }()

        let app = server.makeApplication()
        return try await app.test(.live) { client in
            try await client.execute(
                uri: "/v1/chat/completions",
                method: .post,
                headers: [.contentType: "application/json"],
                body: postBody
            ) { response in
                XCTAssertEqual(response.status, .ok, "body: \(String(buffer: response.body))")
                return String(buffer: response.body)
            }
        }
    }
}

/// Minimal engine for HTTP integration tests (no GGUF / MLX).
private struct MockInferenceEngine: InferenceEngine {
    let fixedReply: String

    init(fixedReply: String = "ok") {
        self.fixedReply = fixedReply
    }

    var modelDescription: String { "mock-engine" }
    var slotCount: Int { 1 }

    func generate(
        messages: [ChatMessage],
        maxTokens: Int,
        temperature: Float,
        priority: SlotPriority
    ) async throws -> GenerationResult {
        _ = messages
        _ = maxTokens
        _ = temperature
        _ = priority
        return GenerationResult(text: fixedReply, promptTokens: 1, completionTokens: 1)
    }

    func slotSummary() -> [(index: Int, state: String, priority: String, pos: Int32)] {
        [(index: 0, state: "idle", priority: "batch", pos: 0)]
    }
}
