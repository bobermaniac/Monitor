// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Monitor",
    platforms: [.macOS(.v10_12)],
    products: [
        .library(
            name: "Monitor",
            targets: ["Monitor"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Monitor",
            dependencies: [],
            path: "Monitor"),
        .testTarget(
            name: "MonitorTests",
            dependencies: ["Monitor"],
            path: "MonitorTests"),
    ]
)
