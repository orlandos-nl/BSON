# BSON

[![Swift 5.8](https://img.shields.io/badge/swift-5.8-green.svg)](https://swift.org/download)
![License](https://img.shields.io/github/license/openkitten/mongokitten.svg)

A fast BSON library, compliant to the whole BSON specification test suite. The library parses the binary data on-demand, delaying copies until the last second.

BSON is parsed and generated as specified for version 1.1 of the [BSON specification](http://bsonspec.org/spec.html).

Be sure to read our [full documentation](https://orlandos.nl/docs/mongokitten/articles/bson) and [API reference](https://swiftinit.org/reference/bson).

## Installation

BSON uses the Swift Package Manager. Add BSON to your dependencies in your Package.swift file:

```swift
.package(url: "https://github.com/orlandos-nl/BSON.git", from: "8.0.0")
```

Also, don't forget to add "BSON" as a dependency for your target.

## Basic Usage

Create Documents using Dictionary Literals:

```swift
var userDocument: Document = [
	"username": "Joannis",
	"online": true,
	"age": 20,
	"pi_constant": 3.14,
	"profile": [
		"firstName": "Joannis",
		"lastName": "Orlandos"
	]
]

let favouriteNumbers: Document = [1, 3, 7, 14, 21, 24, 34]

userDocument["favouriteNumbers"] = favouriteNumbers
```

Access values in an array like you would in Swift Arrays and values in an object like a Dictionary.

```swift
let favouriteNumber = favouriteNumbers[0]
let usernameValue = userDocument["username"]
```

Extract types with simplicity:

```swift
let username = String(userDocument["username"]) // "Joannis"
let isOnline = Bool(userDocument["online"]) // true
let age = Int(userDocument["age"]) // 20
let pi = Double(userDocument["pi_constant"]) // 3.14
```

Chain subscripts easily to find results without a hassle as shown underneath using this JSON structure (assuming this is represented in BSON):

```json
{
  "users": [
  	{
  		"username": "Joannis",
  		"profile": {
  		  "firstName": "Joannis",
  		  "lastName": "Orlandos"
  		}
  	},
  	{
  		"username": "Obbut",
  		"profile": {
  		  "firstName": "Robbert",
  		  "lastName": "Brandsma"
  		}
  	}
  ]
}
```

```swift
let obbutLastName = String(object["users"][1]["profile"]["lastName"]) // "Brandsma"
```

### Nested Documents

Complex array and dictionary literals may confuse the Swift type system. If this happens to you, make the literal explicitly a `Document` type:

```swift
var userDocument: Document = [
	"username": "Joannis",
	"online": true,
	"age": 20,
	"pi_constant": 3.14,
	"profile": [
		"firstName": "Joannis",
		"lastName": "Orlandos",
		"pets": [
			[
				"name": "Noodles",
				"type": "Parrot"
			] as Document,
			[
				"name": "Witje",
				"type": "Rabbit"
			]
		] as Document
	] as Document
]
```

### Codable

Document can be instantiated from [SwiftNIO](https://github.com/apple/swift-nio)'s `ByteBuffer` or `Foundation.Data`.
You can validate the formatting of this document manually using the `.validate()` function. This will also specify where the data was found corrupt.

If you pass a `Document` or `Primitive` into the `BSONDecoder` you can decode any `Decodable` type if the formats match. Likewise, `BSONEncoder` can encode your Swift types into a `Document`.

## Supported Types

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
