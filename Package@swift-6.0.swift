// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "BSON",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BSON",
            targets: ["BSON"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.46.0")
    ],
    targets: [
        .target(
            name: "BSON",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete"),
            ]
        ),
        .testTarget(
            name: "BSONTests",
            dependencies: ["BSON"])
    ]
)
