// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Blink",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "BlinkCore"),
        .executableTarget(name: "Blink", dependencies: ["BlinkCore"]),
        .testTarget(name: "BlinkCoreTests", dependencies: ["BlinkCore"]),
    ]
)
