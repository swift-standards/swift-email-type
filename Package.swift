// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-email-standard",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Email Standard",
            targets: ["Email Standard"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-emailaddress-standard", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "Email Standard",
            dependencies: [
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC_4648", package: "swift-rfc-4648"),
                .product(name: "RFC_5322", package: "swift-rfc-5322")
            ]
        ),
        .testTarget(
            name: "Email Standard Tests",
            dependencies: ["Email Standard"]
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
