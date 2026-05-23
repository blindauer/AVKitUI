// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacAVPlayerBridge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacAVPlayerBridge",
            targets: ["MacAVPlayerBridge"]
        )
    ],
    targets: [
        .target(
            name: "MacAVPlayerBridge"
        ),
        .testTarget(
            name: "MacAVPlayerBridgeTests",
            dependencies: ["MacAVPlayerBridge"]
        )
    ]
)
