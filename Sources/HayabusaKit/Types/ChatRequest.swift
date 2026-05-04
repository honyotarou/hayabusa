package struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String

    package init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

package struct ChatRequest: Codable, Sendable {
    let messages: [ChatMessage]
    let model: String?
    let max_tokens: Int?
    let temperature: Float?
    let priority: String?
}
