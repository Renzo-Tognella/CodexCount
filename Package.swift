// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodexCount",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "CodexCount",
            path: "Sources/CodexCount"
        )
    ]
)
