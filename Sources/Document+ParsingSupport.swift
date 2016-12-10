//
//  Document+InternalByteLevelOperations.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

public func fromBytes<T, S : Collection>(_ bytes: S) throws -> T where S.Iterator.Element == UInt8, S.IndexDistance == Int {
    guard bytes.count >= MemoryLayout<T>.size else {
        throw DeserializationError.invalidElementSize
    }
    
    return UnsafeRawPointer([UInt8](bytes)).assumingMemoryBound(to: T.self).pointee
}

extension Document {
    
    // MARK: - BSON Parsing Logic
    
    /// This function traverses the document and searches for the type and data belonging to the key
    ///
    /// - parameter keyBytes: The binary (`[Byte]`) representation of the key's `String` as C-String
    ///
    /// - returns: A tuple containing the position of the elementType and the position of the first byte of data
    internal func getMeta(forKeyBytes keyBytes: [UInt8]) -> (elementTypePosition: Int, dataPosition: Int, type: ElementType)? {
        for var position in elementPositions {
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
                
                if character == 0 {
                    if keyBytes.count != keyPos {
                        isKey = false
                    }
                    
                    didEnd = true
                    break keyComparison // end of key data
                } else if isKey && keyBytes.count > keyPos {
                    isKey = keyBytes[keyPos] == character
                } else {
                    isKey = false
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
    
    /// Returns the length of an element in bytes
    ///
    /// - parameter position: The position of the first byte of data for this value
    /// - parameter type: The type of data that we're dealing with
    ///
    /// - returns: The length of the data for this value in bytes
    internal func getLengthOfElement(withDataPosition position: Int, type: ElementType) -> Int {
        do {
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
                
                return Int(try fromBytes(storage[position...position+3]) as Int32 + 4)
            case .binary:
                guard need(5) else {
                    return 0
                }
                
                return Int(try fromBytes(storage[position...position+3]) as Int32) + 5
            case .document, .arrayDocument, .javascriptCodeWithScope: // Types with their entire length in the first 4 bytes
                guard need(4) else {
                    return 0
                }
                
                return Int(try fromBytes(storage[position...position+3]) as Int32)
            }
        } catch {
            return 0
        }
    }
    
    /// Caches the Element start positions
    internal func buildElementPositionsCache() -> [Int] {
        var position = 4
        
        let iterator = AnyIterator<Int> {
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
            while self.storage.count > position {
                defer {
                    position += 1
                }
                
                if self.storage[position] == 0 {
                    break
                }
            }
            
            position += self.getLengthOfElement(withDataPosition: position, type: type)
            
            return startPosition
        }
        
        var cache = [Int]()
        
        for num in iterator {
            cache.append(num)
        }
        
        return cache
    }
    
    /// Fetches the info for the key-value at the given position
    ///
    /// - parameter startPosition: The position of the element type identifier, before the key bytes
    internal func getMeta(atPosition startPosition: Int) -> (dataPosition: Int, type: ElementType, startPosition: Int)? {
        var position = startPosition
        
        guard self.storage.count - position > 2 else {
            // Invalid document condition
            return nil
        }
        
        guard let type = ElementType(rawValue: self.storage[position]) else {
            return nil
        }
        
        position += 1
        
        // move past the key data
        while self.storage.count > position {
            defer {
                position += 1
            }
            
            if self.storage[position] == 0 {
                break
            }
        }
        
        return (dataPosition: position, type: type, startPosition: startPosition)
    }
    
    /// Creates an iterator that loops over all key-value pairs in this `Document`
    ///
    /// - parameter startPos: The byte to start searching from
    ///
    /// - returns: An iterator that iterates over all key-value pairs
    internal func makeKeyIterator(startingAtByte startPos: Int = 4) -> AnyIterator<(dataPosition: Int, type: ElementType, keyData: [UInt8], startPosition: Int)> {
        var index = 0
        
        return AnyIterator {
            defer {
                index += 1
            }
            
            guard self.elementPositions.count > index else {
                return nil
            }
            
            let startPosition = self.elementPositions[index]
            var position = startPosition
            
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
    
    /// Get's a `Value` from this `Document` given a position and type
    ///
    /// Returns `Value.nothing` when unable to
    ///
    /// - parameter startPosition: The position of this `Value`'s data in the binary `storage`
    /// - parameter type: The BSON `ElementType` that we're looking for here
    internal func getValue(atDataPosition startPosition: Int, withType type: ElementType) -> Value {
        do {
            var position = startPosition
            
            func remaining() -> Int {
                return storage.endIndex - startPosition
            }
            
            switch type {
            case .double: // double
                guard remaining() >= 8 else {
                    return .nothing
                }
                
                let double: Double = try fromBytes(storage[position..<position+8])
                return .double(double)
            case .string: // string
                // Check for null-termination and at least 5 bytes (length spec + terminator)
                guard remaining() >= 5 else {
                    return .nothing
                }
                
                // Get the length
                let length: Int32 = try fromBytes(storage[position...position+3])
                
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
                
                let length = Int(try fromBytes(storage[position..<position+4]) as Int32)
                
                guard remaining() >= length else {
                    return .nothing
                }
                
                let subData = Array(storage[position..<position+length])
                let document = Document(data: subData)
                return type == .document ? .document(document) : .array(document)
            case .binary: // binary
                guard remaining() >= 5 else {
                    return .nothing
                }
                
                let length = Int(try fromBytes(storage[position..<position+4]) as Int32)
                let subType = storage[position+4]
                
                guard remaining() >= length + 5 else {
                    return .nothing
                }
                
                let realData = length > 0 ? Array(storage[position+5...position+4+length]) : []
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
                
                let interval: Int64 = try fromBytes(storage[position..<position+8])
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
                let totalLength = Int(try fromBytes(storage[position..<position+4]) as Int32)
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
                
                return .int32(try fromBytes(storage[position..<position+4]))
            case .timestamp:
                guard remaining() >= 8 else {
                    return .nothing
                }
                
                let stamp: Int32 = try fromBytes(storage[position..<position+4])
                let increment: Int32 = try fromBytes(storage[position+4..<position+8])
                
                return .timestamp(stamp: stamp, increment: increment)
            case .int64: // timestamp, int64
                guard remaining() >= 8 else {
                    return .nothing
                }
                
                return .int64(try fromBytes(storage[position..<position+8]))
            case .minKey: // MinKey
                return .minKey
            case .maxKey: // MaxKey
                return .maxKey
            }
        } catch {
            return .nothing
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
        guard self.elementPositions.count > key && key >= 0 else {
            return nil
        }
        
        let position = self.elementPositions[key]
        return ElementType(rawValue: storage[position])
    }
    
    /// Returns the type for the given element
    ///
    /// For example: `type(at: 2)` returns the type for the third element
    ///
    /// - parameter key: The key to look for and return it's `ElementType`
    ///
    /// - returns: An element type for the given element
    public func type(at key: String) -> ElementType? {
        return getMeta(forKeyBytes: [UInt8](key.utf8))?.type
    }
}
