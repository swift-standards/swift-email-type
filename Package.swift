// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-email-type",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Email Type",
            targets: ["Email Type"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-emailaddress-type", from: "0.2.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Email Type",
            dependencies: [
                .product(name: "EmailAddress", package: "swift-emailaddress-type"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC_5322", package: "swift-rfc-5322")
            ]
        ),
        .testTarget(
            name: "Email Type Tests",
            dependencies: ["Email Type"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
