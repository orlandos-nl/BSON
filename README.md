# BSON

[![Swift 3.1](https://img.shields.io/badge/swift-3.1-orange.svg)](https://swift.org)
![License](https://img.shields.io/github/license/openkitten/mongokitten.svg)
[![Build Status](https://api.travis-ci.org/OpenKitten/BSON.svg?branch=bson5)](https://travis-ci.org/OpenKitten/BSON)

BSON 5 is the fastest BSON library speeding past all libraries including C. It's compliant to the whole C BSON specification test suite, and even passes official libraries in compliance slightly.
 
It's not only fast, it's also got an extremely easy and intuitive API for extraction.

BSON is parsed and generated as specified for version 1.1 of the [BSON specification](http://bsonspec.org/spec.html).

## Usage

The supported method for using this library is trough the Swift Package manager, like this:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [.Package(url: "https://github.com/OpenKitten/BSON.git", majorVersion: 5)]
)
```

Create Documents naturally:

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

Check the [documentation](http://docs.openkitten.org/bson/) for more information.

## Performance

The performance in this BSON library is thanks to specialized algorithms per-operation with a centralized cache for indexed information. BSON is 100% lazy, so if you don't read data, it doesn't cost *any* performance.

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
