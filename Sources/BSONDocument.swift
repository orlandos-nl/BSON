import Foundation

public struct BSONDocument: ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral, ValueConvertible, Swift.Collection, Equatable, __DocumentProtocolForArrayAdditions {
    public var rawDocument: Document
    
    public init(data: [UInt8]) {
        rawDocument = Document(data: data)
    }
    
    public init(data: Foundation.Data) {
        rawDocument = Document(data: data)
    }

    public init(data: ArraySlice<UInt8>) {
        rawDocument = Document(data: data)
    }
    
    public init() {
        rawDocument = Document()
    }
    
    public func makeBsonValue() -> BSON.Value {
        return rawDocument.makeBsonValue()
    }
    
    public init(dictionaryLiteral elements: (String, ValueConvertible)...) {
        self.rawDocument = BSON.Document(dictionaryElements: elements.map { ($0.0, $0.1.makeBsonValue()) })
    }
    
    public init(arrayLiteral elements: ValueConvertible...) {
        self.rawDocument = BSON.Document(array: elements.map { $0.makeBsonValue() })
    }
    
    public init(_ document: Document) {
        self.rawDocument = document
    }
    
    public subscript(key: String) -> ValueConvertible? {
        get {
            return rawDocument[key].rawValue
        }
        set {
            rawDocument[key] = newValue?.makeBsonValue() ?? BSON.Value.nothing
        }
    }
    
    public subscript(parts: String...) -> ValueConvertible? {
        get {
            return rawDocument[parts].rawValue
        }
        set {
            rawDocument[parts] = newValue?.makeBsonValue() ?? BSON.Value.nothing
        }
    }
    
    public subscript(parts: [String]) -> ValueConvertible? {
        get {
            return rawDocument[parts].rawValue
        }
        set {
            rawDocument[parts] = newValue?.makeBsonValue() ?? BSON.Value.nothing
        }
    }
    
    public subscript(key: Int) -> ValueConvertible? {
        get {
            return rawDocument[key].rawValue
        }
        set {
            rawDocument[key] = newValue?.makeBsonValue() ?? BSON.Value.nothing
        }
    }
    
    public subscript(position: DocumentIndex) -> BSON.Document.IndexIterationElement {
        get {
            return rawDocument[position]
        }
        set {
            rawDocument[position] = newValue
        }
    }
    
    /// The amount of key-value pairs in the `Document`
    public var count: Int {
        return rawDocument.count
    }
    
    /// The amount of `Byte`s in the `Document`
    public var byteCount: Int {
        return rawDocument.byteCount
    }
    
    /// The `Byte` `Array` (`[Byte]`) representation of this `Document`
    public var bytes: [UInt8] {
        return rawDocument.bytes
    }
    
    /// A list of all keys
    public var keys: [String] {
        return rawDocument.keys
    }
    
    /// The `Dictionary` representation of this `Document`
    public var dictionaryValue: [String: ValueConvertible] {
        var dictionary = [String: ValueConvertible]()
        
        for (key, value) in rawDocument.dictionaryValue {
            if let value = value.rawValue {
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
    
    /// The `Array` representation of this `Document`
    public var arrayValue: [ValueConvertible] {
        return rawDocument.arrayValue.flatMap {
            $0.rawValue
        }
    }
    
    /// Fetches the next index
    ///
    /// - parameter i: The `Index` to advance
    public func index(after i: DocumentIndex) -> DocumentIndex {
        return rawDocument.index(after: i)
    }
    
    /// Finds the key-value pair for the given key and removes it
    ///
    /// - parameter key: The `key` in the key-value pair to remove
    ///
    /// - returns: The `Value` in the pair if there was any
    @discardableResult public mutating func removeValue(forKey key: String) -> ValueConvertible? {
        return rawDocument.removeValue(forKey: key)?.rawValue
    }
    
    /// - returns: `true` when this `Document` is a valid BSON `Array`. `false` otherwise
    public func validatesAsArray() -> Bool {
        return rawDocument.validatesAsArray()
    }
    
    public func type(at key: Int) -> ElementType? {
        return rawDocument.type(at: key)
    }
    
    public func type(atKey key: String) -> ElementType? {
        return rawDocument.type(at: key)
    }
    
    public func validate() -> Bool {
        return self.rawDocument.validate()
    }
    
    public static func ==(lhs: BSONDocument, rhs: BSONDocument) -> Bool {
        return lhs.rawDocument == rhs.rawDocument
    }
    
    public static func +(lhs: BSONDocument, rhs: BSONDocument) -> BSONDocument {
        return BSONDocument(lhs.rawDocument + rhs.rawDocument)
    }
    
    public static func +=(lhs: inout BSONDocument, rhs: BSONDocument) {
        lhs.rawDocument += rhs.rawDocument
    }
    
    public mutating func flatten(skippingArrays skipArrays: Bool = false) {
        self.rawDocument.flatten()
    }
    
    public func flattened() -> BSONDocument {
        return BSONDocument(self.rawDocument.flattened())
    }
    
    /// Converts the `Document` to the [MongoDB extended JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/) format.
    /// The data is converted to MongoDB extended JSON in strict mode.
    ///
    /// - returns: The JSON string. Depending on the type of document, the top level object will either be an array or object.
    public func makeExtendedJSON() -> String {
        return rawDocument.makeExtendedJSON()
    }
    
    /// Initializes this `Document` as an `Array` using an `Array`
    ///
    /// - parameter elements: The `Array` used to initialize the `Document` must be a `[Value]`
    public init(array elements: [ValueConvertible]) {
        rawDocument = Document(array: elements.map { $0.makeBsonValue() })
    }
    
    public init(extendedJSON json: String) throws {
        rawDocument = try Document(extendedJSON: json)
    }
    
    /// Initializes this `Document` as a `Dictionary` using an existing Swift `Dictionary`
    ///
    /// - parameter elements: The `Dictionary`'s generics used to initialize this must be a `String` key and `Value` for the value
    public init(dictionaryElements elements: [(String, ValueConvertible)]) {
        rawDocument = Document(dictionaryElements: elements.map { ($0.0, $0.1.makeBsonValue()) })
    }
    
    /// Appends a Key-Value pair to this `Document` where this `Document` acts like a `Dictionary`
    ///
    /// TODO: Analyze what should happen with `Array`-like documents and this function
    /// TODO: Analyze what happens when you append with a duplicate key
    ///
    /// - parameter value: The `Value` to append
    /// - parameter key: The key in the key-value pair
    public mutating func append(_ value: ValueConvertible, forKey key: String) {
        rawDocument.append(value.makeBsonValue(), forKey: key)
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: ValueConvertible) {
        rawDocument.append(value.makeBsonValue())
    }
    
    /// Appends the convents of `otherDocument` to `self` overwriting any keys in `self` with the `otherDocument` equivalent in the case of duplicates
    public mutating func append(contentsOf otherDocument: BSONDocument) {
        rawDocument.append(contentsOf: otherDocument.rawDocument)
    }
    
    /// The first `Index` in this `Document`. Can point to nothing when the `Document` is empty
    public var startIndex: DocumentIndex {
        return rawDocument.startIndex
    }
    
    /// The last `Index` in this `Document`. Can point to nothing whent he `Document` is empty
    public var endIndex: DocumentIndex {
        return rawDocument.endIndex
    }
    
    public func makeIterator() -> AnyIterator<Document.IndexIterationElement> {
        return rawDocument.makeIterator()
    }
}
