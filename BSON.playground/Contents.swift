import BSON

//: ## Basic Usage
//: You can create a `Document` using the Dictionary or Array literal.
//: Documents behave a lot like Swift's `Dictionary` and `Array` types.
//: Note that unlike dictionaries, documents have a fixed order for their key/value pairs. Key/value pairs are stored, iterated over and searched in the order they are inserted.
// Create a document using a dictionary literal
var document: Document = [
    "hello": "I am a BSON document",
    "temperature": 42.5
]

// Retreive the BSON data, ready for storing or sending over the network
let data = document.bytes // Array of [UInt8]

// Initialize a document using data ([UInt8])
let sameDocument = Document(data: data)

// Do something with the data
let temperature = document["temperature"].double

// Use the temperature

//: ## Embedded Documents and Arrays
//: You can embed documents in each other.
//: Documents can also take the form of arrays.
document = [
    "subdocument": ["hello": "sample"],
    "anothersubdocument": [81.2, "cheese"] // an array is also an embedded document
]

//: ## Comparing Documents
//: Use the `==` operator to check if the underlying value of two BSON values are equivalent. Use the `===` operator to also check if they have the same type.
//: The following example shows the difference between the two operators.
document = [
    "double": 200.0,
    "int64": 200
]

document["double"] == document["int64"]
document["double"] === document["int64"]

//: ## Iterating over Documents
//: You can use normal for loops to iterate over documents, like you would with a `Dictionary`.

for (key, value) in document {
    print("The value for the key \(key) is \(value)")
}

//: ## Various Mutations
// Append the given key/value pair at the end of the document.
document.append("example.com", forKey: "website")

//: ## Validation
//: For performance reasons, documents are not automatically validated after they have been initialized.
//: If you wish to check the validity of a `Document`, use the validate method:

document.validate()
