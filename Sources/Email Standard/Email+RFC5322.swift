//
//  Email+RFC5322.swift
//  swift-email-standard
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import EmailAddress_Standard
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
        let from = try RFC_5322.EmailAddress(email.from)
        let to = try email.to.map { try RFC_5322.EmailAddress($0) }

        // Convert optional CC addresses
        let cc: [RFC_5322.EmailAddress]? = try email.cc.map { ccList in
            try ccList.map { try RFC_5322.EmailAddress($0) }
        }

        // Convert optional BCC addresses
        let bcc: [RFC_5322.EmailAddress]? = try email.bcc.map { bccList in
            try bccList.map { try RFC_5322.EmailAddress($0) }
        }

        // Convert optional Reply-To address
        let replyTo: RFC_5322.EmailAddress? = try email.replyTo.map {
            try RFC_5322.EmailAddress($0)
        }

        // Generate Message-ID if not provided in additional headers
        // TODO: Fix this later
        let messageId = email.additionalHeaders[.messageId] ?? RFC_5322.Message.generateMessageId(
            from: from,
            uniqueId: "FIX TO DO LATER"
        )

        // Get body data
        let bodyData = email.body.data

        // Prepare headers (exclude Message-ID as it's a dedicated field)
        var additionalHeaders = email.additionalHeaders.filter { $0.name != .messageId }

        // Add MIME headers from body
        additionalHeaders.append(
            .init(name: .contentType, value: email.body.contentType.headerValue)
        )
        if let encoding = email.body.transferEncoding {
            additionalHeaders.append(
                .init(name: .contentTransferEncoding, value: encoding.headerValue)
            )
        }

        self.init(
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,  // Stored for SMTP envelope; excluded from rendered message headers
            replyTo: replyTo,
            date: email.date,
            subject: email.subject,
            messageId: messageId,
            body: Array(bodyData),
            additionalHeaders: additionalHeaders
        )
    }
}
