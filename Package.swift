// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "BSON",
    products: [
        .library(
            name: "BSON",
            targets: ["BSON"])
        ],
    targets: [
        .target(
            name: "BSON"),
        .testTarget(
            name: "BSONTests",
            dependencies: ["BSON"]),
        ],
    swiftLanguageVersions: [.v4_2]
)
