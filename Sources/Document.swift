//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 19-05-16.
//
//

import Foundation

public protocol __DocumentProtocolForArrayAdditions {
    var bytes: [UInt8] { get }
    init(data: [UInt8])
    func validate() -> Bool
}
extension Document : __DocumentProtocolForArrayAdditions {}

extension Array where Element : __DocumentProtocolForArrayAdditions {
    /// The combined data for all documents in the array
    public var bytes: [UInt8] {
        return self.map { $0.bytes }.reduce([], +)
    }
    
    public init(bsonBytes data: Data, validating: Bool = false) {
        var buffer = [UInt8](repeating: 0, count:  data.count)
        
        data.copyBytes(to: &buffer, count: buffer.count)
        
        self.init(bsonBytes: buffer, validating: validating)
    }
    
    public init(bsonBytes bytes: [UInt8], validating: Bool = false) {
        var array = [Element]()
        var position = 0
        
        documentLoop: while bytes.count >= position + 5 {
            
            guard let length = try? Int(fromBytes(bytes[position..<position+4]) as Int32) else {
                // invalid
                break
            }
            
            guard length > 0 else {
                // invalid
                break
            }
            
            guard bytes.count >= position + length else {
                break documentLoop
            }
            
            let document = Element(data: [UInt8](bytes[position..<position+length]))
            
            if validating {
                if document.validate() {
                    array.append(document)
                }
            } else {
                array.append(document)
            }
            
            position += length
        }
        
        self = array
    }
}

public enum ElementType : UInt8 {
    case double = 0x01
    case string = 0x02
    case document = 0x03
    case arrayDocument = 0x04
    case binary = 0x05
    case objectId = 0x07
    case boolean = 0x08
    case utcDateTime = 0x09
    case nullValue = 0x0A
    case regex = 0x0B
    case javascriptCode = 0x0D
    case javascriptCodeWithScope = 0x0F
    case int32 = 0x10
    case timestamp = 0x11
    case int64 = 0x12
    case minKey = 0xFF
    case maxKey = 0x7F
}

/// `Document` is a collection type that uses a BSON document as storage.
/// As such, it can be stored in a file or instantiated from BSON data.
///
/// Documents behave partially like an array, and partially like a dictionary.
/// For general information about BSON documents, see http://bsonspec.org/spec.html
public struct Document : Collection, ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral {
    internal var storage: [UInt8]
    internal var _count: Int? = nil
    internal var invalid = false
    internal var elementPositions = [Int]()
    internal var isArray: Bool = false
    
    // MARK: - Initialization from data
    
    /// Initializes this Doucment with binary `Foundation.Data`
    ///
    /// - parameters data: the `Foundation.Data` that's being used to initialize this`Document`
    public init(data: Foundation.Data) {
        var byteArray = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &byteArray, count: byteArray.count)
        
        self.init(data: byteArray)
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: [UInt8]) {
        guard let length = try? Int(fromBytes(data[0...3]) as Int32), length <= data.count, data.last == 0x00 else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Array(data[0..<Swift.max(length - 1, 0)])
        elementPositions = buildElementPositionsCache()
        isArray = validatesAsArray()
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: ArraySlice<UInt8>) {
        guard let length = try? Int(fromBytes(data[0...3]) as Int32), length < data.count else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Array(data[0..<length])
        elementPositions = buildElementPositionsCache()
        isArray = self.validatesAsArray()
    }
    
    /// Initializes an empty `Document`
    public init() {
        // the empty document is 5 bytes long.
        storage = [5,0,0,0]
    }
    
    // MARK: - Initialization from Swift Types & Literals
    
    /// Initializes this `Document` as a `Dictionary` using an existing Swift `Dictionary`
    ///
    /// - parameter elements: The `Dictionary`'s generics used to initialize this must be a `String` key and `Value` for the value
    public init(dictionaryElements elements: [(String, Value)]) {
        storage = [5,0,0,0]
        
        for (key, value) in elements {
            // Append the key-value pair
            
            // Add element to positions cache
            elementPositions.append(storage.endIndex)
            
            // Type identifier
            storage.append(value.typeIdentifier)
            // Key
            storage.append(contentsOf: key.utf8)
            // Key null terminator
            storage.append(0x00)
            // Value
            storage.append(contentsOf: value.bytes)
        }
        
        updateDocumentHeader()
        
        isArray = false
    }
    
    /// Initializes this `Document` as a `Dictionary` using a `Dictionary` literal
    ///
    /// - parameter elements: The `Dictionary` used to initialize this must use `String` for key and `Value` for values
    public init(dictionaryLiteral elements: (String, Value)...) {
        self.init(dictionaryElements: elements)
    }
    
    /// Initializes this `Document` as an `Array` using an `Array` literal
    ///
    /// - parameter elements: The `Array` literal used to initialize the `Document` must be a `[Value]`
    public init(arrayLiteral elements: Value...) {
        self.init(array: elements)
    }
    
    /// Initializes this `Document` as an `Array` using an `Array`
    ///
    /// - parameter elements: The `Array` used to initialize the `Document` must be a `[Value]`
    public init(array elements: [Value]) {
        storage = [5,0,0,0]
        
        for (index, value) in elements.enumerated() {
            // Append the values
            
            // Add element to positions cache
            elementPositions.append(storage.endIndex)
            
            // Type identifier
            storage.append(value.typeIdentifier)
            // Key
            storage.append(contentsOf: "\(index)".utf8)
            // Key null terminator
            storage.append(0x00)
            // Value
            storage.append(contentsOf: value.bytes)
        }
        
        updateDocumentHeader()
        
        isArray = true
    }
    
    // MARK: - Manipulation & Extracting values
    
    public typealias Index = DocumentIndex
    public typealias IndexIterationElement = (key: String, value: Value)
    
    /// Appends a Key-Value pair to this `Document` where this `Document` acts like a `Dictionary`
    ///
    /// TODO: Analyze what should happen with `Array`-like documents and this function
    /// TODO: Analyze what happens when you append with a duplicate key
    ///
    /// - parameter value: The `Value` to append
    /// - parameter key: The key in the key-value pair
    public mutating func append(_ value: Value, forKey key: String) {
        // We're going to insert the element before the Document null terminator
        elementPositions.append(storage.endIndex)
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.bytes)
        
        // Increase the bytecount
        updateDocumentHeader()
        
        isArray = false
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Value) {
        let key = "\(self.count)"
        
        // We're going to insert the element before the Document null terminator
        elementPositions.append(storage.endIndex)
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.bytes)
        
        // Increase the bytecount
        updateDocumentHeader()
    }
    
    /// Appends the convents of `otherDocument` to `self` overwriting any keys in `self` with the `otherDocument` equivalent in the case of duplicates
    public mutating func append(contentsOf otherDocument: Document) {
        if self.validatesAsArray() && otherDocument.validatesAsArray() {
            self = Document(array: self.arrayValue + otherDocument.arrayValue)
        } else {
            self += otherDocument
        }
    }
    
    /// Updates this `Document`'s storage to contain the proper `Document` length header
    internal mutating func updateDocumentHeader() {
        // One extra byte for the missing null terminator in the storage
        var count = Int32(storage.count + 1)
        memcpy(&storage, &count, 4)
    }
    
    // MARK: - Collection
    
    /// The first `Index` in this `Document`. Can point to nothing when the `Document` is empty
    public var startIndex: DocumentIndex {
        return DocumentIndex(byteIndex: 4)
    }
    
    /// The last `Index` in this `Document`. Can point to nothing whent he `Document` is empty
    public var endIndex: DocumentIndex {
        var thisIndex = 4
        for element in self.makeKeyIterator() {
            thisIndex = element.startPosition
        }
        return DocumentIndex(byteIndex: thisIndex)
    }
    
    /// Creates an iterator that iterates over all key-value pairs
    public func makeIterator() -> AnyIterator<IndexIterationElement> {
        let keys = self.makeKeyIterator()
        
        return AnyIterator {
            guard let key = keys.next() else {
                return nil
            }

            guard let string = String(bytes: key.keyData[0..<key.keyData.endIndex-1], encoding: String.Encoding.utf8) else {
                return nil
            }
            
            let value = self.getValue(atDataPosition: key.dataPosition, withType: key.type)
            
            return IndexIterationElement(key: string, value: value)
        }
    }
    
    /// Fetches the next index
    ///
    /// - parameter i: The `Index` to advance
    public func index(after i: DocumentIndex) -> DocumentIndex {
        var position = i.byteIndex
        
        guard let type = ElementType(rawValue: storage[position]) else {
            fatalError("Invalid type found in Document when finding the next key at position \(position)")
        }
        
        position += 1
        
        while storage[position] != 0 {
            position += 1
        }
        
        position += 1
        
        let length = getLengthOfElement(withDataPosition: position, type: type)
        
        // Return the position of the byte after the value
        return DocumentIndex(byteIndex: position + length)
    }
    
    /// Finds the key-value pair for the given key and removes it
    ///
    /// - parameter key: The `key` in the key-value pair to remove
    ///
    /// - returns: The `Value` in the pair if there was any
    @discardableResult public mutating func removeValue(forKey key: String) -> Value? {
        guard let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) else {
            return nil
        }
        
        let val = getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        let length = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        guard meta.dataPosition + length <= storage.count else {
            return nil
        }
        
        storage.removeSubrange(meta.elementTypePosition..<meta.dataPosition + length)
        
        let removedLength = (meta.dataPosition + length) - meta.elementTypePosition
        
        for (index, element) in elementPositions.enumerated() where element > meta.elementTypePosition {
            elementPositions[index] = elementPositions[index] - removedLength
        }
        
        if let index = elementPositions.index(of: meta.elementTypePosition) {
            elementPositions.remove(at: index)
        }
        
        updateDocumentHeader()
        
        return val
    }
    
    // MARK: - Files
    
    /// Writes this `Document` to a file. Usually for debugging purposes
    ///
    /// - parameter path: The path to write this to
    public func write(toFile path: String) throws {
        var myData = storage
        let nsData = NSData(bytes: &myData, length: myData.count)
        
        try nsData.write(toFile: path)
    }
}

public struct DocumentIndex : Comparable {
    // The byte index is the very start of the element, the element type
    internal var byteIndex: Int
    
    internal init(byteIndex: Int) {
        self.byteIndex = byteIndex
    }
    
    public static func ==(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
        return lhs.byteIndex == rhs.byteIndex
    }
    
    public static func <(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
        return lhs.byteIndex < rhs.byteIndex
    }
}

extension Sequence where Iterator.Element == Document {
    /// Converts a sequence of Documents to an array of documents in BSON format
    public func makeDocument() -> Document {
        var combination = [] as Document
        for doc in self {
            combination.append(~doc)
        }
        
        return combination
    }
}

