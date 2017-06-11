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
    
    internal var isArray: Bool?
    internal var storage: Bytes
    internal var searchTree = IndexTree()
    
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
        defer {
            index(recursive: nil, lookingFor: nil)
        }
        
        guard data.count > 5 else {
            storage = []
            return
        }
        
        let length = Int(data[0...3].makeInt32())
        
        guard length <= data.count, data.last == 0x00 else {
            storage = Array(data[4..<data.count &- 1])
            return
        }
        
        storage = Array(data[4..<Swift.max(length &- 1, 0)])
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: ArraySlice<Byte>) {
        defer {
            index(recursive: nil, lookingFor: nil)
        }
        
        guard data.count > 5 else {
            storage = []
            return
        }
        
        storage = Array(data[data.startIndex.advanced(by: 4)..<data.endIndex.advanced(by: -1)])
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    internal init(data: ArraySlice<Byte>, copying cache: IndexTree) {
        guard data.count > 5 else {
            storage = []
            return
        }
        
        storage = Array(data)
        self.searchTree = cache
    }
    
    /// Initializes an empty `Document`
    public init() {
        // the empty document is 5 bytes long.
        storage = []
        self.isArray = false
    }
    
    // MARK: - Initialization from Swift Types & Literals
    
    /// Initializes this `Document` as a `Dictionary` using an existing Swift `Dictionary`
    ///
    /// - parameter elements: The `Dictionary`'s generics used to initialize this must be a `String` key and `Value` for the value
    public init(dictionaryElements elements: [(String, Primitive?)]) {
        defer {
            index(recursive: nil, lookingFor: nil)
        }
        
        storage = []
        self.isArray = false
        
        for (key, value) in elements {
            guard let value = value else {
                continue
            }
            
            // Append the key-value pair
            
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
        defer {
            index(recursive: nil, lookingFor: nil)
        }
        
        storage = []
        self.isArray = true
        
        for (index, value) in elements.enumerated() {
            guard let value = value else {
                continue
            }
            
            let key = Bytes(index.description.utf8)
            
            // Append the values
            
            // Type identifier
            storage.append(value.typeIdentifier)
            // Key
            storage.append(contentsOf: key)
            // Key null terminator
            storage.append(0x00)
            // Value
            storage.append(contentsOf: value.makeBinary())
        }
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
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
    }
    
    internal mutating func unset(_ key: IndexKey) {
        guard let meta = getMeta(for: key) else {
            return
        }
        
        let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        let dataEndPosition = meta.dataPosition &+ len
        
        storage.removeSubrange(meta.elementTypePosition..<dataEndPosition)
        let relativeLength = dataEndPosition - meta.elementTypePosition
        
        self.searchTree.storage[key] = nil
        
        unsetSubkeys(for: key)
        
        updateCache(mutatingPosition: meta.elementTypePosition, by: -relativeLength, for: key)
    }
    
    internal mutating func set(value: Primitive, for key: IndexKey) {
        var relativeLength = 0
        var mutatedPosition = 0
        
        unsetSubkeys(for: key)
        
        if let meta = getMeta(for: key) {
            let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
            let dataEndPosition = meta.dataPosition &+ len
            
            storage.removeSubrange(meta.dataPosition..<dataEndPosition)
            let oldLength = dataEndPosition - meta.dataPosition
            let newBinary = value.makeBinary()
            storage.insert(contentsOf: newBinary, at: meta.dataPosition)
            storage[meta.elementTypePosition] = value.typeIdentifier
            relativeLength = newBinary.count - oldLength
            
            mutatedPosition = meta.elementTypePosition
            
            updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: key)
            
            if value is Document {
                for (subKey, position) in (value as! Document).buildAndReturnIndex().storage {
                    self.searchTree.storage[IndexKey(key.keys + subKey.keys)] = position &+ mutatedPosition
                }
            }
            
            // update element
        } else if let lastPart = key.keys.last {
            if key.keys.count == 1 {
                self.searchTree.storage[key] = self.storage.endIndex
                // Append the key-value pair
                // Type identifier
                self.storage.append(value.typeIdentifier)
                // Key
                self.storage.append(contentsOf: lastPart.bytes)
                // Key null terminator
                self.storage.append(0x00)
                // Value
                self.storage.append(contentsOf: value.makeBinary())
            } else {
                let fullKey = key
                var keys = key.keys
                keys.removeLast()
                let key = IndexKey(keys)
                
                func insert(_ value: Primitive, into position: Int, for keyName: KittenBytes) {
                    // If it's a Document, insert, otherwise, do nothing
                    guard let type = ElementType(rawValue: storage[position]), (type == .arrayDocument || type == .document) else {
                        return
                    }
                    
                    let dataLength = getLengthOfElement(withDataPosition: position, type: type)
                    
                    // Serialize the value
                    let serializedValue = value.makeBinary()
                    let serializedPair = [value.typeIdentifier] + keyName.bytes + [0x00] + serializedValue
                    
                    // Set up the parameters for post-insert updates
                    relativeLength = keyName.bytes.count &+ 2 &+ serializedValue.count
                    mutatedPosition = position &+ dataLength &- 1
                    
                    // Insert the new value into the subdocument
                    self.searchTree.storage[fullKey] = self.storage.endIndex
                    self.storage.insert(contentsOf: serializedPair, at: mutatedPosition)
                }
                
                // Look for the subdocument
                if let position = searchTree.storage[key] ?? index(recursive: nil, lookingFor: key)?.elementTypePosition {
                    replaceLoop: for i in position..<storage.count {
                        if storage[i] == 0x00 {
                            insert(value, into: position, for: lastPart)
                            break replaceLoop
                        }
                    }
                } else {
                    var subDocuments: [KittenBytes] = [lastPart]
                    
                    loop: while true {
                        if keys.count > 0 {
                            subDocuments.append(keys.removeLast())
                        }
                        
                        guard let meta = getMeta(for: IndexKey(keys)) else {
                            guard keys.count > 0 else {
                                let key = subDocuments.removeLast()
                                var document = Document()
                                
                                document[subDocuments.reversed()] = value
                                let appendPosition = storage.endIndex
                                self.append(document, forKey: key.bytes)
                                
                                updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: fullKey)
                                
                                self.searchTree.storage[IndexKey([key])] = appendPosition
                                
                                for (subKey, position) in document.buildAndReturnIndex().storage {
                                    // element, 
                                    self.searchTree.storage[IndexKey([key] + subKey.keys)] = position &+ 6 &+ key.bytes.count &+ appendPosition
                                }
                                break loop
                            }
                            
                            continue
                        }
                        
                        if subDocuments.count > 0 {
                            let firstSubDocument = subDocuments.removeLast()
                            var document = Document()
                            
                            document[subDocuments.reversed() + [lastPart]] = value
                            
                            insert(document, into: meta.elementTypePosition, for: firstSubDocument)
                            
                            updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: key)
                            
                            self.searchTree.storage[IndexKey([firstSubDocument])] = meta.elementTypePosition
                            
                            for (subKey, position) in document.buildAndReturnIndex().storage {
                                self.searchTree.storage[IndexKey(key.keys + subKey.keys)] = position &+ 6 &+ firstSubDocument.bytes.count &+ mutatedPosition
                            }
                            
                            break loop
                        }
                        
                        insert(value, into: meta.elementTypePosition, for: lastPart)
                        
                        self.searchTree.storage[IndexKey([lastPart])] = meta.elementTypePosition
                        
                        break loop
                    }
                }
            }
        } else {
            return
        }
    }
    
    fileprivate func unsetSubkeys(for key: IndexKey) {
        nextKey: for indexKey in searchTree.storage.keys where indexKey.keys.count > key.keys.count {
            for i in 0..<key.keys.count where indexKey.keys[i] != key.keys[i] {
                continue nextKey
            }
            
            searchTree.storage[indexKey] = nil
        }
    }
    
    fileprivate mutating func updateCache(mutatingPosition position: Int, by relativeLength: Int, for key: IndexKey) {
        // Modify the searchTree efficienty, where necessary
        for (key, startPosition) in searchTree.storage where startPosition > position {
            searchTree.storage[key] = startPosition &+ relativeLength
        }
        
        if key.keys.count > 1 {
            // Update all document headers, including sub documents
            for pos in 1..<key.keys.count {
                self.updateDocumentHeader(for: IndexKey(Array(key.keys[0..<pos])), relativeLength: relativeLength)
            }
        }
    }
    
    internal mutating func updateDocumentHeader(for key: IndexKey, relativeLength: Int) {
        guard let dataPosition = getMeta(for: key)?.dataPosition, dataPosition < storage.count else {
            return
        }
        
        guard var count = storage.withUnsafeMutableBytes({ $0 }).baseAddress?.advanced(by: dataPosition).assumingMemoryBound(to: Int32.self).pointee else {
            return
        }
        
        count = count + Int32(relativeLength)
        
        guard let pointer = storage.withUnsafeMutableBytes({ $0 }).baseAddress?.advanced(by: dataPosition) else {
            return
        }
        
        memcpy(pointer, &count, 4)
    }
    
    /// Appends a Key-Value pair to this `Document` where this `Document` acts like a `Dictionary`
    ///
    /// TODO: Analyze what should happen with `Array`-like documents and this function
    /// TODO: Analyze what happens when you append with a duplicate key
    ///
    /// - parameter value: The `Value` to append
    /// - parameter key: The key in the key-value pair
    internal mutating func append(_ value: Primitive, forKey key: Bytes) {
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = self.count.description
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: value.makeBinary())
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
    internal func makeDocumentLength() -> Bytes {
        // One extra byte for the missing null terminator in the storage
        return Int32(storage.count + 5).makeBytes()
    }
    
    // MARK: - Collection
    
    /// The first `Index` in this `Document`. Can point to nothing when the `Document` is empty
    public var startIndex: DocumentIndex {
        return DocumentIndex(byteIndex: 0)
    }
    
    /// The last `Index` in this `Document`. Can point to nothing when the `Document` is empty
    public var endIndex: DocumentIndex {
        return DocumentIndex(byteIndex: self.storage.count)
    }
    
    /// Creates an iterator that iterates over all key-value pairs
    public func makeIterator() -> AnyIterator<IndexIterationElement> {
        let keys = self.makeKeyIterator()
        
        return AnyIterator {
            guard let key = keys.next() else {
                return nil
            }
            
            guard let string = String(bytes: key.keyData[0..<key.keyData.endIndex], encoding: String.Encoding.utf8) else {
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
        let indexString = KittenBytes([UInt8](key.utf8))
        let key = IndexKey([indexString])
        
        guard let meta = getMeta(for: key) else {
            return nil
        }
        
        let val = getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        let length = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        guard meta.dataPosition + length <= storage.count else {
            return nil
        }
        
        storage.removeSubrange(meta.elementTypePosition..<meta.dataPosition + length)
        
        searchTree.storage[key] = nil
        
        // Modify the searchTree efficienty, where necessary
        for (searchKey, startPosition) in searchTree.storage where startPosition > meta.elementTypePosition {
            searchTree.storage[searchKey] = startPosition &- (length &+ indexString.bytes.count &+ 2)
        }
        
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
