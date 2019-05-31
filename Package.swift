// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "BSON",
    products: [
        .library(
            name: "BSON",
            targets: ["BSON"])
        ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "BSON",
            dependencies: ["NIO"]
        ),
        .testTarget(
            name: "BSONTests",
            dependencies: ["BSON"])
        ],
    swiftLanguageVersions: [.v4_2]
)
