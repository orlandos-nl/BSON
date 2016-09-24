# BSON

[![Build Status](https://travis-ci.org/OpenKitten/BSON.svg?branch=master)](https://travis-ci.org/PlanTeam/BSON)
[![Swift Version](https://img.shields.io/badge/swift-3.0-orange.svg)](https://swift.org)
![License](https://img.shields.io/github/license/planteam/bson.svg)


A native, fast BSON library for Swift, written in Swift.

BSON is parsed and generated as specified for version 1.0 of the [BSON specification](http://bsonspec.org/spec.html).

### Compatibility

##### Operating systems
All versions starting with BSON 1.3 are compatible with OS X and Ubuntu 15.10. Other operating systems may work but are untested.

##### Swift Version
We support the Swift version specified in .swift_version, which most of the time is the latest version of Swift when a version is released.

For every new Swift snapshot we release a new minor version.

### Usage

The supported method for using this library is trough the Swift Package manager, like this:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [.Package(url: "https://github.com/OpenKitten/BSON.git", majorVersion: 3, minor: 7)]
)
```

Check the [documentation](https://openkitten.github.io/BSON/) for more information.

#### Basic Usage

```swift
// Create a document using a dictionary literal
let document: Document = [
            "hello": "I am a BSON document",
            "temperature": 42.5
        ]

// Retreive the BSON data, ready for storing or sending over the network
let data = document.bsonData // Array of [UInt8]

// Initialize a document using a [UInt8]
let sameDocument = try! Document(data: data)

// Do something with the data
let temperature = document["temperature"].double

// Use the temperature
```

#### Embedded documents

```swift
let document: Document = [
            "subdocument": ["hello": "sample"],
            "anothersubdocument": [81.2, "cheese"] // an array is also an embedded document
        ]
```

#### Comparing

```swift
document["double"] == document["int64"] // true for .double(0) == .int64(0)
document["double"] === document["int64"] // false for .double(0) === .int64(0)
```

### Supported Types

All non-deprecated BSON 1.0 types are supported.

- Double
- String
- Document
- Array
- ObjectId
- Bool
- DateTime
- 32-bit integer
- 64-bit integer
- Null value
- Binary
- Regular Expression
- Min Key
- Max Key
- Timestamp
- Javascript Code
- Javascript Code with Scope

### Supported features

- MongoDB Extended JSON
- ISO8601 for Extended JSON Dates
- **Really** fast BSON Parsing and Serializing
