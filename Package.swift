// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MPKCodexBridge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MPKCodexBridge",
            targets: ["MPKCodexBridge"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MPKCodexBridge",
            path: "Sources/MPKCodexBridge"
        )
    ]
)
