// swift-tools-version:5.5

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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "BSON",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
        .testTarget(
            name: "BSONTests",
            dependencies: ["BSON"])
        ],
    swiftLanguageVersions: [.v4_2]
)
