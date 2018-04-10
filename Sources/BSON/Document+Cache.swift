import Foundation

final class DocumentCache {
    struct Dimensions {
        var type: UInt8
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
    
    func valueLength(forType type: UInt8, at offset: Int) -> Int? {
        switch type {
        case .string, .javascript:
            guard offset &+ 4 < self.storage.usedCapacity else {
                return nil
            }
            
            let stringLength = self.storage.readBuffer.baseAddress!.advanced(by: offset).int32
            
            return 4 &+ numericCast(stringLength)
        case .document, .array:
            guard offset &+ 4 < self.storage.usedCapacity else {
                return nil
            }
            
            let documentLength = self.storage.readBuffer.baseAddress!.advanced(by: offset).int32
            
            return numericCast(documentLength)
        case .binary:
            guard offset &+ 5 < self.storage.usedCapacity else {
                return nil
            }
            
            let binaryLength = self.storage.readBuffer.baseAddress!.advanced(by: offset).int32
            
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
            let offset = storage.cString(at: offset)
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
        default:
            return nil
        }
    }
    
    enum ScanMode {
        case key(String)
        case single
        case all
    }
    
    func scanValue(startingAt position: Int, mode: ScanMode) -> DocumentCache.Dimensions? {
        var position = position
        
        while position < self.storage.usedCapacity {
            let basePosition = position
            let type = self.storage.readBuffer[position]
            position = position &+ 1
            
            let cStringStart = storage.readBuffer.baseAddress!.advanced(by: position)
            let keyLength = storage.cString(at: position)
            position = position &+ keyLength
            
            let readKey = String(cString: cStringStart)
            
            guard let valueLength = self.valueLength(forType: type, at: position) else {
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
    
    func readKey(atDimensions dimensions: DocumentCache.Dimensions) -> String {
        return String(cString: self.storage.readBuffer.baseAddress!.advanced(by: dimensions.from &+ 1))
    }
    
    func readPrimitive(type: UInt8, offset: Int, length: Int) -> Primitive? {
        let pointer = self.storage.readBuffer.baseAddress!.advanced(by: offset)
        
        switch type {
        case .double:
            return pointer.withMemoryRebound(to: Double.self, capacity: 1) { $0.pointee }
        case .string:
            let buffer = self.storage.readBuffer
            
            var basePointer = buffer.baseAddress!.advanced(by: offset)
            
            let length = numericCast(basePointer.int32) as Int
            basePointer += 4
            
            if offset &+ 4 &+ length > self.storage.usedCapacity {
                // Corrupt data
                return nil
            }
            
            let stringBuffer = UnsafeBufferPointer(start: basePointer, count: length)
            
            let stringData = Data(buffer: stringBuffer)
            
            return String(
                data: stringData[..<stringData.endIndex.advanced(by: -1)],
                encoding: .utf8
            )
        case .document, .array:
            fatalError()
        case .binary:
            return nil
        case .objectId:
            return ObjectId(storage[offset..<offset &+ 12])
        case .boolean:
            return pointer.pointee == 0x01
        case .datetime:
            return nil
        case .timestamp:
            return nil
        case .int64:
            return pointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
        case .null:
            return nil
        case .minKey:
            return nil
        case .maxKey:
            // no data
            // Still need to check the key's size
            return nil
        case .regex:
            return nil
        case .javascript:
            return nil
        case .javascriptWithScope:
            return nil
        case .int32:
            return pointer.withMemoryRebound(to: Int32.self, capacity: 1) { $0.pointee }
        case .decimal128:
            return nil
        default:
            return nil
        }
    }
    
    subscript(keyFor dimensions: DocumentCache.Dimensions) -> String {
        return self.readKey(atDimensions: dimensions)
    }
    
    subscript(valueFor dimensions: DocumentCache.Dimensions) -> Primitive {
        return self.readPrimitive(atDimensions: dimensions)!
    }
    
    subscript(dimensionsAt index: Int) -> DocumentCache.Dimensions {
        return self.cache.storage[index].1
    }
}
