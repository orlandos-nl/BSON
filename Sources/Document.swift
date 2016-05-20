//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 19-05-16.
//
//

import Foundation

public protocol ArrayProtocol : _ArrayProtocol {
    func arrayValue() -> [Iterator.Element]
}

extension Array : ArrayProtocol {
    public func arrayValue() -> [Iterator.Element] {
        return self
    }
}

extension ArrayProtocol where Iterator.Element == Document {
    public init(bsonBytes bytes: [UInt8]) {
        // TODO: Implement this
        abort()
    }
}

private enum ElementType : UInt8 {
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
public struct Document : Collection, DictionaryLiteralConvertible, ArrayLiteralConvertible {
    private var storage: [UInt8]
    
    // MARK: - Initialization from data
    public init(data: NSData) {
        var byteArray = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&byteArray, length: byteArray.count)
        
        self.init(data: byteArray)
    }
    
    public init(data: [UInt8]) {
        storage = data
    }
    
    public init() {
        // the empty document is 5 bytes long.
        storage = [0,0,0,5,0]
    }
    
    // MARK: - Initialization from Swift Types & Literals
    public init(dictionaryElements elements: [(String, Value)]) {
        self.init()
        for element in elements {
            self.append(element.1, forKey: element.0)
        }
        updateDocumentHeader()
    }
    
    public init(dictionaryLiteral elements: (String, Value)...) {
        self.init(dictionaryElements: elements)
    }
    
    public init(arrayLiteral elements: Value...) {
        self.init(array: elements)
    }
    
    public init(array elements: [Value]) {
        self.init(dictionaryElements: elements.enumerated().map { (index, value) in ("\(index)", value) })
    }
    
    // MARK: - BSON Parsing Logic
    
    /// This function traverses the document and
    private func getMeta(forKeyBytes keyBytes: [UInt8]) -> (dataPosition: Int, type: ElementType)? {
        // start at the begin of the element list, the fifth byte
        var position = 4
        
        // TODO: Check performance v.s. storing `storage.count` in a variable
        while storage.count > position {
            /**** ELEMENT TYPE ****/
            if storage[position] == 0 {
                // this is the end of the document
                return nil
            }
            
            guard let thisElementType = ElementType(rawValue: storage[position]) else {
                #if BSON_print_errors
                    print("Error while parsing BSON document: element type unknown at position \(position).")
                #endif
                return nil
            }
            
            /**** ELEMENT NAME ****/
            position += 1
            
            // compare the key data
            let keyPositionOffset = position
            var isKey = true // after the loop this will have the correct value
            var didEnd = false // we should end with 0, else document is invalid
            keyComparison: while storage.count > position {
                defer {
                    position += 1
                }
                
                let character = storage[position]
                
                let keyPos = position - keyPositionOffset
                
                // there is still a chance that this is the key, so check for that.
                if isKey && keyBytes.count > keyPos {
                    isKey = keyBytes[keyPos] == character
                }
                
                if character == 0 {
                    didEnd = true
                    break keyComparison // end of key data
                }
            }
            
            // the key MUST end with a 0, else the BSON data is invalid.
            guard didEnd else {
                return nil
            }
            
            /**** ELEMENT DATA ****/
            // The `position` is now at the first byte of the element data, or, when the element has no data, the start of the next element.
            
            // this must be the key, then.
            if isKey {
                return (dataPosition: position, type: thisElementType)
            }
            
            // we didn't find the key, so we should skip past this element, and go on to the next one
            let length = getLengthOfElement(withDataPosition: position, type: thisElementType)
            position += length
        }
        
        return nil
    }
    
    /// Returns the length in bytes.
    private func getLengthOfElement(withDataPosition position: Int, type: ElementType) -> Int {
        switch type {
        // Static:
        case .objectId:
            return 12
        case .double, .int64, .utcDateTime, .timestamp:
            return 8
        case .int32:
            return 4
        case .boolean:
            return 1
        case .nullValue, .minKey, .maxKey:
            return 0
        // Calculated:
        case .regex: // defined as "cstring cstring"
            var currentPosition = position
            var found = 0
            
            // iterate over 2 cstrings
            while storage.count > currentPosition && found < 2 {
                defer {
                    currentPosition += 1
                }
                
                if storage[currentPosition] == 0 {
                    found += 1
                }
            }
            return currentPosition - position // invalid
        case .string, .javascriptCode: // Types with their entire length EXCLUDING the int32 in the first 4 bytes
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee) + 4
        case .binary:
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee) + 5
        case .document, .arrayDocument, .javascriptCodeWithScope: // Types with their entire length in the first 4 bytes
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee)
        }
    }
    
    // MARK: - Manipulation & Extracting values
    public typealias Index = DocumentIndex
    public typealias IndexIterationElement = (key: String, value: Value)
    
    
    public mutating func append(_ value: Value, forKey key: String) {
        var buffer = [UInt8]()
        
        // First, the type
        buffer.append(value.typeIdentifier)
        
        // Then, the key name
        buffer += key.utf8 + [0x00]
        
        // Lastly, the data
        buffer += value.bytes
        
        // Then, insert it into ourselves, before the ending 0-byte.
        storage.insert(contentsOf: buffer, at: storage.endIndex-1)
        
        // Increase the bytecount
        updateDocumentHeader()
    }
    
    private func updateDocumentHeader() {
        // TODO: Update the count
    }
    
    public subscript(key: String) -> Value {
        get {
            // TODO: Implement this
            return .nothing
        }
        
        set {
            // TODO: Implement this
        }
    }
    
    public subscript(key: Int) -> Value {
        get {
            return self["\(key)"]
        }
        set {
            self["\(key)"] = newValue
        }
    }
    
    public subscript(position: DocumentIndex) -> IndexIterationElement {
        get {
            // TODO
            abort()
        }
        set {
            // TODO
            abort()
        }
    }
    
    // MARK: - Collection
    public var startIndex: DocumentIndex {
        // TODO
        abort()
    }
    
    public var endIndex: DocumentIndex {
        // TODO
        abort()
    }
    
    public func makeIterator() -> AnyIterator<IndexIterationElement> {
        // TODO
        abort()
    }
    
    public func index(after i: DocumentIndex) -> DocumentIndex {
        // TODO
        abort()
    }
    
    // MARK: - The old API had this...
    public mutating func removeValue(forKey key: String) -> Value? {
        // TODO
        abort()
    }
    
    // MARK: - Other metadata
    public var count: Int {
        // TODO: Cache and calculate on first `count` request
        var position = 4
        var currentCount = 0
        
        // TODO: Check performance v.s. storing `storage.count` in a variable
        while storage.count > position {
            guard let elementType = ElementType(rawValue: storage[position]) else {
                return currentCount
            }
            
            position += 1
            
            skipKey: while storage.count > position {
                defer {
                    position += 1
                }
                
                if storage[position] == 0 {
                    break skipKey
                }
            }
            
            position += getLengthOfElement(withDataPosition: position, type: elementType)
            
            guard storage.count > position else {
                return currentCount
            }
            
            currentCount += 1
        }
        
        return currentCount
    }

    public var byteCount: Int {
        return Int(UnsafePointer<Int32>(storage).pointee)
    }
    
    public var bytes: [UInt8] {
        return storage
    }
    
    public func validatesAsArray() -> Bool {
        // TODO
        abort()
    }
    
    // MARK: - Files
    public func write(toFile path: String) throws {
        var myData = storage
        let nsData = NSData(bytes: &myData, length: myData.count)
        
        try nsData.write(toFile: path)
    }
}

public struct DocumentIndex : Comparable {
    private var key: [UInt8]
    private var index: Int
}

public func ==(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
    return lhs.key == rhs.key && lhs.index == rhs.index
}

public func <(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
    return lhs.index < rhs.index
}

// MARK: Operators
extension Document : Equatable {}
public func ==(lhs: Document, rhs: Document) -> Bool {
    return lhs === rhs // for now
    // TODO: Implement proper comparison here.
}

/// Returns true if `lhs` and `rhs` store the same serialized data.
/// Implies that `lhs` == `rhs`.
public func ===(lhs: Document, rhs: Document) -> Bool {
    return lhs.storage == rhs.storage
}