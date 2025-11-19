import RFC_2046
import RFC_4648

extension RFC_2046.Boundary {
    /// Generates a cryptographically random boundary using RFC 4648 hex encoding
    ///
    /// Creates a boundary in the format `----=_Part_{hex}` where hex is 32
    /// lowercase hexadecimal characters (16 random bytes).
    ///
    /// This boundary is guaranteed to:
    /// - Be unique (uses cryptographically random bytes)
    /// - Conform to RFC 2046 requirements (1-70 characters, no trailing space)
    /// - Be robust for mail gateway transport
    /// - Use proper hex encoding per RFC 4648 Section 8
    ///
    /// ## Example
    ///
    /// ```swift
    /// let boundary = RFC_2046.Boundary.random()
    /// // Result: ----=_Part_a3f5d8b2c1e4f6a7b9d0c2e5f8a1b3d4
    /// ```
    ///
    /// ## RFC References
    ///
    /// - RFC 2046 Section 5.1.1: Boundary delimiter requirements
    /// - RFC 4648 Section 8: Base 16 (hex) encoding
    public static func random() -> Self {
        let randomBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        let hexBytes = RFC_4648.Hex.encode(randomBytes, uppercase: false)
        let hex = String(decoding: hexBytes, as: UTF8.self)
        return try! Self("----=_Part_\(hex)")
    }
}
