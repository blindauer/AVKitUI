// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AVKitUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AVKitUI",
            targets: ["AVKitUI"]
        )
    ],
    targets: [
        .target(
            name: "AVKitUI"
        ),
        .testTarget(
            name: "AVKitUITests",
            dependencies: ["AVKitUI"]
        )
    ]
)
