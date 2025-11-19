import RFC_2045
import RFC_2046

extension RFC_2046.Multipart {
    /// Creates a multipart/alternative message (text + HTML)
    ///
    /// Commonly used for emails that provide both plain text and HTML versions.
    /// Email clients display the last format they understand (typically HTML).
    ///
    /// Automatically generates a cryptographically random boundary using RFC 4648 hex encoding.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart.alternative(
    ///     textContent: "Hello, World!",
    ///     htmlContent: "<h1>Hello, World!</h1>"
    /// )
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046 Section 5.1.4: Multipart/Alternative subtype
    /// - RFC 4648 Section 8: Base 16 (hex) encoding for boundary generation
    ///
    /// - Parameters:
    ///   - textContent: Plain text version
    ///   - htmlContent: HTML version
    /// - Returns: A multipart/alternative message
    /// - Throws: `RFC_2046.MultipartError` if validation fails
    public static func alternative(
        textContent: String,
        htmlContent: String
    ) throws -> Self {
        try Self(
            subtype: .alternative,
            parts: [
                .init(
                    contentType: .textPlainUTF8,
                    transferEncoding: .sevenBit,
                    text: textContent
                ),
                .init(
                    contentType: .textHTMLUTF8,
                    transferEncoding: .sevenBit,
                    text: htmlContent
                ),
            ],
            boundary: .random()
        )
    }

    /// Creates a multipart/mixed message
    ///
    /// Used for independent parts that should be presented in sequence.
    /// Common use case: email body with file attachments.
    ///
    /// Automatically generates a cryptographically random boundary using RFC 4648 hex encoding.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart.mixed(
    ///     parts: [textPart, attachmentPart]
    /// )
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046 Section 5.1.3: Multipart/Mixed subtype
    /// - RFC 4648 Section 8: Base 16 (hex) encoding for boundary generation
    ///
    /// - Parameters:
    ///   - parts: Body parts in order
    /// - Returns: A multipart/mixed message
    /// - Throws: `RFC_2046.MultipartError` if validation fails
    public static func mixed(
        parts: [RFC_2046.BodyPart]
    ) throws -> Self {
        try Self(
            subtype: .mixed,
            parts: parts,
            boundary: .random()
        )
    }
}
