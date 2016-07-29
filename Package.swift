//
// Created by joannis on 27-1-16.
//

import PackageDescription

let package = Package(
    name: "BSON",
    dependencies: [
        .Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 10)
    ]
)
