# BSON

A native BSON library for Swift, written in Swift.

BSON is parsed and generated as specified for version 1.0 (http://bsonspec.org/spec.html).

### Usage

You can use this library trough Carthage, git submodules or the Swift Package Manager (currently Linux-only).

All usage is covered by the unit tests.

### Supported Types

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

The following types are not implemented yet:

- Regular Expression
- Javascript Code
- Javascript Code with Scope
- Timestamp
- Min key
- Max key