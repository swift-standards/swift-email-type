import Testing

@testable import Email_Standard

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Example from README: Simple HTML Email")
    func exampleSimpleHTMLEmail() throws {
        // From README line 36-44
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Welcome!",
            html: "<h1>Welcome to our service!</h1>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        )

        #expect(email.to.count == 1)
        #expect(email.from.address == "sender@example.com")
        #expect(email.subject == "Welcome!")
    }

    @Test("Example from README: Plain Text Email")
    func examplePlainTextEmail() throws {
        // From README line 49-56
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Hello",
            text: "Hello, World!",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        )

        #expect(email.subject == "Hello")
        #expect(email.body.content.contains("Hello, World!"))
    }

    @Test("Example from README: Email with Text and HTML Alternatives")
    func exampleTextAndHTMLAlternatives() throws {
        // From README line 60-68
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Newsletter",
            text: "Plain text version of newsletter",
            html: "<h1>HTML version</h1><p>Newsletter content...</p>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        )

        #expect(email.subject == "Newsletter")
        #expect(email.body.content.contains("Plain text version"))
        #expect(email.body.content.contains("<h1>HTML version</h1>"))
    }

    @Test("Example from README: Email with Custom Headers")
    func exampleCustomHeaders() throws {
        // From README line 88-99
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Tracked Email",
            html: "<h1>Hello!</h1>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            additionalHeaders: [
                .init(name: "X-Campaign-ID", value: "newsletter-2024"),
                .init(name: "X-Mailer", value: "MyApp 1.0"),
            ]
        )

        #expect(email.additionalHeaders["X-Campaign-ID"] == "newsletter-2024")
        #expect(email.additionalHeaders["X-Mailer"] == "MyApp 1.0")
    }
}
