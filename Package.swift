// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RestedM",
    platforms: [.macOS("27.0")],
    targets: [
        .target(name: "RestedCore"),
        .executableTarget(name: "RestedM", dependencies: ["RestedCore"]),
        .testTarget(name: "RestedCoreTests", dependencies: ["RestedCore"]),
    ],
    swiftLanguageModes: [.v5]
)
