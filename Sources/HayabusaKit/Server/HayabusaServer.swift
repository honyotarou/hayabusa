import Foundation
import HayabusaLocalPolicy
import Hummingbird

package struct HayabusaServer {
    package let engine: any InferenceEngine
    package let port: Int
    package let bindAddress: String
    package let clusterManager: ClusterManager?
    package let speculativeDecoder: SpeculativeDecoder?
    package let kvQuantizeMode: KVQuantizeMode
    package let layerSkipConfig: LayerSkipConfig?

    package init(
        engine: any InferenceEngine,
        port: Int,
        bindAddress: String = "127.0.0.1",
        clusterManager: ClusterManager? = nil,
        speculativeDecoder: SpeculativeDecoder? = nil,
        kvQuantizeMode: KVQuantizeMode = .off,
        layerSkipConfig: LayerSkipConfig? = nil
    ) {
        self.engine = engine
        self.port = port
        self.bindAddress = bindAddress
        self.clusterManager = clusterManager
        self.speculativeDecoder = speculativeDecoder
        self.kvQuantizeMode = kvQuantizeMode
        self.layerSkipConfig = layerSkipConfig
    }

    /// Builds the Hummingbird application (e.g. for `.test(.live)` integration tests).
    package func makeApplication() -> Application<Router<HayabusaRequestContext>.Responder> {
        Application(
            router: buildRouter(),
            configuration: .init(address: .hostname(bindAddress, port: port))
        )
    }

    package func run() async throws {
        try await makeApplication().runService()
    }

    private func buildRouter() -> Router<HayabusaRequestContext> {
        let router = Router(context: HayabusaRequestContext.self)
        let engine = self.engine
        let clusterManager = self.clusterManager
        let speculativeDecoder = self.speculativeDecoder
        let kvQuantizeMode = self.kvQuantizeMode
        let layerSkipConfig = self.layerSkipConfig

        // GET /health
        router.get("health") { _, _ -> String in
            "{\"status\":\"ok\"}"
        }

        // POST /v1/chat/completions
        router.post("v1/chat/completions") { request, context in
            let chatRequest = try await context.requestDecoder.decode(
                ChatRequest.self, from: request, context: context
            )
            let snapshots = chatRequest.messages.map { ($0.role, $0.content) }
            if case let .failure(err) = LocalChatValidation.validate(
                messages: snapshots,
                maxTokens: chatRequest.max_tokens,
                temperature: chatRequest.temperature,
                limits: .localDeveloper
            ) {
                throw err.httpError()
            }

            let result = try await engine.generate(
                messages: chatRequest.messages,
                maxTokens: chatRequest.max_tokens ?? 2048,
                temperature: chatRequest.temperature ?? 0.7,
                priority: SlotPriority(string: chatRequest.priority)
            )

            let response = ChatResponse(
                id: "hayabusa-\(UUID().uuidString.prefix(8))",
                model: chatRequest.model ?? "local",
                content: result.text,
                promptTokens: result.promptTokens,
                completionTokens: result.completionTokens,
                fallbackSubject: chatRequest.messages.last(where: { $0.role == "user" })?.content
            )

            let jsonData = try JSONEncoder().encode(response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            return jsonString
        }

        // GET /slots — diagnostic endpoint
        router.get("slots") { _, _ -> String in
            let summary = engine.slotSummary()
            let slots = summary.map { slot in
                "{\"index\":\(slot.index),\"state\":\"\(slot.state)\",\"priority\":\"\(slot.priority)\",\"pos\":\(slot.pos)}"
            }
            return "[\(slots.joined(separator: ","))]"
        }

        // GET /v1/memory — memory status (available for any backend)
        router.get("v1/memory") { _, _ -> String in
            if let info = engine.memoryInfo() {
                return """
                {"totalPhysical":\(info.totalPhysical),"rssBytes":\(info.rssBytes),\
                "freeEstimate":\(info.freeEstimate),"activeSlots":\(info.activeSlots),\
                "pressure":"\(info.pressure)","slots":\(engine.slotCount)}
                """
            }
            return "{\"pressure\":\"unknown\"}"
        }

        // GET /v1/cluster/status — cluster node listing with memory info
        router.get("v1/cluster/status") { _, _ -> String in
            // Update local node memory before responding
            if let cm = clusterManager, let info = engine.memoryInfo() {
                cm.updateLocalMemory(info)
            }

            guard let cm = clusterManager else {
                return "{\"cluster\":false}"
            }
            let nodes = cm.allNodes()
            let nodesJson = nodes.map { node in
                """
                {"id":"\(node.id)","host":"\(node.host)","port":\(node.port),\
                "backend":"\(node.backend)","model":"\(node.model)","slots":\(node.slots),\
                "isLocal":\(node.isLocal),"isHealthy":\(node.isHealthy),\
                "consecutiveFailures":\(node.consecutiveFailures),\
                "totalMemory":\(node.totalMemory),"rssBytes":\(node.rssBytes),\
                "freeMemory":\(node.freeMemory),"memoryPressure":"\(node.memoryPressure)"}
                """
            }
            let bandwidthJson = cm.bandwidthSnapshots().map { s in
                """
                {"nodeId":"\(s.nodeId)","isLocal":\(s.isLocal),\
                "ewmaTokPerSec":\(String(format: "%.1f", s.ewmaTokPerSec)),\
                "activeRequests":\(s.activeRequests),\
                "totalRequests":\(s.totalRequests),"totalTokens":\(s.totalTokens)}
                """
            }
            return """
            {"cluster":true,"routing":"uzu",\
            "nodes":[\(nodesJson.joined(separator: ","))],\
            "bandwidth":[\(bandwidthJson.joined(separator: ","))]}
            """
        }

        // GET /v1/stats — speculative decoding & KV quantization metrics
        router.get("v1/stats") { _, _ -> String in
            var parts: [String] = []

            // Speculative decoding metrics
            if let sd = speculativeDecoder {
                let m = sd.metrics
                parts.append("""
                "speculative":{\
                "enabled":true,\
                "speculativeTokens":\(4),\
                "totalDraftTokens":\(m.totalDraftTokens),\
                "acceptedTokens":\(m.acceptedTokens),\
                "acceptanceRate":\(String(format: "%.4f", m.acceptanceRate)),\
                "totalGenerations":\(m.totalGenerations),\
                "totalCompletionTokens":\(m.totalCompletionTokens),\
                "effectiveTokPerSec":\(String(format: "%.1f", m.totalGenerations > 0 ? Double(m.totalCompletionTokens) / Double(m.totalGenerations) : 0))}
                """)
            } else {
                parts.append("\"speculative\":{\"enabled\":false}")
            }

            // KV cache quantization info
            let kvEnabled = kvQuantizeMode != .off
            parts.append("""
            "kvQuantize":{\
            "enabled":\(kvEnabled),\
            "mode":"\(kvQuantizeMode.rawValue)",\
            "description":"\(kvQuantizeMode.description)"}
            """)

            // Layer skipping info
            if let ls = layerSkipConfig {
                parts.append("\"layerSkip\":\(ls.statsJSON)")
            } else {
                parts.append("\"layerSkip\":{\"enabled\":false}")
            }

            // Memory info
            if let info = engine.memoryInfo() {
                parts.append("""
                "memory":{\
                "totalPhysical":\(info.totalPhysical),\
                "rssBytes":\(info.rssBytes),\
                "freeEstimate":\(info.freeEstimate),\
                "pressure":"\(info.pressure)"}
                """)
            }

            return "{\(parts.joined(separator: ","))}"
        }

        return router
    }
}
