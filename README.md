# BSON 5.0 - Work in Progress

This branch contains working code for BSON 5.0. Nothing here is final and everything may change. BSON 5.0 does not have a release schedule yet, but will be released alongside MongoKitten 4.0.

# BSON

[![Swift 3.1](https://img.shields.io/badge/swift-3.1-orange.svg)](https://swift.org)
![License](https://img.shields.io/github/license/openkitten/mongokitten.svg)
[![Build Status](https://api.travis-ci.org/OpenKitten/BSON.svg?branch=bson4)](https://travis-ci.org/OpenKitten/BSON)


A native, fast BSON library for Swift, written in Swift.

BSON is parsed and generated as specified for version 1.1 of the [BSON specification](http://bsonspec.org/spec.html).

## Usage

The supported method for using this library is trough the Swift Package manager, like this:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [.Package(url: "https://github.com/OpenKitten/BSON.git", majorVersion: 4)]
)
```

Check the [documentation](http://docs.openkitten.org/bson/) for more information.

### Supported Types

All non-deprecated BSON 1.1 types are supported.

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
- Decimal128

### Supported features

- ISO8601 for Extended JSON Dates
- **Really** fast BSON Parsing and Serializing