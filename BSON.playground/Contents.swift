import BSON

//: ## Basic Usage
//: You can create a `Document` using the Dictionary or Array literal.
//: Documents behave a lot like Swift's `Dictionary` and `Array` types.
//: Note that unlike dictionaries, documents have a fixed order for their key/value pairs. Key/value pairs are stored, iterated over and searched in the order they are inserted.
// Create a document using a dictionary literal
var document: Document = [
    "hello": "I am a BSON document",
    "temperature": 444.4
]

document["temperature"]["kaas"]["sap"] = 6

Int(document["temperature"]["kaas"]["sap"])