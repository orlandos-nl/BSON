//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 19-05-16.
//
//

import Foundation

public typealias IndexIterationElement = (key: String, value: Primitive)

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
    internal var invalid: Bool = false
    internal var searchTree = IndexTrieNode(0)
    internal var original = true
    
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
            invalid = true
            storage = []
            return
        }
        
        let length = Int(Int32(data[0...3]))
        
        guard length > 4 else {
            invalid = true
            storage = data
            return
        }
        
        guard length <= data.count, data.last == 0x00 else {
            invalid = true
            storage = Array(data[4..<data.count &- 1])
            return
        }
        
        storage = Array(data[4..<length &- 1])
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    public init(data: ArraySlice<Byte>) {
        guard data.count > 5 else {
            invalid = true
            storage = []
            return
        }
        
        let length = Int(Int32(data[data.startIndex...data.startIndex.advanced(by: 3)]))
        
        guard length > 4 else {
            invalid = true
            storage = Array(data)
            return
        }
        
        guard length <= data.count, data.last == 0x00 else {
            invalid = true
            storage = Array(data[data.startIndex.advanced(by: 4)..<data.endIndex.advanced(by: -1)])
            return
        }
        
        storage = Array(data[data.startIndex.advanced(by: 4)..<data.endIndex.advanced(by: -1)])
    }
    
    /// Initializes this Doucment with an `Array` of `Byte`s - I.E: `[Byte]`
    ///
    /// - parameters data: the `[Byte]` that's being used to initialize this `Document`
    internal init(data: ArraySlice<Byte>, copying cache: IndexTrieNode) {
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
        storage = []
        self.isArray = true
        
        var reserved = 0
        var counter = 0
        
        let elements: [(UInt8, [UInt8], [UInt8])] = elements.flatMap { element in
            defer { counter = counter &+ 1 }
            guard let element = element else {
                return nil
            }
            
            let key = [UInt8](counter.description.utf8)
            let data = element.makeBinary()
            reserved = reserved &+ data.count &+ key.count &+ 2
            
            return (element.typeIdentifier, key, data)
        }
        
        storage.reserveCapacity(reserved)
        
        for (type, key, value) in elements {
            // Append the values
            
            // Type identifier
            storage.append(type)
            // Key
            storage.append(contentsOf: key)
            // Key null terminator
            storage.append(0x00)
            // Value
            storage.append(contentsOf: value)
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
        let encodedValue = value.makeBinary()
        
        storage.reserveCapacity(storage.count + encodedValue.count + key.utf8.count + 2)
        
        let searchTreeKey = IndexKey(KittenBytes([UInt8](key.utf8)))
        self.searchTree[[searchTreeKey]] = IndexTrieNode(storage.endIndex)
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: encodedValue)
    }
    
    internal mutating func unset(_ key: [IndexKey]) {
        guard let meta = getMeta(for: key) else {
            return
        }
        
        let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        guard len >= 0 else {
            return
        }
        
        let dataEndPosition = meta.dataPosition &+ len
        
        storage.removeSubrange(meta.elementTypePosition..<dataEndPosition)
        let relativeLength = dataEndPosition - meta.elementTypePosition
        
        // Remove indexes for this key since the value is being removed
        self.searchTree[key] = nil
        
        for (key, value) in self.searchTree.storage where value.value > meta.elementTypePosition {
            self.searchTree.storage[key]?.value = value.value &- relativeLength
        }
        
        updateCache(mutatingPosition: meta.elementTypePosition, by: -relativeLength, for: key)
    }
    
    internal mutating func set(value: Primitive, for key: [IndexKey]) {
        var relativeLength = 0
        var mutatedPosition = 0
        
        // Creates a trie node for the value at the given position
        // Will be called later down the line with the position
        // Additonally copies the index from the value if it's a document
        func makeTrie(for mutatedPosition: Int, with value: Primitive, key: [IndexKey]) {
            let node = IndexTrieNode(mutatedPosition)
            
            if let trie = (value as? Document)?.searchTree.storage {
                node.storage = trie
            }
            
            if !isKnownUniquelyReferenced(&searchTree) {
                searchTree = searchTree.copy()
            }
            
            self.searchTree[key] = node
        }
        
        // If the key already has a value
        if let meta = getMeta(for: key) {
            // Remove the value (not the key)
            let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
            
            guard len >= 0 else {
                return
            }
            
            let dataEndPosition = meta.dataPosition &+ len
            
            storage.removeSubrange(meta.dataPosition..<dataEndPosition)
            
            // Add the new value after the key
            let oldLength = dataEndPosition - meta.dataPosition
            let newBinary = value.makeBinary()
            storage.insert(contentsOf: newBinary, at: meta.dataPosition)
            
            // Replace the element type
            storage[meta.elementTypePosition] = value.typeIdentifier
            relativeLength = newBinary.count - oldLength
            
            // Update the trie cache
            mutatedPosition = meta.elementTypePosition
            
            // Update relevant document headers
            updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: key)
            
            makeTrie(for: mutatedPosition, with: value, key: key)
            
            for (key, value) in self.searchTree.storage where value.value > meta.elementTypePosition {
                self.searchTree.storage[key]?.value = value.value &+ relativeLength
            }
            
            // update element
        } else if let lastPart = key.last {
            // The value doesn't exist, and the key provided is valid (has a key)
            
            // If the key is top-level, append to the end of the Document
            if key.count == 1 {
                // Create a new trie node
                makeTrie(for: self.storage.endIndex, with: value, key: key)
                
                // Append the key-value pair
                // Type identifier
                self.storage.append(value.typeIdentifier)
                // Key
                self.storage.append(contentsOf: lastPart.key.bytes)
                // Key null terminator
                self.storage.append(0x00)
                // Value
                self.storage.append(contentsOf: value.makeBinary())
            } else {
                // The value doesn't exist and resides in a subdocument, this is complex
                let fullKey = key
                var key = key
                key.removeLast()
                
                // Inserts the provided value into the document at the given position
                // Seeks to the end of the document and inserts it at the end
                func insert(_ value: Primitive, into position: Int, for keyName: KittenBytes) {
                    // If it's a Document, insert, otherwise, do nothing
                    guard let type = ElementType(rawValue: storage[position]), (type == .arrayDocument || type == .document) else {
                        return
                    }
                    
                    let dataLength = getLengthOfElement(withDataPosition: position, type: type)
                    
                    guard dataLength >= 0 else {
                        return
                    }
                    
                    
                    // Serialize the value
                    let serializedValue = value.makeBinary()
                    let serializedPair = [value.typeIdentifier] + keyName.bytes + [0x00] + serializedValue
                    
                    // Set up the parameters for post-insert updates
                    relativeLength = keyName.bytes.count &+ 2 &+ serializedValue.count
                    mutatedPosition = position &+ dataLength &- 1
                    
                    makeTrie(for: mutatedPosition, with: value, key: fullKey)
                    
                    // Insert the new value into the subdocument
                    self.storage.insert(contentsOf: serializedPair, at: mutatedPosition)
                }
                
                // Look for the highest level matching subdocument, and create the necessary structure in there
                
                // If all of the subdocuments exist, but the key isn't there yet, add the value
                if let position = searchTree[position: key] ?? index(recursive: nil, lookingFor: key)?.elementTypePosition {
                    replaceLoop: for i in position..<storage.count {
                        if storage[i] == 0x00 {
                            // Insert the value into the provided document
                            insert(value, into: i &+ 1, for: lastPart.key)
                            return
                        }
                    }
                } else {
                    var subDocuments: [KittenBytes] = [lastPart.key]
                    
                    // Look through all keys in the path until an existing subdocument is found (or none is found)
                    // All skipped keys will be created and inserted at the best matching (sub)document
                    loop: while true {
                        // Remove the next key from the path and append it as a subdocument
                        if key.count > 0 {
                            subDocuments.append(key.removeLast().key)
                        }
                        
                        // If the current path doesn't exist
                        guard let meta = getMeta(for: key) else {
                            // There must be remaining keys, otherwise, insert it top-level
                            guard key.count > 0 else {
                                let key = subDocuments.removeLast()
                                var document = Document()
                                
                                document[subDocuments.reversed()] = value
                                makeTrie(for: self.storage.endIndex, with: document, key: [IndexKey(key)])
                                self.append(document, forKey: key.bytes)
                                
                                // Update relevant document headers
                                updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: fullKey)
                                
                                break loop
                            }
                            
                            continue
                        }
                        
                        // If the path does exist, and there are subdocuments to be created
                        if subDocuments.count > 0 {
                            let firstSubDocument = subDocuments.removeLast()
                            var document = Document()
                            subDocuments.reverse()
                            
                            document[subDocuments + [lastPart.key]] = value
                            
                            insert(document, into: meta.dataPosition, for: firstSubDocument)
                            
                            updateCache(mutatingPosition: mutatedPosition, by: relativeLength, for: key)
                            makeTrie(for: meta.dataPosition, with: document, key: key)
                        } else {
                            // If there are no necessary subdocuments to be created
                            
                            // Insert the value into this subdocument
                            insert(value, into: meta.elementTypePosition, for: lastPart.key)
                            makeTrie(for: meta.elementTypePosition, with: value, key: [lastPart])
                        }
                    }
                }
            }
        }
    }
    
    fileprivate mutating func updateCache(mutatingPosition position: Int, by relativeLength: Int, for key: [IndexKey]) {
        if key.count > 1 {
            // Update all document headers, including sub documents
            for pos in 1..<key.count {
                self.updateDocumentHeader(for: Array(key[0..<pos]), relativeLength: relativeLength)
            }
        }
    }
    
    internal mutating func updateDocumentHeader(for key: [IndexKey], relativeLength: Int) {
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
        let encodedValue = value.makeBinary()
        
        storage.reserveCapacity(storage.count + encodedValue.count + key.utf8.count + 2)
        
        let searchTreeKey = IndexKey(KittenBytes([UInt8](key.utf8)))
        self.searchTree[[searchTreeKey]] = IndexTrieNode(storage.endIndex)
        
        // Append the key-value pair
        // Type identifier
        storage.append(value.typeIdentifier)
        // Key
        storage.append(contentsOf: key.utf8)
        // Key null terminator
        storage.append(0x00)
        // Value
        storage.append(contentsOf: encodedValue)
    }
    
    /// Appends the convents of `otherDocument` to `self` overwriting any keys in `self` with the `otherDocument` equivalent in the case of duplicates
    public mutating func append(contentsOf otherDocument: Document) {
        if self.validatesAsArray() && otherDocument.validatesAsArray() {
            self = Document(array: self.arrayRepresentation + otherDocument.arrayRepresentation)
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
        
        guard length >= 0 else {
            fatalError("Invalid value found in Document when finding the next key at position \(position)")
        }
        
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
        let key = IndexKey(indexString)
        
        guard let meta = getMeta(for: [key]) else {
            return nil
        }
        
        let val = getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        let length = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        guard length >= 0 else {
            return nil
        }
        
        guard meta.dataPosition + length <= storage.count else {
            return nil
        }
        
        storage.removeSubrange(meta.elementTypePosition..<meta.dataPosition + length)
        
        searchTree.storage[key] = nil
        
        // Modify the searchTree efficienty, where necessary
        for node in searchTree.storage.values where node.value > meta.elementTypePosition {
            node.value = node.value &- (length &+ indexString.bytes.count &+ 2)
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
