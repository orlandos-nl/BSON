//
//  Document+InternalByteLevelOperations.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import KittenCore
import Foundation

public func fromBytes<T, S : Collection>(_ bytes: S) throws -> T where S.Iterator.Element == Byte, S.IndexDistance == Int {
    guard bytes.count >= MemoryLayout<T>.size else {
        throw DeserializationError.invalidElementSize
    }
    
    return UnsafeRawPointer(Bytes(bytes)).assumingMemoryBound(to: T.self).pointee
}

extension Collection where Self.Iterator.Element == Byte, Self.Index == Int {
    public func makeInt32Array() -> [Int32] {
        var array = [Int32]()
        for idx in stride(from: self.startIndex, to: self.endIndex, by: MemoryLayout<Int32>.size) {
            var number: Int32 = 0
            number |= self.count > 3 ? Int32(self[idx.advanced(by: 3)]) << 24 : 0
            number |= self.count > 2 ? Int32(self[idx.advanced(by: 2)]) << 16 : 0
            number |= self.count > 1 ? Int32(self[idx.advanced(by: 1)]) << 8 : 0
            number |= self.count > 0 ? Int32(self[idx]) : 0
            array.append(number)
        }
        
        return array
    }
    
    func makeIntArray() -> [Int] {
        var array = [Int]()
        for idx in stride(from: self.startIndex, to: self.endIndex, by: MemoryLayout<Int>.size) {
            var number: Int = 0
            number |= self.count > 7 ? Int(self[idx.advanced(by: 7)]) << 56 : 0
            number |= self.count > 6 ? Int(self[idx.advanced(by: 6)]) << 48 : 0
            number |= self.count > 5 ? Int(self[idx.advanced(by: 5)]) << 40 : 0
            number |= self.count > 4 ? Int(self[idx.advanced(by: 4)]) << 32 : 0
            number |= self.count > 3 ? Int(self[idx.advanced(by: 3)]) << 24 : 0
            number |= self.count > 2 ? Int(self[idx.advanced(by: 2)]) << 16 : 0
            number |= self.count > 1 ? Int(self[idx.advanced(by: 1)]) << 8 : 0
            number |= self.count > 0 ? Int(self[idx.advanced(by: 0)]) << 0 : 0
            array.append(number)
        }
        
        return array
    }
    
    public func makeInt32() -> Int32 {
        var val: Int32 = 0
        val |= self.count > 3 ? Int32(self[startIndex.advanced(by: 3)]) << 24 : 0
        val |= self.count > 2 ? Int32(self[startIndex.advanced(by: 2)]) << 16 : 0
        val |= self.count > 1 ? Int32(self[startIndex.advanced(by: 1)]) << 8 : 0
        val |= self.count > 0 ? Int32(self[startIndex]) : 0
        
        return val
    }
    
    public func makeInt() -> Int {
        var number: Int = 0
        number |= self.count > 7 ? Int(self[startIndex.advanced(by: 7)]) << 56 : 0
        number |= self.count > 6 ? Int(self[startIndex.advanced(by: 6)]) << 48 : 0
        number |= self.count > 5 ? Int(self[startIndex.advanced(by: 5)]) << 40 : 0
        number |= self.count > 4 ? Int(self[startIndex.advanced(by: 4)]) << 32 : 0
        number |= self.count > 3 ? Int(self[startIndex.advanced(by: 3)]) << 24 : 0
        number |= self.count > 2 ? Int(self[startIndex.advanced(by: 2)]) << 16 : 0
        number |= self.count > 1 ? Int(self[startIndex.advanced(by: 1)]) << 8 : 0
        number |= self.count > 0 ? Int(self[startIndex.advanced(by: 0)]) << 0 : 0
        
        return number
    }
}

extension Document {
    
    internal typealias ElementMetadata = (elementTypePosition: Int, dataPosition: Int, type: ElementType)
    
    internal func buildAndReturnIndex() -> IndexTrieNode {
        self.index(recursive: nil, lookingFor: nil)
        return searchTree
    }
    
    @discardableResult
    internal func index(recursive keys: [IndexKey]? = nil, lookingFor matcher: [IndexKey]?, offset: Int = 0) -> ElementMetadata? {
        if searchTree.fullyIndexed {
            return nil
        }
        
        var position: Int
        
        let thisKey = keys ?? []
        
        if let keys = keys {
            if let pos = searchTree[position: keys] {
                position = pos
            } else {
                fatalError()
            }
        } else {
            position = 0
        }
        
        if keys != nil {
            guard position &+ 2 < self.storage.count else {
                return nil
            }
            
            // elementTypePosition + 1 (key position)
            keySkipper : for i in position + 1..<storage.count {
                guard self.storage[i] != 0 else {
                    // null terminator + length
                    position = i &+ 5
                    break keySkipper
                }
            }
        }
    
        iterator: while position < self.storage.count {
            guard position &+ 2 < self.storage.count else {
                return nil
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return nil
            }
            
            guard position &+ 1 < storage.count else {
                return nil
            }
            
            var buffer = Bytes()
            
            // elementTypePosition + 1 (key position)
            keyBuilder : for i in position + 1..<storage.count {
                guard self.storage[i] != 0 else {
                    break keyBuilder
                }
                
                buffer.append(storage[i])
            }
            
            let key = thisKey + [IndexKey(KittenBytes(buffer))]
            
            searchTree[key] = IndexTrieNode(position &- offset)
            
            let dataPosition = position &+ 1 &+ buffer.count &+ 1
            
            if let matcher = matcher, key == matcher {
                return (position, dataPosition, type)
            }
            
            position = dataPosition &+ self.getLengthOfElement(withDataPosition: dataPosition, type: type)
            
            if type == .document || type == .arrayDocument {
                if let matcher = matcher {
                    guard matcher.count > key.count else {
                        continue iterator
                    }
                    
                    for (pos, key) in key.enumerated() {
                        guard matcher[pos] == key else {
                            continue iterator
                        }
                    }
                }
                
                if let result = index(recursive: key, lookingFor: matcher, offset: dataPosition &+ 4), matcher != nil {
                    return result
                }
            }
        }
    
        if matcher == nil {
            searchTree.fullyIndexed = true
        }
        
//        unset = true
        
        return nil
    }
    
    // MARK: - BSON Parsing Logic
    
    /// This function traverses the document and searches for the type and data belonging to the key
    ///
    /// - parameter keyBytes: The binary (`[Byte]`) representation of the key's `String` as C-String
    ///
    /// - returns: A tuple containing the position of the elementType and the position of the first byte of data
    internal func getMeta(for indexKey: [IndexKey]) -> ElementMetadata? {
        guard let keyByteCount = indexKey.last?.key.bytes.count, let position = searchTree[position: indexKey], position < storage.count else {
            return index(recursive: nil, lookingFor: indexKey)
        }
        
        guard let thisElementType = ElementType(rawValue: storage[position]) else {
            print("Error while parsing BSON document: element type unknown at position \(position).")
            return nil
        }
        
        // dataPosition = Element type, key, null terminator
        return (elementTypePosition: position, dataPosition: position &+ 1 &+ keyByteCount &+ 1, type: thisElementType)
    }

    /// Returns the length of an element in bytes
    ///
    /// - parameter position: The position of the first byte of data for this value
    /// - parameter type: The type of data that we're dealing with
    ///
    /// - returns: The length of the data for this value in bytes
    internal func getLengthOfElement(withDataPosition position: Int, type: ElementType) -> Int {
        // check
        func need(_ amountOfBytes: Int) -> Bool {
            return self.storage.count >= position + amountOfBytes // the document doesn't have a trailing null until the bytes are fetched
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
            
            return Int(storage[position...position+3].makeInt32() + 4)
        case .binary:
            guard need(5) else {
                return 0
            }
            
            return Int(storage[position...position+3].makeInt32() + 5)
        case .document, .arrayDocument, .javascriptCodeWithScope: // Types with their entire length in the first 4 bytes
            guard need(4) else {
                return 0
            }
            
            return Int(storage[position...position+3].makeInt32())
        case .decimal128:
            return 16
        }
    }
    
    /// Caches the Element start positions
    internal func buildElementPositionsCache() -> Dictionary<KittenBytes, Int> {
        var position = 0
        var positions = Dictionary<KittenBytes, Int>()
        
        loop: while position < self.storage.count {
            let startPosition = position
            
            guard self.storage.count - position > 2 else {
                // Invalid document condition
                break loop
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                break loop
            }
            
            position += 1
            
            var buffer = Bytes()
            
            // get the key data
            while self.storage.count > position {
                defer {
                    position += 1
                }
                
                if self.storage[position] == 0 {
                    break
                }
                
                buffer.append(storage[position])
            }
            
            position += self.getLengthOfElement(withDataPosition: position, type: type)
            
            positions[KittenBytes(buffer)] = startPosition
        }
        
        return positions
    }
    
    /// Fetches the info for the key-value at the given position
    ///
    /// - parameter startPosition: The position of the element type identifier, before the key bytes
    internal func getMeta(atPosition startPosition: Int) -> (dataPosition: Int, type: ElementType, startPosition: Int, elementTypePosition: Int)? {
        var position = startPosition
        
        guard self.storage.count - position > 2 else {
            // Invalid document condition
            return nil
        }
        
        guard let type = ElementType(rawValue: self.storage[position]) else {
            return nil
        }
        
        let elementTypePosition = position
        
        position = position &+ 1
        
        // move past the key data
        while self.storage.count > position {
            defer {
                position = position &+ 1
            }
            
            if self.storage[position] == 0 {
                break
            }
        }
        
        return (dataPosition: position, type: type, startPosition: startPosition, elementTypePosition: elementTypePosition)
    }
    
    /// Creates an iterator that loops over all key-value pairs in this `Document`
    ///
    /// - parameter startPos: The byte to start searching from
    ///
    /// - returns: An iterator that iterates over all key-value pairs
    internal func makeKeyIterator(startingAtByte startPos: Int = 0) -> AnyIterator<(dataPosition: Int, type: ElementType, keyData: Bytes, startPosition: Int)> {
        index(recursive: nil, lookingFor: nil)
        
        var iterator = searchTree.storage.sorted(by: { 
            $0.value.value < $1.value.value
        }).makeIterator()
        
        return AnyIterator {
            guard let position = iterator.next()?.1.value else {
                return nil
            }
            
            guard self.storage.count &- position > 2 else {
                // Invalid document condition
                return nil
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return nil
            }
            
            for i in position + 1 ..< self.storage.count {
                if self.storage[i] == 0 {
                    return (dataPosition: i &+ 1, type: type, keyData: Array(self.storage[position + 1..<i]), startPosition: position)
                }
            }
            
            return nil
        }
    }
    
    /// Get's a `Value` from this `Document` given a position and type
    ///
    /// Returns `Value.nothing` when unable to
    ///
    /// - parameter startPosition: The position of this `Value`'s data in the binary `storage`
    /// - parameter type: The BSON `ElementType` that we're looking for here
    internal func getValue(atDataPosition position: Int, withType type: ElementType, kittenString: Bool = false, forIndexKey indexKey: [IndexKey]? = nil) -> Primitive? {
        do {
            
            func remaining() -> Int {
                return storage.endIndex - position
            }
            
            switch type {
            case .double: // double
                guard remaining() >= 8 else {
                    return nil
                }
                
                let double: Double = try fromBytes(storage[position..<position+8])
                return double
            case .string: // string
                // Check for null-termination and at least 5 bytes (length spec + terminator)
                guard remaining() >= 5 else {
                    return nil
                }
                
                // Get the length
                let length: Int32 = storage[position...position+3].makeInt32()
                
                // Check if the data is at least the right size
                guard storage.count-position >= Int(length) + 4 else {
                    return nil
                }
                
                // Empty string
                if length == 1 {
                    return ""
                }
                
                guard length > 0 else {
                    return nil
                }
                
                var stringData = Array(storage[position+4..<position+Int(length + 3)])
                
                if kittenString {
                    return KittenBytes(stringData)
                } else {
                    guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: String.Encoding.utf8, freeWhenDone: false) else {
                        return nil
                    }
                    
                    return string
                }
            case .document, .arrayDocument: // document / array
                guard remaining() >= 5 else {
                    return nil
                }
                
                let length = Int(storage[position..<position+4].makeInt32())
                
                guard remaining() >= length else {
                    return nil
                }
                
                if let indexKey = indexKey, let node = self.searchTree[indexKey] {
                    return Document(data: storage[position + 4..<position+length-1], copying: node)
                } else {
                    return Document(data: storage[position..<position+length])
                }
            case .binary: // binary
                guard remaining() >= 5 else {
                    return nil
                }
                
                let length = Int(storage[position..<position+4].makeInt32())
                let subType = storage[position+4]
                
                guard remaining() >= length + 5 else {
                    return nil
                }
                
                let realData = length > 0 ? Array(storage[position+5...position+4+length]) : []
                
                return Binary(data: realData, withSubtype: Binary.Subtype(rawValue: subType))
            case .objectId: // objectid
                guard remaining() >= 12 else {
                    return nil
                }
                
                if let id = try? ObjectId(bytes: Array(storage[position..<position+12])) {
                    return id
                } else {
                    return nil
                }
            case .boolean:
                guard remaining() >= 1 else {
                    return nil
                }
                
                return storage[position] == 0x00 ? false : true
            case .utcDateTime:
                guard remaining() >= 8 else {
                    return nil
                }
                
                let interval: Int = storage[position..<position+8].makeInt()
                return Date(timeIntervalSince1970: Double(interval) / 1000) // BSON time is in ms
            case .nullValue:
                return NSNull()
            case .regex:
                let k = storage[position..<storage.endIndex].split(separator: 0x00, maxSplits: 2, omittingEmptySubsequences: false)
                guard k.count >= 2 else {
                    return nil
                }
                
                let patternData = Array(k[0])
                let optionsData = Array(k[1])
                
                guard let pattern = try? String.instantiateFromCString(bytes: patternData + [0x00]),
                    let options = try? String.instantiateFromCString(bytes: optionsData + [0x00]) else {
                        return nil
                }
                
                return RegularExpression(pattern: pattern, options: regexOptions(fromString: options))
            case .javascriptCode:
                guard let code = try? String.instantiate(bytes: Array(storage[position..<storage.endIndex])) else {
                    return nil
                }
                
                return JavascriptCode(code)
            case .javascriptCodeWithScope:
                // min length is 14 bytes: 4 for the int32, 5 for the string and 5 for the document
                guard remaining() >= 14 else {
                    return nil
                }
                
                // why did they include this? it's not needed. whatever. we'll validate it.
                let totalLength = Int(storage[position..<position+4].makeInt32())
                guard remaining() >= totalLength else {
                    return nil
                }
                
                let stringDataAndMore = Array(storage[position+4..<position+totalLength])
                var trueCodeSize = 0
                guard let code = try? String.instantiate(bytes: stringDataAndMore, consumedBytes: &trueCodeSize) else {
                    return nil
                }
                
                // - 4 (length) - 5 (document)
                guard stringDataAndMore.count - 4 - 5 >= trueCodeSize else {
                    return nil
                }
                
                let scopeDataAndMaybeMore = Array(stringDataAndMore[trueCodeSize..<stringDataAndMore.endIndex])
                let scope = Document(data: scopeDataAndMaybeMore)
                
                return JavascriptCode(code: code, withScope: scope)
            case .int32: // int32
                guard remaining() >= 4 else {
                    return nil
                }
                
                return storage[position..<position+4].makeInt32()
            case .timestamp:
                guard remaining() >= 8 else {
                    return nil
                }
                
                let stamp = Timestamp(increment: storage[position..<position+4].makeInt32(), timestamp: storage[position+4..<position+8].makeInt32())
                
                return stamp
            case .int64:
                guard remaining() >= 8 else {
                    return nil
                }
                
                return try fromBytes(storage[position..<position+8]) as Int
            case .decimal128:
                guard remaining() >= 16 else {
                    return nil
                }
                
                return Decimal128(slice: storage[position..<position + 16])
            case .minKey: // MinKey
                return MinKey()
            case .maxKey: // MaxKey
                return MaxKey()
            }
        } catch {
            return nil
        }
    }
    
    /// Returns the type for the given element
    ///
    /// For example: `type(at: 2)` returns the type for the third element
    ///
    /// - parameter key: The key to look for and return it's `ElementType`
    ///
    /// - returns: An element type for the given element
    public func type(at key: Int) -> ElementType? {
        let indexKey = makeIndexKey(from: [key])
        return getMeta(for: indexKey)?.type
    }
    
    /// Returns the type for the given element
    ///
    /// For example: `type(at: 2)` returns the type for the third element
    ///
    /// - parameter key: The key to look for and return it's `ElementType`
    ///
    /// - returns: An element type for the given element
    public func type(at key: String) -> ElementType? {
        let indexKey = makeIndexKey(from: [key])
        return getMeta(for: indexKey)?.type
    }
}
