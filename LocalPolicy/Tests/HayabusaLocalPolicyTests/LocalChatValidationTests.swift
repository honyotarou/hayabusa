import Foundation
import HayabusaLocalPolicy
import XCTest

final class LocalChatValidationTests: XCTestCase {
    private var limits: LocalServiceLimits { .localDeveloper }

    func testRejectsEmptyMessages() {
        let result = LocalChatValidation.validate(
            messages: [],
            maxTokens: 64,
            temperature: 0.5,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(err, .noMessages)
    }

    func testRejectsTooManyMessages() {
        let many = (0..<(limits.maxChatMessages + 1)).map { i in
            (role: "user", String(repeating: "a", count: 4) + "\(i)")
        }
        let result = LocalChatValidation.validate(
            messages: many,
            maxTokens: 8,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(err, .tooManyMessages(limit: limits.maxChatMessages))
    }

    func testRejectsLongMessage() {
        let long = String(repeating: "z", count: limits.maxContentCharsPerMessage + 1)
        let result = LocalChatValidation.validate(
            messages: [("user", long)],
            maxTokens: 8,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(err, .messageContentTooLong(index: 0, limit: limits.maxContentCharsPerMessage))
    }

    func testRejectsTotalContentOverflow() {
        let chunk = String(repeating: "x", count: limits.maxContentCharsPerMessage)
        let messages = [
            ("user", chunk),
            ("user", chunk),
            ("user", chunk),
            ("user", chunk),
            ("user", chunk),
        ]
        let result = LocalChatValidation.validate(
            messages: messages,
            maxTokens: 8,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(err, .totalContentTooLong(limit: limits.maxTotalContentChars))
    }

    func testRejectsMaxTokensTooSmall() {
        let result = LocalChatValidation.validate(
            messages: [("user", "hi")],
            maxTokens: 0,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(
            err,
            .maxTokensOutOfRange(
                value: 0,
                min: limits.maxTokensMin,
                max: limits.maxTokensMax
            )
        )
    }

    func testRejectsMaxTokensTooLarge() {
        let result = LocalChatValidation.validate(
            messages: [("user", "hi")],
            maxTokens: limits.maxTokensMax + 1,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(
            err,
            .maxTokensOutOfRange(
                value: limits.maxTokensMax + 1,
                min: limits.maxTokensMin,
                max: limits.maxTokensMax
            )
        )
    }

    func testAllowsNilMaxTokens() {
        let result = LocalChatValidation.validate(
            messages: [("user", "hello")],
            maxTokens: nil,
            temperature: 0.2,
            limits: limits
        )
        guard case .success = result else {
            return XCTFail("expected success")
        }
    }

    func testRejectsTemperature() {
        let result = LocalChatValidation.validate(
            messages: [("user", "hello")],
            maxTokens: 16,
            temperature: 2.5,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(
            err,
            .temperatureOutOfRange(
                value: 2.5,
                min: limits.temperatureMin,
                max: limits.temperatureMax
            )
        )
    }

    func testRejectsUnknownRole() {
        let result = LocalChatValidation.validate(
            messages: [("root", "hello")],
            maxTokens: 16,
            temperature: nil,
            limits: limits
        )
        guard case let .failure(err) = result else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(err, .messageRoleNotAllowed(index: 0, role: "root"))
    }

    func testAcceptsWellFormed() {
        let result = LocalChatValidation.validate(
            messages: [
                ("system", "be brief"),
                ("user", "ping"),
            ],
            maxTokens: 128,
            temperature: 1,
            limits: limits
        )
        guard case .success = result else {
            XCTFail("expected success")
            return
        }
    }

    func testRolesAreCaseInsensitive() {
        let result = LocalChatValidation.validate(
            messages: [("USER", "hi")],
            maxTokens: 8,
            temperature: nil,
            limits: limits
        )
        guard case .success = result else {
            XCTFail("expected success")
            return
        }
    }
}
