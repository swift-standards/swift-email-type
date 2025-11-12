# swift-email-type

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Type-safe email message representation built on RFC standards

## Overview

This package provides a Swift type for representing email messages. It's built on top of RFC standards (RFC 2045, RFC 2046, RFC 5322) and provides a clean, type-safe API for creating emails.

## Features

- ✅ Type-safe email construction
- ✅ RFC-compliant MIME multipart support
- ✅ Multiple recipient types (To, CC, BCC)
- ✅ Text, HTML, and multipart (text + HTML) bodies
- ✅ Custom header support
- ✅ Built on RFC standards (2045, 2046, 5322)
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` and `Codable` conformance

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-email-type", branch: "main")
]
```

## Usage

### Simple HTML Email

```swift
import Email

let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Welcome!",
    html: "<h1>Welcome to our service!</h1>"
)
```

### Plain Text Email

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Hello",
    text: "Hello, World!"
)
```

### Email with Text and HTML Alternatives

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Newsletter",
    text: "Plain text version of newsletter",
    html: "<h1>HTML version</h1><p>Newsletter content...</p>"
)
```

### Email with Multiple Recipients

```swift
let email = Email(
    to: [
        try EmailAddress("user1@example.com"),
        try EmailAddress("user2@example.com")
    ],
    from: try EmailAddress("sender@example.com"),
    cc: [try EmailAddress("manager@example.com")],
    bcc: [try EmailAddress("archive@example.com")],
    subject: "Team Update",
    body: .html("<h1>Important Update</h1>")
)
```

### Email with Custom Headers

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Tracked Email",
    html: "<h1>Hello!</h1>",
    headers: [
        "X-Campaign-ID": "newsletter-2024",
        "X-Mailer": "MyApp 1.0"
    ]
)
```

### Custom Multipart Messages

```swift
// Create custom multipart message
let multipart = RFC_2046.Multipart(
    subtype: .alternative,
    parts: [
        .init(
            contentType: .textPlainUTF8,
            content: "Plain text version"
        ),
        .init(
            contentType: .textHTMLUTF8,
            content: "<h1>HTML version</h1>"
        )
    ]
)

let email = Email(
    to: [try EmailAddress("recipient@example.com")],
    from: try EmailAddress("sender@example.com"),
    subject: "Custom Message",
    body: .multipart(multipart)
)
```

### Accessing Email Properties

```swift
// Headers including MIME headers
let headers = email.allHeaders
// ["Content-Type": "multipart/alternative; boundary=...", ...]

// Body content (rendered with MIME boundaries for multipart)
let content = email.body.content

// Individual properties
print(email.from.addressValue)    // "sender@example.com"
print(email.to.map(\.addressValue)) // ["recipient@example.com"]
print(email.subject)               // "Newsletter"
```

## Type Overview

### `Email`

The main email message type.

```swift
public struct Email: Hashable, Sendable, Codable {
    public let to: [EmailAddress]
    public let from: EmailAddress
    public let replyTo: EmailAddress?
    public let cc: [EmailAddress]?
    public let bcc: [EmailAddress]?
    public let subject: String
    public let body: Body
    public let headers: [String: String]

    public var allHeaders: [String: String]
}
```

### `Email.Body`

Email body content types.

```swift
public enum Body: Hashable, Sendable {
    case text(Data, charset: RFC_2045.Charset)
    case html(Data, charset: RFC_2045.Charset)
    case multipart(RFC_2046.Multipart)

    public var contentType: RFC_2045.ContentType
    public var transferEncoding: RFC_2045.ContentTransferEncoding?
    public var content: String
}
```

## Email Provider Integration

This type is designed to be provider-agnostic. Use it with email services like:

### Mailgun

```swift
extension Mailgun.Client {
    func send(_ email: Email) async throws {
        try await messages.send(
            from: email.from.addressValue,
            to: email.to.map(\.addressValue),
            cc: email.cc?.map(\.addressValue),
            bcc: email.bcc?.map(\.addressValue),
            subject: email.subject,
            html: email.body.content,
            headers: email.allHeaders
        )
    }
}
```

### SendGrid, AWS SES, etc.

Similar extension patterns can be used with any email provider API.

## RFC Standards

This package builds on these RFC standards:

- **RFC 2045** - MIME Part 1: Format of Internet Message Bodies (Content-Type, Content-Transfer-Encoding)
- **RFC 2046** - MIME Part 2: Media Types (multipart/alternative, multipart/mixed)
- **RFC 5322** - Internet Message Format (email address structure)

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## Related Packages

- [swift-emailaddress-type](https://github.com/coenttb/swift-emailaddress-type) - Email address validation and RFC compliance
- [swift-rfc-2045](https://github.com/coenttb/swift-rfc-2045) - MIME fundamentals
- [swift-rfc-2046](https://github.com/coenttb/swift-rfc-2046) - MIME multipart support
- [swift-subscriptions](https://github.com/coenttb/swift-subscriptions) - Subscription management with RFC 2369/8058 headers

## License

Licensed under Apache 2.0.

## Contributing

Contributions welcome! Please ensure:
- All tests pass
- Code follows existing style
- Type safety and RFC compliance maintained
