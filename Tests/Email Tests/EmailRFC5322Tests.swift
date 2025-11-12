//
//  EmailRFC5322Tests.swift
//  swift-email-type
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import EmailAddress
import Foundation
import RFC_5322
import Testing
@testable import Email

@Suite("Email to RFC 5322 Message Conversion")
struct EmailRFC5322Tests {

    @Test("Convert simple text email to RFC 5322 Message")
    func convertSimpleTextEmail() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test Email",
            body: "Hello, World!"  // ExpressibleByStringLiteral
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.from.addressValue == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.to[0].addressValue == "recipient@example.com")
        #expect(message.subject == "Test Email")
        #expect(message.bodyString == "Hello, World!")

        let rendered = message.render()
        #expect(rendered.contains("From: sender@example.com"))
        #expect(rendered.contains("To: recipient@example.com"))
        #expect(rendered.contains("Subject: Test Email"))
        #expect(rendered.contains("Hello, World!"))
    }

    @Test("Convert HTML email to RFC 5322 Message")
    func convertHTMLEmail() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "HTML Test",
            body: .html("<h1>Hello, World!</h1>")
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.bodyString?.contains("<h1>Hello, World!</h1>") == true)

        let rendered = message.render()
        #expect(rendered.contains("Content-Type: text/html"))
        #expect(rendered.contains("<h1>Hello, World!</h1>"))
    }

    @Test("Convert multipart email to RFC 5322 Message")
    func convertMultipartEmail() throws {
        let multipart = try RFC_2046.Multipart.alternative(
            textContent: "Plain text version",
            htmlContent: "<p>HTML version</p>"
        )

        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Multipart Test",
            body: .multipart(multipart)
        )

        let message = try RFC_5322.Message(from: email)

        let rendered = message.render()
        #expect(rendered.contains("Content-Type: multipart/alternative"))
        #expect(rendered.contains("Plain text version"))
        #expect(rendered.contains("<p>HTML version</p>"))
    }

    @Test("Convert email with CC and Reply-To")
    func convertEmailWithCCAndReplyTo() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            replyTo: EmailAddress("reply@example.com"),
            cc: [EmailAddress("cc@example.com")],
            subject: "Test with CC",
            body: "Test body"
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.replyTo?.addressValue == "reply@example.com")
        #expect(message.cc?.count == 1)
        #expect(message.cc?[0].addressValue == "cc@example.com")

        let rendered = message.render()
        #expect(rendered.contains("Reply-To: reply@example.com"))
        #expect(rendered.contains("Cc: cc@example.com"))
    }

    @Test("Convert email with custom headers")
    func convertEmailWithCustomHeaders() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test",
            additionalHeaders: [
                .init(name: "X-Custom-Header", value: "custom-value"),
                .init(name: "X-Priority", value: "1")
            ]
        )

        let message = try RFC_5322.Message(from: email)

        let rendered = message.render()
        #expect(rendered.contains("X-Custom-Header: custom-value"))
        #expect(rendered.contains("X-Priority: 1"))
    }

    @Test("Message-ID is generated if not provided")
    func messageIdGeneration() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test"
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.messageId.hasPrefix("<"))
        #expect(message.messageId.hasSuffix("@example.com>"))
        #expect(message.messageId.contains("@"))
    }

    @Test("Can write message to .eml file")
    func writeToEmlFile() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test Email",
            body: "Hello, World!"
        )

        let message = try RFC_5322.Message(from: email)
        let emlContent = message.render()

        // Verify .eml format
        #expect(emlContent.contains("From: "))
        #expect(emlContent.contains("To: "))
        #expect(emlContent.contains("Subject: "))
        #expect(emlContent.contains("Date: "))
        #expect(emlContent.contains("Message-ID: "))
        #expect(emlContent.contains("\r\n\r\n")) // Headers/body separator
    }
}
