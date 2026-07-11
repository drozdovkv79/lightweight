// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LightweightChat",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LightweightChat",
            path: "Sources"
        )
    ]
)
