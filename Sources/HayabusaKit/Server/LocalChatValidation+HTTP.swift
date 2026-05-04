import Foundation
import HayabusaLocalPolicy
import Hummingbird

extension LocalChatValidationError {
    /// transport mapping isolated from domain rules (local server only).
    func httpError() -> HTTPError {
        switch self {
        case .noMessages:
            HTTPError(.badRequest, message: "messages must be a non-empty array")
        case .tooManyMessages(let limit):
            HTTPError(.badRequest, message: "too many messages (limit \(limit))")
        case .messageRoleEmpty(let index):
            HTTPError(.badRequest, message: "message[\(index)] has empty role")
        case .messageRoleNotAllowed(let index, let role):
            HTTPError(.badRequest, message: "message[\(index)] role not allowed: \(role)")
        case .messageContentTooLong(let index, let limit):
            HTTPError(.badRequest, message: "message[\(index)] content too long (limit \(limit) UTF-16 code units)")
        case .totalContentTooLong(let limit):
            HTTPError(.badRequest, message: "messages exceed total content limit (\(limit) UTF-16 code units)")
        case .maxTokensOutOfRange(let value, let min, let max):
            HTTPError(.badRequest, message: "max_tokens \(value) out of range \(min)...\(max)")
        case .temperatureOutOfRange(let value, let min, let max):
            HTTPError(.badRequest, message: "temperature \(value) out of range \(min)...\(max)")
        }
    }
}
