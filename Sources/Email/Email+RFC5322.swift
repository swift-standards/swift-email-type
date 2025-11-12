//
//  Email+RFC5322.swift
//  swift-email-type
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Foundation
import RFC_5322

extension RFC_5322.Message {
    /// Creates an RFC 5322 Message from an Email
    ///
    /// Converts the high-level Email composition type to the wire-format RFC 5322 Message.
    /// This enables serialization of Email instances to .eml files.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try Email(
    ///     to: [EmailAddress("recipient@example.com")],
    ///     from: EmailAddress("sender@example.com"),
    ///     subject: "Hello",
    ///     html: "<h1>Hello, World!</h1>"
    /// )
    ///
    /// let message = try RFC_5322.Message(from: email)
    /// let emlContent = message.render()
    /// ```
    ///
    /// - Parameter email: The Email to convert
    /// - Throws: If email addresses cannot be parsed or email is invalid
    public init(from email: Email) throws {
        // Convert from EmailAddress to RFC_5322.EmailAddress
        let from = try RFC_5322.EmailAddress(email.from.rawValue)
        let to = try email.to.map { try RFC_5322.EmailAddress($0.rawValue) }

        // Convert optional CC addresses
        let cc: [RFC_5322.EmailAddress]? = try email.cc.map { ccList in
            try ccList.map { try RFC_5322.EmailAddress($0.rawValue) }
        }

        // Convert optional Reply-To address
        let replyTo: RFC_5322.EmailAddress? = try email.replyTo.map {
            try RFC_5322.EmailAddress($0.rawValue)
        }

        // Generate Message-ID if not provided in additional headers
        let messageId = email.additionalHeaders[.messageId] ?? RFC_5322.Message.generateMessageId(from: from)

        // Get body data
        let bodyData = email.body.data

        // Prepare headers (exclude Message-ID as it's a dedicated field)
        var additionalHeaders = email.additionalHeaders.filter { $0.name != .messageId }

        // Add MIME headers from body
        additionalHeaders.append(.init(name: .contentType, value: email.body.contentType.headerValue))
        if let encoding = email.body.transferEncoding {
            additionalHeaders.append(.init(name: .contentTransferEncoding, value: encoding.headerValue))
        }

        self.init(
            from: from,
            to: to,
            cc: cc,
            bcc: nil, // BCC is intentionally excluded from message headers
            replyTo: replyTo,
            subject: email.subject,
            date: Date(), // Current date for message generation
            messageId: messageId,
            body: bodyData,
            additionalHeaders: additionalHeaders
        )
    }
}
