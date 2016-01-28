//
// Created by joannis on 27-1-16.
//

import PackageDescription

let package = Package(name: "BSON",
    exclude: ["Carthage"],
    dependencies: [
        .Package(url: "https://github.com/oisdk/SwiftSequence", majorVersion: 1)
    ],
    targets: [
        Target(name: "BSON"),
        Target(name: "BSONTests",
            dependencies: [.Target(name: "BSON")])
    ]
)

