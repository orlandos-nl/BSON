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
        if let length = storage.firstRelativeIndexOf(byte: 0x00, startingAt: index) {
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

        #if swift(>=5.0)
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

        return key == storage.getString(at: base, length: length)
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

    func matchesKey(_ key: String, at index: Int) -> Bool {
        guard let length = storage.firstRelativeIndexOf(byte: 0x00, startingAt: index) else {
            return false
        }

        #if swift(>=5.0)
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

        return key == storage.getString(at: index, length: length)
    }

    func key(at index: Int) -> String? {
        guard let length = storage.getInteger(at: index, endianness: .little, as: Int32.self), length > 0 else {
            return nil
        }

        return storage.getString(at: index + 4, length: Int(length - 1))
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
            guard let patternEnd = storage.firstRelativeIndexOf(byte: 0x00, startingAt: offset), let pattern = storage.getString(at: offset, length: patternEnd - 1) else {
                return nil
            }

            let offset = offset + patternEnd

            guard let optionsEnd = storage.firstRelativeIndexOf(byte: 0x00, startingAt: offset), let options = storage.getString(at: offset, length: optionsEnd - 1) else {
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

    mutating func overwriteValue(with value: Primitive, atPairOffset pairOffset: Int) {
        var offset = pairOffset
        let typeOffset = pairOffset

        guard
            let oldTypeId: UInt8 = storage.getInteger(at: typeOffset),
            let oldType = TypeIdentifier(rawValue: oldTypeId)
        else {
            return
        }

        offset += 1 // skip type

        guard skipKey(at: &offset) else {
            return
        }

        guard let length = valueLength(forType: oldType, at: offset) else {
            return
        }

        func beforeWriting(_ type: TypeIdentifier, newLength: Int) {
            storage.set(integer: type.rawValue, at: typeOffset)
            let diff = length - newLength

            if diff < 0 {
                let maintainedDataOffset = offset + length
                guard let bytes = storage.getBytes(at: maintainedDataOffset, length: storage.readableBytes - maintainedDataOffset) else {
                    return
                }

                storage.moveWriterIndex(to: offset + newLength)
                storage.write(bytes: bytes)
            } else if diff == 0 {
                return
            } else if diff > 0 {
                // More removed than added
                removeBytes(at: offset + newLength, length: diff)
            }
        }

        switch value {
        case let double as Double: // 0x01
            beforeWriting(.double, newLength: 8)
            storage.set(integer: double.bitPattern, at: offset, endianness: .little)
        case let string as String: // 0x02
            let stringLength = string.utf8.count
            beforeWriting(.string, newLength: 4 + stringLength + 1)
            storage.set(integer: Int32(stringLength + 1), at: offset, endianness: .little)
            storage.set(string: string, at: offset + 4)
            storage.set(integer: 0, at: offset + 4 + stringLength, endianness: .little, as: UInt8.self)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            beforeWriting(document.isArray ? .array : .document, newLength: document.storage.readableBytes)
            storage.write(buffer: &document.storage)
        case let binary as Binary: // 0x05
            beforeWriting(.binary, newLength: 5 + binary.count)
            storage.set(integer: Int32(binary.count), at: offset, endianness: .little)
            storage.set(integer: binary.subType.identifier, at: offset + 4, endianness: .little)
            storage.set(buffer: binary.storage, at: offset + 5)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            beforeWriting(.objectId, newLength: 12)
            storage.set(integer: objectId.byte0, at: offset)
            storage.set(integer: objectId.byte1, at: offset &+ 1)
            storage.set(integer: objectId.byte2, at: offset &+ 2)
            storage.set(integer: objectId.byte3, at: offset &+ 3)
            storage.set(integer: objectId.byte4, at: offset &+ 4)
            storage.set(integer: objectId.byte5, at: offset &+ 5)
            storage.set(integer: objectId.byte6, at: offset &+ 6)
            storage.set(integer: objectId.byte7, at: offset &+ 7)
            storage.set(integer: objectId.byte8, at: offset &+ 8)
            storage.set(integer: objectId.byte9, at: offset &+ 9)
            storage.set(integer: objectId.byte10, at: offset &+ 10)
            storage.set(integer: objectId.byte11, at: offset &+ 11)
        case let bool as Bool: // 0x08
            beforeWriting(.boolean, newLength: 1)
            let bool: UInt8 = bool ? 0x01 : 0x00
            storage.set(integer: bool, at: offset, endianness: .little)
        case let date as Date: // 0x09
            beforeWriting(.datetime, newLength: 8)
            let milliseconds = Int(date.timeIntervalSince1970 * 1000)
            storage.set(integer: milliseconds, at: offset, endianness: .little)
        case is Null: // 0x0A
            beforeWriting(.null, newLength: 0)
        case let regex as RegularExpression: // 0x0B
            Swift.assert(!regex.pattern.contains("\0"))
            Swift.assert(!regex.options.contains("\0"))

            beforeWriting(.regex, newLength: regex.pattern.utf8.count + regex.options.utf8.count + 2)
            // string counts + null terminators
            storage.write(string: regex.pattern)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)

            storage.write(string: regex.options)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)
            // 0x0C is deprecated (DBPointer)
        // 0x0E is deprecated (Symbol)
        case let int as Int32: // 0x10
            beforeWriting(.int32, newLength: 4)
            storage.write(integer: int, endianness: .little)
        case let stamp as Timestamp:
            beforeWriting(.timestamp, newLength: 8)
            storage.write(integer: stamp.increment, endianness: .little)
            storage.write(integer: stamp.timestamp, endianness: .little)
        case let int as Int: // 0x12
            beforeWriting(.int64, newLength: 8)
            storage.write(integer: int, endianness: .little)
        case let decimal128 as Decimal128:
            beforeWriting(.decimal128, newLength: decimal128.storage.count)
            storage.write(bytes: decimal128.storage)
        case is MaxKey: // 0x7F
            beforeWriting(.maxKey, newLength: 0)
        case is MinKey: // 0xFF
            beforeWriting(.minKey, newLength: 0)
        case let javascript as JavaScriptCode:
            let codeLengthWithNull = javascript.code.utf8.count + 1
            beforeWriting(.javascript, newLength: 4 + codeLengthWithNull)
            storage.write(integer: Int32(codeLengthWithNull), endianness: .little)
            storage.write(string: javascript.code)
            storage.write(integer: 0, endianness: .little, as: UInt8.self)
        case let javascript as JavaScriptCodeWithScope:
            var codeBuffer = javascript.scope.makeByteBuffer()
            let codeLength = javascript.code.utf8.count + 1 // code, null terminator
            let codeLengthWithHeader = 4 + codeLength
            let primitiveLength = 4 + codeLengthWithHeader + codeBuffer.writerIndex // int32(code_w_s size), code, scope doc
            beforeWriting(.javascriptWithScope, newLength: primitiveLength)

            storage.write(integer: Int32(primitiveLength), endianness: .little) // header
            storage.write(integer: codeLength) // string (code)
            storage.write(string: javascript.code)
            storage.write(buffer: &codeBuffer)
        case let bsonData as BSONDataType:
            self.overwriteValue(with: bsonData.primitive, atPairOffset: pairOffset)
            return
        default:
            //            guard let data = primitive as? BSONDataType else {
            assertionFailure("Currently unsupported type \(primitive)")
            return
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
