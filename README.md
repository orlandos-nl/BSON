# BSON

A native BSON library for Swift, written in Swift.

BSON is parsed and generated as specified for version 1.0 (http://bsonspec.org/spec.html).

### Usage

You can use this library trough Carthage, git submodules or the Swift Package Manager (currently Linux-only).

The project contains a tutorial playground. That's probably the best way to learn!

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


### Requirements

We support the Swift Development Snapshot 2016-03-01-a currently. Other versions of swift may or may not work.
