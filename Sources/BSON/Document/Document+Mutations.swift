import Foundation

extension Document {
    /// Calls `changeCapacity` on `storage` and updates the document header
    private mutating func changeCapacity(_ requiredCapacity: Int) {
        storage.reserveCapacity(requiredCapacity)
        self.usedCapacity = Int32(requiredCapacity)
    }
    
    /// Moves the bytes with the given length at the position `from` to the position at `to`
    mutating func moveBytes(from: Int, to: Int, length: Int) {
        let initialReaderIndex = storage.readerIndex
        let initialWriterIndex = storage.writerIndex
        
        storage.moveReaderIndex(to: 0)
        storage.moveWriterIndex(to: Int(self.usedCapacity))
        
        defer {
            storage.moveReaderIndex(to: initialReaderIndex)
            storage.moveWriterIndex(to: initialWriterIndex)
        }
        
        _ = storage.withUnsafeMutableReadableBytes { pointer in
            memmove(
                pointer.baseAddress! + to, // dst
                pointer.baseAddress! + from, // src
                length // len
            )
        }
    }

    func skipKey(at index: inout Int) -> Bool {
        if let length = storage.firstRelativeIndexOf(startingAt: index) {
            index += length + 1 // including null terminator
            return true
        }

        return false
    }

    func skipMatchingKey(_ key: String, at index: inout Int) -> Bool {
        let base = index

        if !skipKey(at: &index) {
            return false
        }

        let length = index - base

        #if compiler(>=5)
        let valid = key.utf8.withContiguousStorageIfAvailable { key -> Bool in
            if key.count != length {
                return false
            }

            return storage.withUnsafeReadableBytes { storage in
                return memcmp(key.baseAddress!, storage.baseAddress! + index, length) == 0
            }
        }
        
        if let valid = valid {
            return valid
        }
        #endif
        
        if key.utf8.count != length {
            return false
        } else {
            return key == storage.getString(at: base, length: length)
        }
    }

    func skipValue(ofType type: TypeIdentifier, at index: inout Int) -> Bool {
        if let length = valueLength(forType: type, at: index) {
            index += length
            return true
        }

        return false
    }

    func skipKeyValuePair(at index: inout Int) -> Bool {
        guard
            let typeId = storage.getInteger(at: index, as: UInt8.self),
            let type = TypeIdentifier(rawValue: typeId)
        else { return false }

        index += 1

        guard skipKey(at: &index) else { return false }
        return skipValue(ofType: type, at: &index)
    }
    
    func getKey(at index: Int) -> String? {
        guard let length = storage.firstRelativeIndexOf(startingAt: index) else {
            return nil
        }
        
        return storage.getString(at: index, length: length)
    }

    func matchesKey(_ key: String, at index: Int) -> Bool {
        guard let length = storage.firstRelativeIndexOf(startingAt: index) else {
            return false
        }
        
        #if compiler(>=5)
        let valid = key.utf8.withContiguousStorageIfAvailable { key -> Bool in
            if key.count != length {
                return false
            }

            return storage.withUnsafeReadableBytes { storage in
                return memcmp(key.baseAddress!, storage.baseAddress! + index, length) == 0
            }
        }
        
        if let valid = valid {
            return valid
        }
        #endif
        
        if key.utf8.count != length {
            return false
        } else {
            return key == storage.getString(at: index, length: length)
        }
    }

    func value(forType type: TypeIdentifier, at offset: Int) -> Primitive? {
        switch type {
        case .double:
            return storage.getDouble(at: offset)
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
            guard let patternEnd = storage.firstRelativeIndexOf(startingAt: offset), let pattern = storage.getString(at: offset, length: patternEnd - 1) else {
                return nil
            }

            let offset = offset + patternEnd

            guard let optionsEnd = storage.firstRelativeIndexOf(startingAt: offset), let options = storage.getString(at: offset, length: optionsEnd - 1) else {
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
    
    /// Removes `length` number of bytes at `index`, and moves the bytes after over it
    /// Afterwards, it updates the document header
    mutating func removeBytes(at index: Int, length: Int) {
        moveBytes(from: index + length, to: index, length: numericCast(self.usedCapacity) - index - length)
        storage.moveWriterIndex(to: storage.readableBytes - length)
        self.usedCapacity -= Int32(length)
    }
}
