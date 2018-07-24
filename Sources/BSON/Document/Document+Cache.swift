import Foundation

final class DocumentCache {
    struct Dimensions {
        var type: TypeIdentifier
        var from: Int
        var keyLengthWithNull: Int
        var valueLength: Int
        
        var end: Int {
            // Type Identifier, CString, value
            return from &+ 1 &+ keyLengthWithNull &+ valueLength
        }
        
        var fullLength: Int {
            return 1 &+ keyLengthWithNull &+ valueLength
        }
    }
    
    typealias Element = (String, Dimensions)
    typealias Storage = [Element]
    private var storage: Storage
    
    init(storage: Storage = .init()) {
        self.storage = storage
    }
    
    func copy() -> DocumentCache {
        return DocumentCache(storage: self.storage)
    }
    
    // MARK: Mutating the cache
    
    func add(_ element: Element) {
        storage.append(element)
    }
    
    /// Alters the cache for the deletion of the value at `position`, by removing the element
    /// at the given position from the cache and updating the `from` values of all elements after
    /// the item at the `position`.
    func handleRemovalOfItem(atPosition position: Int) {
        var removedDimensions: Dimensions? = nil
        
        storage = storage.compactMap { (key, dimensions) in
            if let removedDimensions = removedDimensions {
                // dimensions after the position must be updated
                var newDimensions = dimensions
                newDimensions.from &-= removedDimensions.fullLength
                return (key, newDimensions)
            } else if dimensions.from < position {
                // dimensions before the position are not affected
                return (key, dimensions)
            } else if dimensions.from == position {
                // the dimensions at the position need to be removed
                removedDimensions = dimensions
                return nil
            }
            
            fatalError("Unreachable code reached - please file an issue")
        }
        
        assert(removedDimensions != nil)
    }
    
    func replace(_ dimensionsToReplace: Dimensions, with newDimensions: Dimensions, newKey: String) {
        precondition(dimensionsToReplace.from == newDimensions.from, "Can only replace dimensions with new dimensions at the same position")
        
        storage = storage.compactMap { (key, dimensions) in
            if dimensions.from < dimensionsToReplace.from {
                // dimensions before the position are not affected
                return (key, dimensions)
            } else if dimensions.from == newDimensions.from {
                return (newKey, newDimensions)
            } else {
                // dimensions after the position need to be updated
                let sizeDifference = dimensionsToReplace.fullLength &- newDimensions.fullLength
                var newDimensionsAtThisPosition = dimensions
                newDimensionsAtThisPosition.from &-= sizeDifference
                return (key, newDimensionsAtThisPosition)
            }
        }
    }
    
    // MARK: Examining the cache
    
    var cachedDimensions: [Dimensions] {
        return storage.map { $0.1 }
    }
    
    var cachedKeys: [String] {
        return storage.map { $0.0 }
    }
    
    var count: Int {
        return storage.count
    }
    
    subscript(index: Int) -> Element {
        return storage[index]
    }
    
    var lastScannedPosition: Int {
        var lastDimensions: Int?
        
        for (_, dimensions) in storage {
            if let existingDimensions = lastDimensions, existingDimensions < dimensions.end {
                lastDimensions = dimensions.end
            } else if lastDimensions == nil {
                lastDimensions = dimensions.end
            }
        }
        
        return lastDimensions ?? 4
    }
    
    func dimensions(forKey key: String) -> Dimensions? {
        for (dimensionKey, dimension) in storage where dimensionKey == key {
            return dimension
        }
        
        return nil
    }
}

extension Document {
    mutating func prepareCacheForMutation() {
        if !isKnownUniquelyReferenced(&cache) {
            cache = cache.copy()
        }
    }
    
    var fullyCached: Bool {
        return cache.lastScannedPosition >= self.usedCapacity &- 1
    }
    
    func getCached(byKey key: String) -> Primitive? {
        let dimensions: DocumentCache.Dimensions
        
        if let d = cache.dimensions(forKey: key) {
            dimensions = d
        } else if let d = scanValue(startingAt: cache.lastScannedPosition, mode: .key(key)) {
            dimensions = d
        } else {
            return nil
        }
        
        return readPrimitive(atDimensions: dimensions)
    }
    
    func valueLength(forType type: TypeIdentifier, at offset: Int) -> Int? {
        switch type {
        case .string, .javascript:
            guard let binaryLength = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            return numericCast(4 &+ binaryLength)
        case .document, .array:
            guard let documentLength = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            return numericCast(documentLength)
        case .binary:
            guard let binaryLength = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            // int32 + subtype + bytes
            return numericCast(5 &+ binaryLength)
        case .objectId:
            return 12
        case .boolean:
            return 1
        case .datetime, .timestamp, .int64, .double:
            return 8
        case .null, .minKey, .maxKey:
            // no data
            return 0
        case .regex:
            var slice = storage.slice()
            slice.moveReaderIndex(to: offset)
            
            guard let patternEndOffset = slice.firstRelativeIndexOf(byte: 0x00) else {
                return nil
            }
            
            slice.moveReaderIndex(forwardBy: patternEndOffset)
            
            guard let optionsEndOffset = slice.firstRelativeIndexOf(byte: 0x00) else {
                return nil
            }
            
            return patternEndOffset + optionsEndOffset
        case .javascriptWithScope:
            guard let string = valueLength(forType: .string, at: offset) else {
                return nil
            }
            
            guard let document = valueLength(forType: .document, at: offset) else {
                return nil
            }
            
            return string &+ document
        case .int32:
            return 4
        case .decimal128:
            return 16
        }
    }
    
    enum ScanMode {
        case key(String)
        case single
        case all
    }
    
    func ensureFullyCached() {
        if !self.fullyCached {
            _ = self.scanValue(startingAt: cache.lastScannedPosition, mode: .all)
        }
    }
    
    func scanValue(startingAt position: Int, mode: ScanMode) -> DocumentCache.Dimensions? {
        var storage = self.storage
        storage.moveReaderIndex(to: position)
        
        while storage.readableBytes > 1 {
            let basePosition = storage.readerIndex
            
            guard let typeId = storage.readInteger(endianness: .little, as: UInt8.self) else {
                return nil
            }
            
            guard let keyLengthWithNull = storage.firstRelativeIndexOf(byte: 0) else {
                return nil
            }
            
            guard let readKey = storage.readString(length: keyLengthWithNull-1) else {
                return nil
            }
            
            // advance past null terminator
            storage.moveReaderIndex(forwardBy: 1)
            
            guard
                let type = TypeIdentifier(rawValue: typeId),
                let valueLength = self.valueLength(forType: type, at: storage.readerIndex)
            else {
                return nil
            }
            
            let dimension = DocumentCache.Dimensions(
                type: type,
                from: basePosition,
                keyLengthWithNull: keyLengthWithNull,
                valueLength: valueLength
            )
            
            cache.add((readKey, dimension))
            storage.moveReaderIndex(forwardBy: valueLength)
            
            switch mode {
            case .key(let key):
                if readKey == key {
                    return dimension
                }
            case .single:
                return nil
            case .all:
                continue
            }
        }
        
        return nil
    }
    
    func readPrimitive(atDimensions dimensions: DocumentCache.Dimensions) -> Primitive? {
        return self.readPrimitive(type: dimensions.type, offset: dimensions.from &+ 1 &+ dimensions.keyLengthWithNull, length: dimensions.valueLength)
    }
    
    func readKey(atDimensions dimensions: DocumentCache.Dimensions) -> String {
        // + 1 for the type identifier
        // - 1 for the null terminator
        guard let key = storage.getString(at: dimensions.from &+ 1, length: dimensions.keyLengthWithNull &- 1) else {
            assertionFailure("Key not found for dimensions \(dimensions)")
            return ""
        }
        
        return key
    }
    
    func readPrimitive(type: TypeIdentifier, offset: Int, length: Int) -> Primitive? {
        switch type {
        case .double:
            return self.storage.getDouble(at: offset)
        case .string, .binary, .document, .array:
            guard let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            if type == .string {
                return self.storage.getString(at: offset &+ 4, length: numericCast(length) - 1)
            } else if type == .document || type == .array {
                guard let slice = self.storage.getSlice(at: offset, length: numericCast(length)) else {
                    return nil
                }
                
                return Document(
                    storage: slice,
                    cache: DocumentCache(),
                    isArray: type == .array
                )
            } else {
                guard
                    let subType = self.storage.getByte(at: offset &+ 4),
                    let slice = self.storage.getSlice(at: offset &+ 5, length: numericCast(length))
                else {
                    return nil
                }
                
                return Binary(subType: Binary.SubType(subType), buffer: slice)
            }
        case .objectId:
            guard let slice = storage.getSlice(at: offset, length: 12) else {
                return nil
            }
            
            return ObjectId(slice)
        case .boolean:
            return storage.getByte(at: offset) == 0x01
        case .datetime:
            guard let timestamp = self.storage.getInteger(at: offset, endianness: .little, as: Int64.self) else {
                return nil
            }
            
            return Date(timeIntervalSince1970: Double(timestamp) / 1000)
        case .timestamp:
            guard
                let increment = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
                let timestamp = self.storage.getInteger(at: offset &+ 4, endianness: .little, as: Int32.self)
            else {
                return nil
            }
            
            return Timestamp(increment: increment, timestamp: timestamp)
        case .int64:
            return self.storage.getInteger(at: offset, endianness: .little, as: Int.self)
        case .null:
            return Null()
        case .minKey:
            return MinKey()
        case .maxKey:
            // no data
            // Still need to check the key's size
            return MaxKey()
        case .regex:
            var buffer = storage
            buffer.moveReaderIndex(to: offset)
            guard let patternEnd = buffer.firstRelativeIndexOf(byte: 0x00), let pattern = buffer.readString(length: patternEnd - 1) else {
                return nil
            }
            
            buffer.moveReaderIndex(forwardBy: 1)
            
            guard let optionsEnd = buffer.firstRelativeIndexOf(byte: 0x00), let options = buffer.readString(length: optionsEnd - 1) else {
                return nil
            }
            
            return RegularExpression(pattern: pattern, options: options)
        case .javascript:
            unimplemented()
        case .javascriptWithScope:
            unimplemented()
        case .int32:
            return self.storage.getInteger(at: offset, endianness: .little, as: Int32.self)
        case .decimal128:
            guard let slice = storage.getSlice(at: offset, length: 16) else {
                return nil
            }
            
            return Decimal128(slice)
        }
    }
    
    subscript(valueFor dimensions: DocumentCache.Dimensions) -> Primitive {
        return self.readPrimitive(atDimensions: dimensions)!
    }
}
