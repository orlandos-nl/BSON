//
// Created by joannis on 27-1-16.
//

import PackageDescription

let package = Package(name: "BSON",
        targets: [
                Target(name: "BSON"),
                Target(name: "BSONTests",
                        dependencies: [.Target(name: "BSON")])
        ]
)

