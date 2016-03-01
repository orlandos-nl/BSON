//: # BSON
//:
//: Welcome to BSON! BSON, short for Binary JSON, is a binary-encoded serialization of JSON-like documents. Like JSON, BSON supports the embedding of documents and arrays within other documents and arrays. For more information about BSON, visit the [website](http://bsonspec.org).
//:
//: This playground will walk you trough the basic and some of the more advanced usage of the BSON library.
//: 
//: Of course, we start by importing BSON:
import BSON
//: You can create documents by assigning a dictionary or array literal to a variable of the `Document` type.
let document: Document = [
    "hello": "I am a BSON document",
    "temperature": 42.5
]
//: The raw BSON data of a document can be retreived using the `bsonData` property. This is an array of UInt8.
let data = document.bsonData
//: We can initialize another document using this data
let sameDocument = try! Document(data: data)
//: `Document` has all the properties and functions you would expect from a collection:
let count = sameDocument.count

for (key, value) in sameDocument {
    print("The value for \(key) is \(value)")
}   

if let text = document["hello"] as? String {
    // do something with the error here
    print("The string is: \(text)")
}
//: The following types are supported:
var anotherDocument: Document = [
    "double": 53.2,
    "64bit-integer": 52,
    "32bit-integer": Int32(20),
    "embedded-document": *["double": 44.3, "_id": ObjectId()],
    "embedded-array": *[44, 33, 22, 11, 10, 9],
    "identifier": ObjectId(),
    "datetime": NSDate(),
    "bool": false,
    "null": Null(),
    "binary": Binary(data: [0x01, 0x02]),
    "string": "Hello, I'm a string!"
]
//: As you can see, to embed an array or document (dictionary) in a document, you must prefix the declaration with the *-operator. This is needed for the compiler to infer the type of the declaration.
