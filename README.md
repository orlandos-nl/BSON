# BSON

A native BSON library for Swift, written in Swift.

BSON is parsed and generated as specified for version 1.0 of the [BSON specification](http://bsonspec.org/spec.html).

### Compatibility

##### Operating systems
All versions starting with BSON 1.3 are compatible with OS X and Ubuntu 15.10. Other operating systems may work but are untested.

##### Swift Version
We support the Swift version specified in .swift_version, which most of the time is the latest version of Swift when a version is released.

For every new Swift snapshot we release a new minor version.

### Usage

The supported method of using this library is trough the Swift Package manager, like this:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [.Package(url: "https://github.com/PlanTeam/BSON.git", majorVersion: 1, minor: 3)]
)
```

Check the [documentation](https://planteam.github.io/BSON/) for more information.

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
guard let temperature = document["temperature"] as? Double else {
	// do something with the error here
	abort()
}

// Use the temperature
```

#### Embedded documents

Due to the Swift compiler sometimes creating NSArray instances, use the `prefix operator *` with embedded documents.

```swift
let document: Document = [
            "subdocument": *["hello", "mother of god"],
            "anothersubdocument": *["key": 81.2] // an array is also an embedded document
        ]
```

Code not using this operator will compile, but the embedded documents won't be inserted in your document. A warning will be logged to the console.

### Comparing values

You can currently compare integers, doubles, booleans, and strings by using the ?== operator:

```swift
if document["key"] ?== 42.3 {

}
```

### Supported Types

All non-deprecated BSON 1.0 types are supported.

- Double (Swift.Double)
- String (Swift.String)
- Document (BSON.Document)
- Array (BSON.Document)
- ObjectId (BSON.ObjectId)
- Bool (Swift.Bool)
- DateTime (Foundation.NSDate)
- 32-bit integer (Swift.Int32)
- 64-bit integer (Swift.Int)
- Null value (BSON.Null)
- Binary (BSON.Binary)
- Regular Expression (BSON.RegularExpression)
- Min Key (BSON.MinKey)
- Max Key (BSON.MaxKey)
- Timestamp (BSON.Timestamp)
- Javascript Code (BSON.JavaScriptCode)
- Javascript Code with Scope (BSON.JavaScriptCode)