import Foundation

/// tunable caps for a single-machine, localhost-first deployment.
public struct LocalServiceLimits: Sendable, Equatable {
    /// aligned with Hummingbird decode path (`RequestContext.maxUploadSize`).
    public let maxJsonBodyBytes: Int
    public let maxChatMessages: Int
    public let maxContentCharsPerMessage: Int
    public let maxTotalContentChars: Int
    public let maxTokensMin: Int
    public let maxTokensMax: Int
    public let temperatureMin: Float
    public let temperatureMax: Float
    /// lowercased role names (e.g. `user`, `system`); matching is case-insensitive.
    public let allowedRoles: Set<String>

    public init(
        maxJsonBodyBytes: Int,
        maxChatMessages: Int,
        maxContentCharsPerMessage: Int,
        maxTotalContentChars: Int,
        maxTokensMin: Int,
        maxTokensMax: Int,
        temperatureMin: Float,
        temperatureMax: Float,
        allowedRoles: Set<String>
    ) {
        self.maxJsonBodyBytes = maxJsonBodyBytes
        self.maxChatMessages = maxChatMessages
        self.maxContentCharsPerMessage = maxContentCharsPerMessage
        self.maxTotalContentChars = maxTotalContentChars
        self.maxTokensMin = maxTokensMin
        self.maxTokensMax = maxTokensMax
        self.temperatureMin = temperatureMin
        self.temperatureMax = temperatureMax
        self.allowedRoles = allowedRoles
    }

    /// conservative defaults for interactive local use; adjust in one place when hardware/policy changes.
    public static let localDeveloper = LocalServiceLimits(
        maxJsonBodyBytes: 8 * 1024 * 1024,
        maxChatMessages: 512,
        maxContentCharsPerMessage: 512 * 1024,
        maxTotalContentChars: 2 * 1024 * 1024,
        maxTokensMin: 1,
        maxTokensMax: 128_000,
        temperatureMin: 0,
        temperatureMax: 2,
        allowedRoles: ["system", "user", "assistant", "tool"]
    )
}
