//
//  Document+InternalByteLevelOperations.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document {
    
    // MARK: - BSON Parsing Logic
    
    internal typealias ElementMetadata = (elementTypePosition: Int, dataPosition: Int, type: ElementType)
    
    internal func buildAndReturnIndex() -> IndexTrieNode {
        self.index(recursive: nil, lookingFor: nil)
        return searchTree
    }
    
    /// Searches through this document and it's subdocument until the matching key has been found.
    ///
    /// Incrementally updates the index as it goes along and continues where it left until either the key is found, doesn't exist or the level depth has been reached.
    ///
    /// - parameter keys: The key path to start looking from, useful for continueing a recursive search. If nil, start top-level.
    /// - parameter matcher: The key path to look for recursively. If nil, it will look for everything
    /// - parameter levels: The depth to stop scanning at. `0` is top level.
    @discardableResult
    internal func index(recursive keys: [IndexKey]? = nil, lookingFor matcher: [IndexKey]?, levels: Int? = nil) -> ElementMetadata? {
        // If the key path is indexes, return the data about this key path
        if searchTree.recursivelyIndexed {
            guard let matcher = matcher, let pos = searchTree[position: matcher] else {
                return nil
            }
            
            guard let type = ElementType(rawValue: self.storage[pos]) else {
                return nil
            }
            
            keySkipper : for i in pos &+ 1..<storage.count {
                guard self.storage[i] != 0 else {
                    return (pos, i &+ 1, type)
                }
            }
            
            return nil
        }
        
        shortCut: if let levels = levels, matcher == nil, self.searchTree.fullyIndexed, levels == 0 {
            return nil
        }
        
        var position: Int
        
        let thisKey = keys ?? []
        
        // Look for the place to resume, or start from nothing
        resumeCheck: if let matcher = matcher, let pos = searchTree[position: matcher] {
            position = pos
        } else if var keys = keys {
            if let pos = searchTree[position: keys] {
                if searchTree[keys]?.recursivelyIndexed == true {
                    return nil
                }
                
                position = pos
            } else {
                var keys2 = [IndexKey]()
                
                while keys.count > 0 {
                    keys2.append(keys.removeLast())
                    
                    if let pos = searchTree[position: keys] {
                        position = pos
                        break resumeCheck
                    }
                }
                
                position = 0
            }
        } else {
            position = 0
        }
        
        // Skip over the last key, to the start of the elements
        if keys != nil {
            guard position &+ 2 < self.storage.count else {
                return nil
            }
            
            // elementTypePosition + 1 (key position)
            keySkipper : for i in position &+ 1..<storage.count {
                guard self.storage[i] != 0 else {
                    // null terminator + length
                    position = i &+ 5
                    break keySkipper
                }
            }
        }
        
        let basePosition = position
        
        // Iterate over all keys, caching as we go along
        iterator: while position < self.storage.count {
            guard position &+ 2 < self.storage.count else {
                return nil
            }
            
            // Extract the type
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return nil
            }
            
            guard position &+ 1 < storage.count else {
                return nil
            }
            
            var buffer = Bytes()
            
            // Iterate over the key, put it into the buffer
            keyBuilder : for i in position + 1..<storage.count {
                guard self.storage[i] != 0 else {
                    break keyBuilder
                }
                
                buffer.append(storage[i])
            }
            
            let key = thisKey + [IndexKey(KittenBytes(buffer))]
            
            // Create an index for this entry
            searchTree[key] = IndexTrieNode(position &- basePosition)
            
            let dataPosition = position &+ 1 &+ buffer.count &+ 1
            
            // If there's a match, return thr results
            if let matcher = matcher, key == matcher {
                return (position, dataPosition, type)
            }
            
            let len = getLengthOfElement(withDataPosition: dataPosition, type: type)
            
            guard len >= 0 else {
                return nil
            }
            
            // Skip to the next key
            position = dataPosition &+ len
            
            // If this element was a Document
            if type == .document || type == .arrayDocument {
                // If there was a matcher, continue iterating if this wasn't a match, otherwise, dive in!
                // If there was no matcher, dive in anyways
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
                
                // Diving in? Sure. But don't go too deep if there's a depth specified
                if let levels = levels {
                    guard levels > 0 else {
                        continue iterator
                    }
                    
                    if let result = index(recursive: key, lookingFor: matcher, levels: levels &- 1), matcher != nil {
                        return result
                    }
                }
                
                if let result = index(recursive: key, lookingFor: matcher), matcher != nil {
                    return result
                }
            }
        }
        
        if let keys = keys {
            self.searchTree[keys]?.recursivelyIndexed = true
        } else if levels == nil || levels == 0 {
            self.searchTree.recursivelyIndexed = self.searchTree.storage.values.reduce(true) { $0.1.recursivelyIndexed && $0.0 }
        }
        
        self.searchTree.fullyIndexed = true
        
        return nil
    }
    
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
                return -1
            }
            
            return Int(Int32(storage[position...position+3]) + 4)
        case .binary:
            guard need(5) else {
                return -1
            }
            
            return Int(Int32(storage[position...position+3]) + 5)
        case .document, .arrayDocument, .javascriptCodeWithScope: // Types with their entire length in the first 4 bytes
            guard need(4) else {
                return -1
            }
            
            return Int(Int32(storage[position...position+3]))
        case .decimal128:
            return 16
        }
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
        self.index(recursive: nil, lookingFor: nil, levels: 0)
        let storageCopy = searchTree.storage
        var iterator = storageCopy.sorted(by: {
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
            case .javascriptCode:
                // Check for null-termination and at least 5 bytes (length spec + terminator)
                guard remaining() >= 5 else {
                    return nil
                }
                
                // Get the length
                let length: Int32 = Int32(storage[position...position+3])
                
                // Check if the data is at least the right size
                guard storage.count-position >= Int(length) + 4 else {
                    return nil
                }
                
                // Empty string
                if length == 1 {
                    return JavascriptCode(code: "")
                }
                
                guard length > 0 else {
                    return nil
                }
                
                let stringData = Array(storage[position+4..<position+Int(length + 3)])
                
                guard let code = String(bytes: stringData, encoding: .utf8) else {
                    return nil
                }
                
                return JavascriptCode(code: code)
            case .string: // string
                // Check for null-termination and at least 5 bytes (length spec + terminator)
                guard remaining() >= 5 else {
                    return nil
                }
                
                // Get the length
                let length: Int32 = Int32(storage[position...position+3])
                
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
                
                let stringData = Array(storage[position+4..<position+Int(length + 3)])
                
                if kittenString {
                    return KittenBytes(stringData)
                } else {
                    return String(bytes: stringData, encoding: .utf8)
                }
            case .document, .arrayDocument: // document / array
                guard remaining() >= 5 else {
                    return nil
                }
                
                let length = Int(Int32(storage[position..<position+4]))
                
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
                
                let length = Int(Int32(storage[position..<position+4]))
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
                
                switch storage[position] {
                case 0x00:
                    return false
                case 0x01:
                    return true
                default:
                    return nil
                }
            case .utcDateTime:
                guard remaining() >= 8 else {
                    return nil
                }
                
                let interval: Int = Int(storage[position..<position+8])
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
            case .javascriptCodeWithScope:
                // min length is 14 bytes: 4 for the int32, 5 for the string and 5 for the document
                guard remaining() >= 14 else {
                    return nil
                }
                
                // why did they include this? it's not needed. whatever. we'll validate it.
                let totalLength = Int(Int32(storage[position..<position+4]))
                guard remaining() >= totalLength else {
                    return nil
                }
                
                let stringDataAndMore = Array(storage[position+4..<position+totalLength])
                var trueCodeSize = 0
                guard let code = try? String.instantiate(bytes: stringDataAndMore, consumedBytes: &trueCodeSize) else {
                    return nil
                }
                
                let scopeDataAndMaybeMore = Array(stringDataAndMore[trueCodeSize..<stringDataAndMore.endIndex])
                let scope = Document(data: scopeDataAndMaybeMore)
                
                return JavascriptCode(code: code, withScope: scope)
            case .int32: // int32
                guard remaining() >= 4 else {
                    return nil
                }
                
                return Int32(storage[position..<position+4])
            case .timestamp:
                guard remaining() >= 8 else {
                    return nil
                }
                
                let stamp = Timestamp(increment: Int32(storage[position..<position+4]), timestamp: Int32(storage[position+4..<position+8]))
                
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
