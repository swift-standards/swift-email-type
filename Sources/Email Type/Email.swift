@_exported import EmailAddress
import Foundation
@_exported import RFC_2045
@_exported import RFC_2046
@_exported import RFC_5322

/// A type-safe email message
///
/// Represents a complete email message with addresses, subject, body content,
/// and headers. Built on RFC standards for proper email formatting.
///
/// ## Example
///
/// ```swift
/// // Simple HTML email
/// let email = try Email(
///     to: [EmailAddress("recipient@example.com")],
///     from: EmailAddress("sender@example.com"),
///     subject: "Hello!",
///     html: "<h1>Hello, World!</h1>"
/// )
///
/// // Email with text and HTML alternatives
/// let email = try Email(
///     to: [EmailAddress("recipient@example.com")],
///     from: EmailAddress("sender@example.com"),
///     subject: "Newsletter",
///     text: "Plain text version",
///     html: "<h1>HTML version</h1>"
/// )
/// ```
///
/// This module re-exports EmailAddress, RFC 2045, and RFC 2046 for convenience.
public struct Email: Hashable, Sendable, CustomDebugStringConvertible {
    /// Recipient addresses
    public let to: [EmailAddress]

    /// Sender address
    public let from: EmailAddress

    /// Reply-to address (if different from sender)
    public let replyTo: EmailAddress?

    /// Carbon copy addresses
    public let cc: [EmailAddress]?

    /// Blind carbon copy addresses
    public let bcc: [EmailAddress]?

    /// Email subject line
    public let subject: String

    /// Email body content
    public let body: Body

    /// Additional custom headers
    ///
    /// These are supplemental headers beyond the typed properties (to, from, subject, etc.).
    /// MIME headers (Content-Type, Content-Transfer-Encoding) are automatically determined
    /// by the `body` property and should not be included here.
    ///
    /// Common use cases: X-Mailer, List-Unsubscribe, X-Priority, etc.
    public let additionalHeaders: [RFC_5322.Header]

    /// Creates an email message
    ///
    /// - Parameters:
    ///   - to: Recipient addresses (must not be empty)
    ///   - from: Sender address
    ///   - replyTo: Reply-to address (optional)
    ///   - cc: Carbon copy addresses (optional)
    ///   - bcc: Blind carbon copy addresses (optional)
    ///   - subject: Email subject
    ///   - body: Email body content
    ///   - additionalHeaders: Additional custom headers (optional)
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        replyTo: EmailAddress? = nil,
        cc: [EmailAddress]? = nil,
        bcc: [EmailAddress]? = nil,
        subject: String,
        body: Body,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws {
        guard !to.isEmpty else {
            throw Email.Error.emptyRecipients
        }

        self.to = to
        self.from = from
        self.replyTo = replyTo
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.additionalHeaders = additionalHeaders
    }

    /// All MIME headers including Content-Type
    ///
    /// Combines additional headers with MIME headers from the body.
    /// MIME headers (Content-Type, Content-Transfer-Encoding) are automatically
    /// determined from the `body` property.
    public var allHeaders: [RFC_5322.Header] {
        var result = additionalHeaders
        result[.contentType] = body.contentType.headerValue
        if let encoding = body.transferEncoding {
            result[.contentTransferEncoding] = encoding.headerValue
        }
        return result
    }
}

// MARK: - Error

extension Email {
    /// Email validation errors
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The recipient list is empty
        case emptyRecipients
    }
}

extension Email.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyRecipients:
            return "Email must have at least one recipient in the 'to' field"
        }
    }
}

// MARK: - Body

extension Email {
    /// Email body content
    ///
    /// Supports plain text, HTML, or multipart (text + HTML) content.
    /// Content is stored as Data internally for efficiency, with String convenience methods.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Plain text (String convenience)
    /// let body = Email.Body.text("Hello!")
    ///
    /// // HTML (String convenience)
    /// let body = Email.Body.html("<h1>Hello!</h1>")
    ///
    /// // Direct Data usage
    /// let body = Email.Body.textData(myData, charset: "UTF-8")
    ///
    /// // Text + HTML alternative
    /// let body = try Email.Body.multipart(
    ///     .alternative(
    ///         textContent: "Hello!",
    ///         htmlContent: "<h1>Hello!</h1>"
    ///     )
    /// )
    /// ```
    public enum Body: Hashable, Sendable {
        /// Plain text content (stored as UTF-8 encoded data)
        case text(Data, charset: RFC_2045.Charset)

        /// HTML content (stored as UTF-8 encoded data)
        case html(Data, charset: RFC_2045.Charset)

        /// Multipart message (text + HTML alternatives, attachments, etc.)
        case multipart(RFC_2046.Multipart)

        /// The Content-Type for this body
        public var contentType: RFC_2045.ContentType {
            switch self {
            case .text(_, let charset):
                return RFC_2045.ContentType(
                    type: "text",
                    subtype: "plain",
                    parameters: ["charset": charset.rawValue]
                )

            case .html(_, let charset):
                return RFC_2045.ContentType(
                    type: "text",
                    subtype: "html",
                    parameters: ["charset": charset.rawValue]
                )

            case .multipart(let multipart):
                return multipart.contentType
            }
        }

        /// The Content-Transfer-Encoding for this body (if needed)
        public var transferEncoding: RFC_2045.ContentTransferEncoding? {
            switch self {
            case .text, .html:
                return .sevenBit
            case .multipart:
                return nil  // Multipart doesn't have transfer encoding at top level
            }
        }

        /// Renders the body content as a string
        ///
        /// For multipart bodies, this includes the complete MIME structure
        /// with boundaries.
        public func render() -> String {
            switch self {
            case .text(let data, _):
                return String(data: data, encoding: .utf8) ?? ""

            case .html(let data, _):
                return String(data: data, encoding: .utf8) ?? ""

            case .multipart(let multipart):
                return multipart.render()
            }
        }

        /// The rendered body content
        public var content: String {
            render()
        }

        /// The raw data content
        public var data: Data {
            switch self {
            case .text(let data, _), .html(let data, _):
                return data
            case .multipart(let multipart):
                return Data(multipart.render().utf8)
            }
        }
    }
}

// MARK: - Body Convenience Constructors

extension Email.Body {
    /// Creates a plain text body from a String
    ///
    /// - Parameters:
    ///   - content: The text content
    ///   - charset: Character set (default: UTF-8)
    /// - Returns: A text email body
    public static func text(_ content: String, charset: RFC_2045.Charset = .utf8) -> Self {
        .text(Data(content.utf8), charset: charset)
    }

    /// Creates an HTML body from a String
    ///
    /// - Parameters:
    ///   - content: The HTML content
    ///   - charset: Character set (default: UTF-8)
    /// - Returns: An HTML email body
    public static func html(_ content: String, charset: RFC_2045.Charset = .utf8) -> Self {
        .html(Data(content.utf8), charset: charset)
    }

    /// Creates a plain text body from Data
    ///
    /// - Parameters:
    ///   - content: The text content as data
    ///   - charset: Character set (default: UTF-8)
    /// - Returns: A text email body
    public static func textData(_ content: Data, charset: RFC_2045.Charset = .utf8) -> Self {
        .text(content, charset: charset)
    }

    /// Creates an HTML body from Data
    ///
    /// - Parameters:
    ///   - content: The HTML content as data
    ///   - charset: Character set (default: UTF-8)
    /// - Returns: An HTML email body
    public static func htmlData(_ content: Data, charset: RFC_2045.Charset = .utf8) -> Self {
        .html(content, charset: charset)
    }
}

// MARK: - ExpressibleByStringLiteral

extension Email.Body: ExpressibleByStringLiteral {
    /// Creates a plain text body from a string literal
    ///
    /// Enables convenient syntax: `body: "Hello, World!"` instead of `body: .text("Hello, World!")`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try Email(
    ///     to: [EmailAddress("recipient@example.com")],
    ///     from: EmailAddress("sender@example.com"),
    ///     subject: "Test",
    ///     body: "Hello, World!"  // Automatically becomes .text("Hello, World!")
    /// )
    /// ```
    public init(stringLiteral value: String) {
        self = .text(value)
    }
}

// MARK: - Convenience Initializers

extension Email {
    /// Creates an email with simple text content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - text: Plain text content
    ///   - additionalHeaders: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        text: String,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .text(text),
            additionalHeaders: additionalHeaders
        )
    }

    /// Creates an email with simple HTML content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - html: HTML content
    ///   - additionalHeaders: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        html: String,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .html(html),
            additionalHeaders: additionalHeaders
        )
    }

    /// Creates an email with both text and HTML content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - text: Plain text content
    ///   - html: HTML content
    ///   - additionalHeaders: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        text: String,
        html: String,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .multipart(try .alternative(textContent: text, htmlContent: html)),
            additionalHeaders: additionalHeaders
        )
    }
}

// MARK: - Protocol Conformances

extension Email {
    /// A debug description of the email
    ///
    /// Provides a summary showing sender, recipients, and subject for debugging contexts.
    public var debugDescription: String {
        let recipients = to.map(\.addressValue).joined(separator: ", ")
        var parts = ["From: \(from.addressValue)", "To: \(recipients)"]

        if let replyTo = replyTo {
            parts.append("Reply-To: \(replyTo.addressValue)")
        }
        if let cc = cc, !cc.isEmpty {
            parts.append("CC: \(cc.map(\.addressValue).joined(separator: ", "))")
        }
        if let bcc = bcc, !bcc.isEmpty {
            parts.append("BCC: \(bcc.map(\.addressValue).joined(separator: ", "))")
        }

        parts.append("Subject: \"\(subject)\"")

        return parts.joined(separator: " ")
    }
}

extension Email: Codable {
    enum CodingKeys: String, CodingKey {
        case to, from, replyTo, cc, bcc, subject, body, additionalHeaders
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try container.decode([EmailAddress].self, forKey: .to)
        self.from = try container.decode(EmailAddress.self, forKey: .from)
        self.replyTo = try container.decodeIfPresent(EmailAddress.self, forKey: .replyTo)
        self.cc = try container.decodeIfPresent([EmailAddress].self, forKey: .cc)
        self.bcc = try container.decodeIfPresent([EmailAddress].self, forKey: .bcc)
        self.subject = try container.decode(String.self, forKey: .subject)
        self.body = try container.decode(Body.self, forKey: .body)
        self.additionalHeaders = try container.decode(
            [RFC_5322.Header].self,
            forKey: .additionalHeaders
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try container.encode(from, forKey: .from)
        try container.encodeIfPresent(replyTo, forKey: .replyTo)
        try container.encodeIfPresent(cc, forKey: .cc)
        try container.encodeIfPresent(bcc, forKey: .bcc)
        try container.encode(subject, forKey: .subject)
        try container.encode(body, forKey: .body)
        try container.encode(additionalHeaders, forKey: .additionalHeaders)
    }
}

extension Email.Body: Codable {
    enum CodingKeys: String, CodingKey {
        case type, content, charset, multipart
    }

    enum BodyType: String, Codable {
        case text, html, multipart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BodyType.self, forKey: .type)

        switch type {
        case .text:
            let content = try container.decode(Data.self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .text(content, charset: charset)

        case .html:
            let content = try container.decode(Data.self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .html(content, charset: charset)

        case .multipart:
            let multipart = try container.decode(RFC_2046.Multipart.self, forKey: .multipart)
            self = .multipart(multipart)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let data, let charset):
            try container.encode(BodyType.text, forKey: .type)
            try container.encode(data, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .html(let data, let charset):
            try container.encode(BodyType.html, forKey: .type)
            try container.encode(data, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .multipart(let multipart):
            try container.encode(BodyType.multipart, forKey: .type)
            try container.encode(multipart, forKey: .multipart)
        }
    }
}
