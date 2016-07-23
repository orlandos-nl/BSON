//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 19-05-16.
//
//

import Foundation
import C7

public protocol BSONArrayProtocol : _ArrayProtocol {}
extension Array : BSONArrayProtocol {}

extension BSONArrayProtocol where Iterator.Element == Document {
    public init(bsonBytes bytes: [UInt8], validating: Bool = false) {
        var array = [Document]()
        var position = 0
        
        documentLoop: while bytes.count >= position + 5 {
            let length = Int(UnsafePointer<Int32>(Array(bytes[position..<position+4])).pointee)
            
            guard length > 0 else {
                // invalid
                break
            }
            
            guard bytes.count >= position + length else {
                break documentLoop
            }
            
            let document = Document(data: Array(bytes[position..<position+length]))
            
            if validating {
                if document.validate() {
                    array.append(document)
                }
            } else {
                array.append(document)
            }
            
            position += length
        }
        
        self.init(array)
    }
    
    /// The combined data for all documents in the array
    public var bytes: [UInt8] {
        return self.map { $0.bytes }.reduce([], combine: +)
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
    internal var storage: C7.Data
    private var _count: Int? = nil
    private var invalid = false
    
    // MARK: - Initialization from data
    public init(data: Foundation.Data) {
        var byteArray = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &byteArray, count: byteArray.count)
        
        self.init(data: byteArray)
    }
    
    public init(data: C7.Data) {
        guard let length = try? Int32.instantiate(bytes: Array(data[0...3])), Int(length) <= data.count else {
            self.storage = [5,0,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Data(data[0..<Int(length)])
    }
    
    public init(data: [UInt8]) {
        guard let length = try? Int32.instantiate(bytes: Array(data[0...3])), Int(length) <= data.count else {
            self.storage = [5,0,0,0,0]
            self.invalid = true
            return
        }
        
        storage = Data(data[0..<Int(length)])
    }
    
    public init() {
        // the empty document is 5 bytes long.
        storage = [5,0,0,0,0]
    }
    
    // MARK: - Initialization from Swift Types & Literals
    public init(dictionaryElements elements: [(String, Value)]) {
        self.init()
        for element in elements {
            self.append(element.1, forKey: element.0)
        }
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
    private func getMeta(forKeyBytes keyBytes: [UInt8]) -> (elementTypePosition: Int, dataPosition: Int, type: ElementType)? {
        // start at the begin of the element list, the fifth byte
        var position = 4
        
        while storage.count > position {
            /**** ELEMENT TYPE ****/
            if storage[position] == 0 {
                // this is the end of the document
                return nil
            }
            
            guard let thisElementType = ElementType(rawValue: storage[position]) else {
                print("Error while parsing BSON document: element type unknown at position \(position).")
                return nil
            }
            
            let elementTypePosition = position
            
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
                return (elementTypePosition: elementTypePosition, dataPosition: position, type: thisElementType)
            }
            
            // we didn't find the key, so we should skip past this element, and go on to the next one
            let length = getLengthOfElement(withDataPosition: position, type: thisElementType)
            position += length
        }
        
        return nil
    }
    
    /// Returns the length in bytes.
    private func getLengthOfElement(withDataPosition position: Int, type: ElementType) -> Int {
        // check
        func need(_ amountOfBytes: Int) -> Bool {
            return self.storage.count >= position + amountOfBytes + 1 // the document also has a trailing null
        }
        
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
            guard need(5) else { // length definition + null terminator
                return 0
            }
            
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee) + 4
        case .binary:
            guard need(5) else {
                return 0
            }
            
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee) + 5
        case .document, .arrayDocument, .javascriptCodeWithScope: // Types with their entire length in the first 4 bytes
            guard need(4) else {
                return 0
            }
            
            return Int(UnsafePointer<Int32>(Array(storage[position...position+3])).pointee)
        }
    }
    
    // the return value of the closure indicates wether the loop must continue (true) or stop (false)
    private func makeKeyIterator(startingAtByte startPos: Int = 4) -> AnyIterator<(dataPosition: Int, type: ElementType, keyData: [UInt8], startPosition: Int)> {
        var position = startPos
        return AnyIterator {
            let startPosition = position
            
            guard self.storage.count - position > 2 else {
                // Invalid document condition
                return nil
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return nil
            }
            position += 1
            
            // get the key data
            let keyStart = position
            while self.storage.count > position {
                defer {
                    position += 1
                }
                
                if self.storage[position] == 0 {
                    break
                }
            }
            
            defer {
                position += self.getLengthOfElement(withDataPosition: position, type: type)
            }
            
            return (dataPosition: position, type: type, keyData: Array(self.storage[keyStart..<position]), startPosition: startPosition)
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
    
    public mutating func append(_ value: Value) {
        let key = "\(self.count)"
        self.append(value, forKey: key)
    }
    
    private mutating func updateDocumentHeader() {
        storage.replaceSubrange(0..<4, with: Int32(storage.count).bytes)
    }
    
    private func getValue(atDataPosition startPosition: Int, withType type: ElementType) -> Value {
        var position = startPosition
        
        func remaining() -> Int {
            return storage.endIndex - startPosition
        }
        
        switch type {
        case .double: // double
            guard remaining() >= 8 else {
                return .nothing
            }
            
            let double = UnsafePointer<Double>(Array(storage[position..<position+8])).pointee
            return .double(double)
        case .string: // string
            // Check for null-termination and at least 5 bytes (length spec + terminator)
            guard remaining() >= 5 else {
                return .nothing
            }
            
            // Get the length
            let length = UnsafePointer<Int32>(Array(storage[position...position+3])).pointee
            
            // Check if the data is at least the right size
            guard storage.count-position >= Int(length) + 4 else {
                return .nothing
            }
            
            // Empty string
            if length == 1 {
                position += 5
                
                return .string("")
            }
            
            guard length > 0 else {
                return .nothing
            }
            
            var stringData = Array(storage[position+4..<position+Int(length + 3)])
            
            guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: String.Encoding.utf8, freeWhenDone: false) else {
                return .nothing
            }
            
            return .string(string)
        case .document, .arrayDocument: // document / array
            guard remaining() >= 5 else {
                return .nothing
            }
            
            let length = Int(UnsafePointer<Int32>(Array(storage[position..<position+4])).pointee)
            let subData = Array(storage[position..<position+length])
            let document = Document(data: subData)
            return type == .document ? .document(document) : .array(document)
        case .binary: // binary
            guard remaining() >= 5 else {
                return .nothing
            }
            
            let length = UnsafePointer<Int32>(Array(storage[position..<position+4])).pointee
            let subType = storage[position+4]
            
            guard remaining() >= Int(length) + 5 else {
                return .nothing
            }
            
            let realData = length > 0 ? Array(storage[position+5...position+Int(4+length)]) : []
            // length + subType + data
            position += 4 + 1 + Int(length)
            
            return .binary(subtype: BinarySubtype(rawValue: subType), data: realData)
        case .objectId: // objectid
            guard remaining() >= 12 else {
                return .nothing
            }
            
            if let id = try? ObjectId(bytes: Array(storage[position..<position+12])) {
                return .objectId(id)
            } else {
                return .nothing
            }
        case .boolean:
            guard remaining() >= 1 else {
                return .nothing
            }
            
            return storage[position] == 0x00 ? .boolean(false) : .boolean(true)
        case .utcDateTime:
            guard remaining() >= 8 else {
                return .nothing
            }
            
            let interval = UnsafePointer<Int64>(Array(storage[position..<position+8])).pointee
            let date = Date(timeIntervalSince1970: Double(interval) / 1000) // BSON time is in ms
            
            return .dateTime(date)
        case .nullValue:
            return .null
        case .regex:
            let k = storage[position..<storage.endIndex].split(separator: 0x00, maxSplits: 2, omittingEmptySubsequences: false)
            guard k.count >= 2 else {
                return .nothing
            }
            
            let patternData = Array(k[0])
            let optionsData = Array(k[1])
            
            guard let pattern = try? String.instantiateFromCString(bytes: patternData + [0x00]),
                let options = try? String.instantiateFromCString(bytes: optionsData + [0x00]) else {
                    return .nothing
            }
            
            return .regularExpression(pattern: pattern, options: options)
        case .javascriptCode:
            guard let code = try? String.instantiate(bytes: Array(storage[position..<storage.endIndex])) else {
                return .nothing
            }
            
            return .javascriptCode(code)
        case .javascriptCodeWithScope:
            // min length is 14 bytes: 4 for the int32, 5 for the string and 5 for the document
            guard remaining() >= 14 else {
                return .nothing
            }
            
            // why did they include this? it's not needed. whatever. we'll validate it.
            let totalLength = Int(UnsafePointer<Int32>(Array(storage[position..<position+4])).pointee)
            guard remaining() >= totalLength else {
                return .nothing
            }
            
            let stringDataAndMore = Array(storage[position+4..<position+totalLength])
            var trueCodeSize = 0
            guard let code = try? String.instantiate(bytes: stringDataAndMore, consumedBytes: &trueCodeSize) else {
                return .nothing
            }
            
            // - 4 (length) - 5 (document)
            guard stringDataAndMore.count - 4 - 5 >= trueCodeSize else {
                return .nothing
            }
            
            let scopeDataAndMaybeMore = Array(stringDataAndMore[trueCodeSize..<stringDataAndMore.endIndex])
            let scope = Document(data: scopeDataAndMaybeMore)
            
            return .javascriptCodeWithScope(code: code, scope: scope)
        case .int32: // int32
            guard remaining() >= 4 else {
                return .nothing
            }
            
            return .int32(UnsafePointer<Int32>(Array(storage[position..<position+4])).pointee)
        case .timestamp:
            guard remaining() >= 8 else {
                return .nothing
            }
            
            let stamp = UnsafePointer<Int32>(Array(storage[position..<position+4])).pointee
            let increment = UnsafePointer<Int32>(Array(storage[position+4..<position+8])).pointee
            
            return .timestamp(stamp: stamp, increment: increment)
        case .int64: // timestamp, int64
            guard remaining() >= 8 else {
                return .nothing
            }
            
            return .int64(UnsafePointer<Int64>(Array(storage[position..<position+8])).pointee)
        case .minKey: // MinKey
            return .minKey
        case .maxKey: // MaxKey
            return .maxKey
        }
    }
    
    public subscript(key: String) -> Value {
        get {
            guard let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) else {
                // use dot syntax
                var parts = key.components(separatedBy: ".")
                
                guard parts.count >= 2 else {
                    return .nothing
                }
                
                let firstPart = parts.removeFirst()
                
                var value: Value = self[firstPart]
                while !parts.isEmpty {
                    let part = parts.removeFirst()
                    
                    value = value[part]
                }
                
                return value
            }
            
            return getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        }
        
        set {
            let parts = key.characters.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            
            if parts.count == 2 {
                let firstPart = String(parts[0])
                let secondPart = String(parts[1])
                
                self[firstPart][secondPart] = newValue
                return
            }
            
            if let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) {
                let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                let dataEndPosition = meta.dataPosition+len
                
                storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                storage.insert(contentsOf: newValue.bytes, at: meta.dataPosition)
                storage[meta.elementTypePosition] = newValue.typeIdentifier
                updateDocumentHeader()
                
                return
            }
            
            self.append(newValue, forKey: key)
        }
    }
    
    public subscript(key: Int) -> Value {
        get {
            var keyPos = 0
            
            for currentKey in makeKeyIterator() {
                if keyPos == key {
                    return getValue(atDataPosition: currentKey.dataPosition, withType: currentKey.type)
                }
                
                keyPos += 1
            }
            
            return .nothing
        }
        set {
            var keyPos = 0
            
            for currentKey in makeKeyIterator() {
                if keyPos == key {
                    let len = getLengthOfElement(withDataPosition: currentKey.dataPosition, type: currentKey.type)
                    let dataEndPosition = currentKey.dataPosition+len
                    
                    storage.removeSubrange(currentKey.dataPosition..<dataEndPosition)
                    storage.insert(contentsOf: newValue.bytes, at: currentKey.dataPosition)
                    storage[currentKey.startPosition] = newValue.typeIdentifier
                    updateDocumentHeader()
                    
                    return
                }
                
                keyPos += 1
            }
            
            fatalError("Index out of range")
        }
    }
    
    public subscript(position: DocumentIndex) -> IndexIterationElement {
        get {
            var position = position.byteIndex

            guard let type = ElementType(rawValue: storage[position]) else {
                fatalError("Invalid type found in Document when searching the Document at the position \(position)")
            }
            
            position += 1
            var keyData = [UInt8]()
            
            while storage[position] != 0 {
                defer {
                    position += 1
                }
                
                keyData.append(storage[position])
            }
            
            // Skip beyond the null-terminator
            position += 1
            
            guard let key = String(bytesNoCopy: &keyData, length: keyData.count, encoding: String.Encoding.utf8, freeWhenDone: false) else {
                fatalError("Unable to construct the key bytes into a String")
            }
            
            let value = getValue(atDataPosition: position, withType: type)
            
            return (key: key, value: value)
        }
        
        set {
            var position = position.byteIndex

            guard let type = ElementType(rawValue: storage[position]) else {
                fatalError("Invalid type found in Document when modifying the Document at the position \(position)")
            }
            
            storage[position] = newValue.value.typeIdentifier
            
            position += 1
            let stringPosition = position
            
            while storage[position] != 0 {
                position += 1
            }
            
            storage.removeSubrange(stringPosition..<position)
            
            storage.insert(contentsOf: [UInt8](newValue.key.utf8), at: stringPosition)
            position = stringPosition + newValue.key.characters.count + 1
            
            let length = getLengthOfElement(withDataPosition: position, type: type)
            
            storage.removeSubrange(position..<position+length)
            storage.insert(contentsOf: newValue.value.bytes, at: position)
            
            updateDocumentHeader()
        }
    }
    
    public func validate() -> Bool {
        if self.invalid {
            return false
        }
        
        guard storage.count > 4 else {
            return false
        }
        
        let length = Int(UnsafePointer<Int32>(Array(bytes[0..<4])).pointee)

        // Check the length
        guard storage.count == length && storage.bytes.last == 0 else {
            return false
        }
        
        var position = 4
        
        while position < storage.count + 4 && storage[position] != 0 {
            // Get the element type
            guard let type = ElementType(rawValue: storage[position]) else {
                return false
            }
            
            // Position after the element type
            position += 1
            
            // This musn't be the end of the document or key
            guard storage[position] != 0 else {
                return false
            }
            
            // Find the end of the key - if any
            while position < storage.count && storage[position] != 0 {
                position += 1
            }
            
            // Check that the String ends with a null-terminator
            guard storage[position] == 0 else {
                return false
            }
            
            position += 1
            
            // get the length, safely
            let length: Int
            
            switch type {
            // Static:
            case .objectId:
                length = 12
            case .double, .int64, .utcDateTime, .timestamp:
                length = 8
            case .int32:
                length = 4
            case .boolean:
                length =  1
            case .nullValue, .minKey, .maxKey:
                length = 0
            // Calculated:
            case .regex: // defined as "cstring cstring"
                length = getLengthOfElement(withDataPosition: position, type: type)
            case .binary:
                guard storage.count > position + 5 else {
                    return false
                }
                length = getLengthOfElement(withDataPosition: position, type: type)
            default:
                guard storage.count > position + 4 else {
                    return false
                }
                length = getLengthOfElement(withDataPosition: position, type: type)
            }
            
            // Check if the length is correct
            guard storage.count > position + length else {
                return false
            }

            // Position after the value
            position += length
        }
        
        // Check if the document has an end
        guard position == storage.count - 1 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Collection
    public var startIndex: DocumentIndex {
        return DocumentIndex(byteIndex: 4)
    }
    
    public var endIndex: DocumentIndex {
        var thisIndex = 4
        for element in self.makeKeyIterator() {
            thisIndex = element.startPosition
        }
        return DocumentIndex(byteIndex: thisIndex)
    }
    
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
    
    public func index(after i: DocumentIndex) -> DocumentIndex {
        var position = i.byteIndex
        
        guard let type = ElementType(rawValue: storage[position]) else {
            fatalError("Invalid type found in Document when modifying the Document at the position \(position)")
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
    
    // MARK: - The old API had this...
    @discardableResult public mutating func removeValue(forKey key: String) -> Value? {
        guard let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) else {
            return nil
        }
        
        let val = getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        let length = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
        
        storage.removeSubrange(meta.elementTypePosition..<meta.dataPosition + length)
        updateDocumentHeader()
        
        return val
    }
    
    // MARK: - Other metadata
    public var count: Int {
        return calculatedCount
    }
    
    private var calculatedCount: Int {
        var position = 4
        var currentCount = 0
        
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
        // TODO: Does this kill the process on empty documents?
        return Int(UnsafePointer<Int32>(storage.bytes).pointee)
    }
    
    public var bytes: [UInt8] {
        return storage.bytes
    }
    
    public var data: C7.Data {
        return storage
    }
    
    /// Returns a list of all keys. 
    public var keys: [String] {
        var keys = [String]()
        for element in self.makeKeyIterator() {
            guard let key = try? String.instantiateFromCString(bytes: element.keyData) else {
                // huh?
                // TODO: Make that init nonfailing.
                continue
            }
            
            keys.append(key)
        }
        return keys
    }
    
    public var dictionaryValue: [String: Value] {
        var dictionary = [String: Value]()
        
        for pos in makeKeyIterator() {
            if let key = String(bytes: pos.keyData[0..<pos.keyData.endIndex-1], encoding: String.Encoding.utf8) {
                
                let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
                
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
    
    public var arrayValue: [Value] {
        var array = [Value]()
        
        for pos in makeKeyIterator() {
            let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
            
            array.append(value)
        }
        
        return array
    }
    
    public func validatesAsArray() -> Bool {
        var index = 0
        
        for key in self.keys {
            guard key == String(index) else {
                return false
            }
            
            index += 1
        }

        return true
    }
    
    // MARK: - Files
    public func write(toFile path: String) throws {
        var myData = storage
        let nsData = NSData(bytes: &myData, length: myData.count)
        
        try nsData.write(toFile: path)
    }
}

extension Document : CustomStringConvertible {
    public var description: String {
        return self.makeExtendedJSON()
    }
}

#if os(OSX) || os(iOS)
    extension Document : CustomPlaygroundQuickLookable {
        public var customPlaygroundQuickLook: PlaygroundQuickLook {
            return .text(self.makeExtendedJSON())
        }
    }
#endif

public struct DocumentIndex : Comparable {
    // The byte index is the very start of the element, the element type
    private var byteIndex: Int
    
    private init(byteIndex: Int) {
        self.byteIndex = byteIndex
    }
}

public func ==(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
    return lhs.byteIndex == rhs.byteIndex
}

public func <(lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
    return lhs.byteIndex < rhs.byteIndex
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
