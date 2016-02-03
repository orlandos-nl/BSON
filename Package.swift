//
// Created by joannis on 27-1-16.
//

import PackageDescription

let package = Package(name: "BSON",
    exclude: [],
    dependencies: [],
    targets: [
        Target(name: "BSON"),
        Target(name: "Tests",
            dependencies: [.Target(name: "BSON")])
    ]
)

