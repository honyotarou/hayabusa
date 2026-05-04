import Foundation

public enum LocalChatValidationError: Error, Sendable, Equatable {
    case noMessages
    case tooManyMessages(limit: Int)
    case messageRoleEmpty(index: Int)
    case messageRoleNotAllowed(index: Int, role: String)
    case messageContentTooLong(index: Int, limit: Int)
    case totalContentTooLong(limit: Int)
    case maxTokensOutOfRange(value: Int, min: Int, max: Int)
    case temperatureOutOfRange(value: Float, min: Float, max: Float)
}

public enum LocalChatValidation {
    /// validates decoded chat fields before touching the inference engine (single entry point).
    public static func validate(
        messages: [(role: String, content: String)],
        maxTokens: Int?,
        temperature: Float?,
        limits: LocalServiceLimits
    ) -> Result<Void, LocalChatValidationError> {
        if messages.isEmpty {
            return .failure(.noMessages)
        }
        if messages.count > limits.maxChatMessages {
            return .failure(.tooManyMessages(limit: limits.maxChatMessages))
        }

        var totalChars = 0
        for (index, message) in messages.enumerated() {
            let role = message.role.trimmingCharacters(in: .whitespacesAndNewlines)
            if role.isEmpty {
                return .failure(.messageRoleEmpty(index: index))
            }
            if !limits.allowedRoles.contains(role.lowercased()) {
                return .failure(.messageRoleNotAllowed(index: index, role: role))
            }

            let len = message.content.utf16.count
            if len > limits.maxContentCharsPerMessage {
                return .failure(.messageContentTooLong(index: index, limit: limits.maxContentCharsPerMessage))
            }
            totalChars += len
        }

        if totalChars > limits.maxTotalContentChars {
            return .failure(.totalContentTooLong(limit: limits.maxTotalContentChars))
        }

        if let maxTokens {
            if maxTokens < limits.maxTokensMin || maxTokens > limits.maxTokensMax {
                return .failure(
                    .maxTokensOutOfRange(
                        value: maxTokens,
                        min: limits.maxTokensMin,
                        max: limits.maxTokensMax
                    )
                )
            }
        }

        if let temperature {
            if temperature < limits.temperatureMin || temperature > limits.temperatureMax {
                return .failure(
                    .temperatureOutOfRange(
                        value: temperature,
                        min: limits.temperatureMin,
                        max: limits.temperatureMax
                    )
                )
            }
        }

        return .success(())
    }
}
