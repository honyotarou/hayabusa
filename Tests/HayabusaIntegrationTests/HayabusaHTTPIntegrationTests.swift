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
