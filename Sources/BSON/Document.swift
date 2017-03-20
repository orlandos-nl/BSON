//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 19-05-16.
//
//

import Foundation
import KittenCore

public typealias IndexIterationElement = (key: String, value: Primitive)

extension Array where Element == Document {
    /// The combined data for all documents in the array
    public var bytes: Bytes {
        return self.map { $0.bytes }.reduce([], +)
    }
    
    public init(bsonBytes data: Data, validating: Bool = false) {
        var buffer = Bytes(repeating: 0, count:  data.count)
        
        data.copyBytes(to: &buffer, count: buffer.count)
        
        self.init(bsonBytes: buffer, validating: validating)
    }
    
    public init(bsonBytes bytes: Bytes, validating: Bool = false) {
        var array = [Element]()
        var position = 0
        let byteCount = bytes.count
        
        documentLoop: while byteCount >= position + 5 {
            let length = Int(bytes[position..<position+4].makeInt32())
            
            guard length > 0 else {
                // invalid
                break
            }
            
            guard byteCount >= position + length else {
                break documentLoop
            }
            
            let document = Element(data: Bytes(bytes[position..<position+length]))
            
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

public enum ElementType : Byte {
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
    case decimal128 = 0x13
    case minKey = 0xFF
    case maxKey = 0x7F
}

/// `Document` is a collection type that uses a BSON document as storage.
/// As such, it can be stored in a file or instantiated from BSON data.
///
/// Documents behave partially like an array, and partially like a dictionary.
/// For general information about BSON documents, see http://bsonspec.org/spec.html
public struct Document : Collection, ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral {
    public typealias Key = String
    public typealias Value = Primitive?
    
    internal var storage: Bytes
    internal var _count: Int? = nil
    internal var invalid = false
    internal var searchTree = Dictionary<KittenBytes, Int>()
    internal var isArray: Bool = false
    
    internal func sortedTree() -> [(KittenBytes, Int)] {
        return searchTree.sorted(by: { lhs, rhs in
            return lhs.1 < rhs.1
        })
    }
    
    // MARK: - Initialization from data
    
    /// Initializes this Doucment with binary `Foundation.Data`
    ///
    /// - parameters data: the `Foundation.Data` that's being used to initialize this`Document`
    public init(data: Foundation.Data) {
        var byteArray = Bytes(repeating: 0, count: data.count)
        data.copyBytes(to: &byteArray, count: byteArray.count)
        
        self.init(data: byteArray)
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: Bytes) {
        guard data.count > 4 else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        let length = Int(data[0...3].makeInt32())
        
        guard length <= data.count, data.last == 0x00 else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Array(data[0..<Swift.max(length - 1, 0)])
        searchTree = buildElementPositionsCache()
        isArray = validatesAsArray()
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: ArraySlice<Byte>) {
        guard data.count > 4 else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Array(data[data.startIndex..<data.endIndex.advanced(by: -1)])
        var length: UInt32 = 0
        
        memcpy(&length, &storage, 4)
        
        guard numericCast(length) <= data.count, data.last == 0x00 else {
            self.storage = [5,0,0,0]
            self.invalid = true
            return
        }
        
        
        searchTree = buildElementPositionsCache()
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
    public init(dictionaryElements elements: [(String, Primitive?)]) {
        storage = [5,0,0,0]
        
        for (key, value) in elements {
            guard let value = value else {
                continue
            }
            
            // Append the key-value pair
            
            // Add element to positions cache
            searchTree[KittenBytes(Bytes(key.utf8))] = storage.endIndex
            
            // Type identifier
            storage.append(value.typeIdentifier)
            // Key
            storage.append(contentsOf: key.utf8)
            // Key null terminator
            storage.append(0x00)
            // Value
            let data = value.makeBinary()
            storage.append(contentsOf: data)
        }
        
        updateDocumentHeader()
        
        isArray = false
    }
    
    /// Initializes this `Document` as a `Dictionary` using a `Dictionary` literal
    ///
    /// - parameter elements: The `Dictionary` used to initialize this must use `String` for key and `Value` for values
    public init(dictionaryLiteral elements: (String, Primitive?)...) {
        self.init(dictionaryElements: elements)
    }
    
    /// Initializes this `Document` as an `Array` using an `Array` literal
    ///
    /// - parameter elements: The `Array` literal used to initialize the `Document` must be a `[Value]`
    public init(arrayLiteral elements: Primitive?...) {
        self.init(array: elements)
    }
    
    /// Initializes this `Document` as an `Array` using an `Array`
    ///
    /// - parameter elements: The `Array` used to initialize the `Document` must be a `[Value]`
    public init(array elements: [Primitive?]) {
        storage = [5,0,0,0]
        
        for (index, value) in elements.enumerated() {
            guard let value = value else {
                continue
            }
            
            let key = Bytes(index.description.utf8)
            
            // Append the values
            
            // Add element to positions cache
            searchTree[KittenBytes(key)] = storage.endIndex
            
            // Type identifier
            storage.append(value.typeIdentifier)
            // Key
            storage.append(contentsOf: key)
            // Key null terminator
            storage.append(0x00)
            // Value
            storage.append(contentsOf: value.makeBinary())
        }
        
        updateDocumentHeader()
        
        isArray = true
    }
    
    // MARK: - Manipulation & Extracting values
    
    public typealias Index = DocumentIndex
    
    /// Appends a Key-Value pair to this `Document` where this `Document` acts like a `Dictionary`
    ///
    /// TODO: Analyze what should happen with `Array`-like documents and this function
    /// TODO: Analyze what happens when you append with a duplicate key
    ///
    /// - parameter value: The `Value` to append
    /// - parameter key: The key in the key-value pair
    public mutating func append(_ value: Primitive, forKey key: String) {
        // We're going to insert the element before the Document null terminator
        searchTree[KittenBytes(Bytes(key.utf8))] = storage.endIndex
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
        
        // Increase the bytecount
        updateDocumentHeader()
        
        isArray = false
    }
    
    /// Appends a Key-Value pair to this `Document` where this `Document` acts like a `Dictionary`
    ///
    /// TODO: Analyze what should happen with `Array`-like documents and this function
    /// TODO: Analyze what happens when you append with a duplicate key
    ///
    /// - parameter value: The `Value` to append
    /// - parameter key: The key in the key-value pair
    internal mutating func append(_ value: Primitive, forKey key: Bytes) {
        // We're going to insert the element before the Document null terminator
        searchTree[KittenBytes(key)] = storage.endIndex
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
        
        // Increase the bytecount
        updateDocumentHeader()
        
        isArray = false
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = self.count.description
        
        
        // We're going to insert the element before the Document null terminator
        searchTree[KittenBytes(Bytes(key.utf8))] = storage.endIndex
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
        
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
    
    /// The last `Index` in this `Document`. Can point to nothing whent the `Document` is empty
    public var endIndex: DocumentIndex {
        return index(after: DocumentIndex(byteIndex: (sortedTree().last?.1 ?? 4)))
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
            
            guard let value = self.getValue(atDataPosition: key.dataPosition, withType: key.type) else {
                return nil
            }
            
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
    @discardableResult public mutating func removeValue(forKey key: String) -> Primitive? {
        guard let meta = getMeta(forKeyBytes: Bytes(key.utf8)) else {
            return nil
        }
        
        let val = getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        let length = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        guard meta.dataPosition + length <= storage.count else {
            return nil
        }
        
        storage.removeSubrange(meta.elementTypePosition..<meta.dataPosition + length)
        
        let removedLength = (meta.dataPosition + length) - meta.elementTypePosition
        
        for (key, elementPosition) in searchTree where elementPosition > meta.elementTypePosition {
            searchTree[key] = elementPosition - removedLength
        }
        
        searchTree.removeValue(forKey: key.kittenBytes)
        
        updateDocumentHeader()
        
        return val
    }
    
    // MARK: - Files
    
    /// Writes this `Document` to a file. Usually for debugging purposes
    ///
    /// - parameter path: The path to write this to
    public func write(toFile path: String) throws {
        guard let url = URL(string: "file://" + path) else {
            throw URLError(.badURL)
        }
        try Data(bytes: self.bytes).write(to: url)
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
            combination.append(doc)
        }
        
        return combination
    }
}
