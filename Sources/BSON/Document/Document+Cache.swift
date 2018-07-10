import Foundation

final class DocumentCache {
    struct Dimensions {
        var type: TypeIdentifier
        var from: Int
        var keyCString: Int
        var valueLength: Int
        
        var end: Int {
            // Type Identifier, CString, value
            return from &+ 1 &+ keyCString &+ valueLength
        }
        
        var fullLength: Int {
            return keyCString &+ valueLength
        }
    }
    
    var storage = [(String, Dimensions)]()
    
    init() {}
}

extension Document {
    var fullyCached: Bool {
        return self.lastScannedPosition >= self.count &- 1
    }
    
    var lastScannedPosition: Int {
        var lastDimensions: Int?
        
        for (_, dimensions) in self.cache.storage {
            if let existingDimensions = lastDimensions, existingDimensions < dimensions.end {
                lastDimensions = dimensions.end
            } else if lastDimensions == nil {
                lastDimensions = dimensions.end
            }
        }
        
        return lastDimensions ?? 4
    }
    
    func dimension(forKey key: String) -> DocumentCache.Dimensions? {
        for (dimensionKey, dimension) in cache.storage where dimensionKey == key {
            return dimension
        }
        
        return nil
    }
    
    func getCached(byKey key: String) -> Primitive? {
        let dimensions: DocumentCache.Dimensions
        
        if let d = dimension(forKey: key) {
            dimensions = d
        } else if let d = scanValue(startingAt: lastScannedPosition, mode: .key(key)) {
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
            // Still need to check the key's size
            return 0
        case .regex:
            let offset = self.storage.cString(at: offset)
            let optionsEnd = storage.cString(at: offset)
            
            return optionsEnd &- offset
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
    
    func scanValue(startingAt position: Int, mode: ScanMode) -> DocumentCache.Dimensions? {
        self.storage.moveReaderIndex(to: position)
        
        while self.storage.readableBytes > 0 {
            guard let typeId: UInt8 = self.storage.readInteger() else {
                return nil
            }
            
            let cStringStart = storage.readBuffer.baseAddress!.advanced(by: position)
            let keyLength = storage.cString(at: position)
            position = position &+ keyLength
            
            let readKey = String(cString: cStringStart)
            
            guard
                let type = TypeIdentifier(rawValue: typeId),
                let valueLength = self.valueLength(forType: type, at: position)
            else {
                return nil
            }
            
            position = position &+ valueLength
            
            let dimension = DocumentCache.Dimensions(
                type: type,
                from: basePosition,
                keyCString: keyLength,
                valueLength: valueLength
            )
            
            self.cache.storage.append((readKey, dimension))
            
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
        return self.readPrimitive(type: dimensions.type, offset: dimensions.from &+ 1 &+ dimensions.keyCString, length: dimensions.valueLength)
    }
    
    func readKey(atDimensions dimensions: DocumentCache.Dimensions) -> String? {
        return storage.getString(at: dimensions.from &+ 1, length: dimensions.keyCString &- 1)
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
                return self.storage.getString(at: offset &+ 4, length: numericCast(length))
            } else if type == .document || type == .array {
                return Document(
                    storage: storage[offset..<offset &+ length &- 1],
                    cache: DocumentCache(),
                    isArray: type == .array
                )
            } else {
                basePointer += 5
                
                // Offset + Size + SubType + Data
                if offset &+ 5 &+ length > self.storage.usedCapacity {
                    // Corrupt data
                    return nil
                }
                
                return Binary(storage: storage[offset..<offset &+ length])
            }
        case .objectId:
            guard let bytes = storage.getBytes(at: offset, length: 12) else {
                return nil
            }
            
            return ObjectId(bytes)
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
            unimplemented()
        case .javascript:
            unimplemented()
        case .javascriptWithScope:
            unimplemented()
        case .int32:
            return self.storage.getInteger(at: offset, endianness: .little, as: Int32.self)
        case .decimal128:
            guard let data = storage.getBytes(at: offset, length: 16) else {
                return nil
            }
            
            return Decimal128(data)
        }
    }
    
    subscript(valueFor dimensions: DocumentCache.Dimensions) -> Primitive {
        return self.readPrimitive(atDimensions: dimensions)!
    }
    
    subscript(dimensionsAt index: Int) -> DocumentCache.Dimensions {
        return self.cache.storage[index].1
    }
}
