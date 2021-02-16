// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SyntaxKit",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13)],
    products: [
        .library(
            name: "SyntaxKit",
            targets: ["SyntaxKit"]
        ),
    ],
    targets: [
        .target(
            name: "SyntaxKit"
        )
    ]
)
