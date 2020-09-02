import Foundation

extension Document {
    func valueLength(forType type: TypeIdentifier, at offset: Int) -> Int? {
        switch type {
        case .string, .javascript: // Int32 is excluding the int32 header
            guard let binaryLength = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            return numericCast(4 &+ binaryLength)
        case .document, .array, .javascriptWithScope: // Int32 is including the int32 header
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
            guard let patternEndOffset = storage.firstRelativeIndexOf(startingAt: offset) else {
                return nil
            }
            
            guard let optionsEndOffset = storage.firstRelativeIndexOf(startingAt: offset + patternEndOffset + 1) else {
                return nil
            }
            
            return patternEndOffset + 1 + optionsEndOffset + 1
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
    
    func readPrimitive(type: TypeIdentifier, offset: Int, length: Int) -> Primitive? {
        switch type {
        case .double:
            return self.storage.getDouble(at: offset)
        case .string:
            guard let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            // Omit the null terminator as we don't use/need that in Swift
            return self.storage.getString(at: offset &+ 4, length: numericCast(length) - 1)
        case .binary:
            guard let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            guard
                let subType = self.storage.getByte(at: offset &+ 4),
                let slice = self.storage.getSlice(at: offset &+ 5, length: numericCast(length))
            else {
                return nil
            }
            
            return Binary(subType: Binary.SubType(subType), buffer: slice)
        case .document, .array:
            guard
                let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
                let slice = self.storage.getSlice(at: offset, length: numericCast(length))
            else {
                return nil
            }
            
            return Document(
                buffer: slice,
                isArray: type == .array
            )
        case .objectId:
            return storage.getObjectId(at: offset)
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
            return self.storage.getInteger(at: offset, endianness: .little, as: _BSON64BitInteger.self)
        case .null:
            return Null()
        case .minKey:
            return MinKey()
        case .maxKey:
            // no data
            // Still need to check the key's size
            return MaxKey()
        case .regex:
            guard
                let patternEnd = storage.firstRelativeIndexOf(startingAt: offset),
                let pattern = storage.getString(at: offset, length: patternEnd - 1)
            else {
                return nil
            }

            guard
                let optionsEnd = storage.firstRelativeIndexOf(startingAt: offset + patternEnd),
                let options = storage.getString(at: offset + patternEnd, length: optionsEnd - 1)
            else {
                return nil
            }

            return RegularExpression(pattern: pattern, options: options)
        case .javascript:
            guard
                let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
                let code = self.storage.getString(at: offset &+ 4, length: numericCast(length) - 1)
            else {
                return nil
            }
            
            return JavaScriptCode(code)
        case .javascriptWithScope:
            guard let length = self.storage.getInteger(at: offset, endianness: .little, as: Int32.self) else {
                return nil
            }
            
            guard
                let codeLength = self.storage.getInteger(at: offset &+ 4, endianness: .little, as: Int32.self),
                let code = self.storage.getString(at: offset &+ 8, length: numericCast(length) - 1)
            else {
                return nil
            }
            
            guard
                let documentLength = self.storage.getInteger(at: offset &+ 8 &+ numericCast(codeLength), endianness: .little, as: Int32.self),
                let slice = self.storage.getSlice(at: offset, length: numericCast(documentLength))
            else {
                return nil
            }
            
            let scope = Document(
                buffer: slice,
                isArray: false
            )
            
            return JavaScriptCodeWithScope(code, scope: scope)
        case .int32:
            return self.storage.getInteger(at: offset, endianness: .little, as: Int32.self)
        case .decimal128:
            guard let slice = storage.getBytes(at: offset, length: 16) else {
                return nil
            }
            
            return Decimal128(slice)
        }
    }
}
