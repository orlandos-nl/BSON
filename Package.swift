// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "BSON",
    products: [
        .library(
            name: "BSON",
            targets: ["BSON"])
        ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .revision("master"))
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
