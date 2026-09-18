// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LightweightChat",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown", from: "0.7.0"),
        .package(url: "https://github.com/raspu/Highlightr", from: "2.1.0")
    ],
    targets: [
        .executableTarget(
            name: "LightweightChat",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Highlightr", package: "Highlightr")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LightweightChatTests",
            dependencies: [
                .target(name: "LightweightChat")
            ],
            path: "Tests"
        )
    ]
)
