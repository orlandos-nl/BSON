import Foundation

extension Document {
    /// Calls `changeCapacity` on `storage` and updates the document header
    private mutating func changeCapacity(_ requiredCapacity: Int) {
        storage.reserveCapacity(requiredCapacity)
        self.usedCapacity = Int32(requiredCapacity)
    }
    
    /// This function is called before writing a primitive body to the document storage
    ///
    /// It:
    ///
    /// - moves data around to make sure the data can be written, if needded
    /// - updates the document header
    /// - writes the type identifier
    /// - writes the key
    ///
    /// After calling `prepareForWritingPrimitive`, the `writerIndex` of the `storage` will be at the position where the primitive body can be written
    private mutating func prepareWritingPrimitive(_ type: TypeIdentifier, bodyLength: Int, existingDimensions: DocumentCache.Dimensions?, key: String) {
        // capacity needed for one element: typeId + key with null terminator + body
        let fullLength = 1 + key.count + 1 + bodyLength
        let requiredCapacity = Int(self.usedCapacity) + fullLength - (existingDimensions?.fullLength ?? 0)
        
        if let existingDimensions = existingDimensions {
            storage.moveWriterIndex(to: existingDimensions.from)
            
            if existingDimensions.fullLength < fullLength {
                // need to make extra space; new value is bigger than old value
                let initialUsedCapacity = usedCapacity
                changeCapacity(requiredCapacity)
                let requiredExtraLength = fullLength - existingDimensions.fullLength
                moveBytes(from: existingDimensions.end, to: existingDimensions.end &+ requiredExtraLength, length: numericCast(initialUsedCapacity) &- existingDimensions.end)
            } else if existingDimensions.fullLength > fullLength {
                // need to make space smaller; new value is smaller than old value
                moveBytes(from: existingDimensions.end, to: existingDimensions.from &+ fullLength, length: numericCast(usedCapacity) &- existingDimensions.end)
                changeCapacity(requiredCapacity)
            }
        } else {
            // Move the writer index to the `null` byte, which will be overwritten with the new data
            storage.moveWriterIndex(to: Int(self.usedCapacity &- 1))
            changeCapacity(requiredCapacity)
        }
        
        let newDimensions = DocumentCache.Dimensions(
            type: type,
            from: storage.writerIndex,
            keyLengthWithNull: key.count + 1,
            valueLength: bodyLength
        )
        
        prepareCacheForMutation()
        if let dimensions = existingDimensions {
            cache.replace(dimensions, with: newDimensions, newKey: key)
        } else {
            cache.add((key, newDimensions))
        }
        
        // Write the type identifier
        storage.write(integer: type.rawValue, endianness: .little)
        
        // Write the key
        storage.write(string: key)
        storage.write(integer: 0, endianness: .little, as: UInt8.self)
        
        // Writer index is now at the position of the body
    }
    
    /// Moves the writer index to the end of the document and writes the null terminator
    private mutating func finalizeWriting() {
        storage.moveWriterIndex(to: Int(self.usedCapacity &- 1))
        storage.write(integer: 0, endianness: .little, as: UInt8.self)
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
    
    /// Removes `length` number of bytes at `index`, and moves the bytes after over it
    /// Afterwards, it updates the document header
    mutating func removeBytes(at index: Int, length: Int) {
        moveBytes(from: index + length, to: index, length: numericCast(self.usedCapacity) - index - length)
        self.usedCapacity -= Int32(length)
    }
    
    mutating func write(_ primitive: Primitive, forDimensions dimensions: DocumentCache.Dimensions?, key: String) {
        defer { finalizeWriting() }
        
        // When changing this switch, please order in ascending type identifier order for readability
        switch primitive {
        case let double as Double: // 0x01
            prepareWritingPrimitive(.double, bodyLength: 8, existingDimensions: dimensions, key: key)
            storage.write(integer: double.bitPattern, endianness: .little)
        case let string as String: // 0x02
            let stringLengthWithNull = string.utf8.count + 1
            prepareWritingPrimitive(.string, bodyLength: stringLengthWithNull + 4, existingDimensions: dimensions, key: key)
            
            storage.write(integer: Int32(stringLengthWithNull), endianness: .little)
            storage.write(string: string)
            storage.write(integer: 0, endianness: .little, as: UInt8.self)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            prepareWritingPrimitive(document.isArray ? .array : .document, bodyLength: Int(document.usedCapacity), existingDimensions: dimensions, key: key)
            var buffer = document.makeByteBuffer()
            storage.write(buffer: &buffer)
        case let binary as Binary: // 0x05
            prepareWritingPrimitive(.binary, bodyLength: binary.count + 1 + 4, existingDimensions: dimensions, key: key)
            storage.write(integer: Int32(binary.count), endianness: .little)
            storage.write(integer: binary.subType.identifier, endianness: .little)
            var buffer = binary.storage
            storage.write(buffer: &buffer)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            prepareWritingPrimitive(.objectId, bodyLength: 12, existingDimensions: dimensions, key: key)
            storage.write(bytes: objectId.storage)
        case let bool as Bool: // 0x08
            prepareWritingPrimitive(.boolean, bodyLength: 1, existingDimensions: dimensions, key: key)
            
            let bool: UInt8 = bool ? 0x01 : 0x00
            storage.write(integer: bool, endianness: .little)
        case let date as Date: // 0x09
            prepareWritingPrimitive(.datetime, bodyLength: 8, existingDimensions: dimensions, key: key)
            
            let milliseconds = Int(date.timeIntervalSince1970 * 1000)
            storage.write(integer: milliseconds, endianness: .little)
        case is Null: // 0x0A
            prepareWritingPrimitive(.null, bodyLength: 0, existingDimensions: dimensions, key: key)
        case let regex as RegularExpression: // 0x0B
            Swift.assert(!regex.pattern.contains("\0"))
            Swift.assert(!regex.options.contains("\0"))
            
            // string counts + null terminators
            prepareWritingPrimitive(.regex, bodyLength: regex.pattern.count + regex.options.count + 2, existingDimensions: dimensions, key: key)
            
            storage.write(string: regex.pattern)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)
            
            storage.write(string: regex.options)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)
            // 0x0C is deprecated (DBPointer)
            // 0x0E is deprecated (Symbol)
        case let int as Int32: // 0x10
            prepareWritingPrimitive(.int32, bodyLength: 4, existingDimensions: dimensions, key: key)
            storage.write(integer: int, endianness: .little)
        case let stamp as Timestamp:
            prepareWritingPrimitive(.timestamp, bodyLength: 8, existingDimensions: dimensions, key: key)
            storage.write(integer: stamp.increment, endianness: .little)
            storage.write(integer: stamp.timestamp, endianness: .little)
        case let int as Int: // 0x12
            prepareWritingPrimitive(.int64, bodyLength: 8, existingDimensions: dimensions, key: key)
            storage.write(integer: int, endianness: .little)
        case let decimal128 as Decimal128:
            prepareWritingPrimitive(.decimal128, bodyLength: 16, existingDimensions: dimensions, key: key)
            storage.write(bytes: decimal128.storage)
        case is MaxKey: // 0x7F
            prepareWritingPrimitive(.maxKey, bodyLength: 0, existingDimensions: dimensions, key: key)
        case is MinKey: // 0xFF
            prepareWritingPrimitive(.maxKey, bodyLength: 0, existingDimensions: dimensions, key: key)
        case let javascript as JavaScriptCode:
            let codeLengthWithNull = javascript.code.utf8.count + 1
            prepareWritingPrimitive(.javascript, bodyLength: 4 + codeLengthWithNull, existingDimensions: dimensions, key: key)
            
            storage.write(integer: Int32(codeLengthWithNull), endianness: .little)
            storage.write(string: javascript.code)
            storage.write(integer: 0, endianness: .little, as: UInt8.self)
        case let javascript as JavaScriptCodeWithScope:
            var codeBuffer = javascript.scope.makeByteBuffer()
            
            let codeLength = javascript.code.utf8.count + 1 // code, null terminator
            let codeLengthWithHeader = 4 + codeLength
            let primitiveLength = 4 + codeLengthWithHeader + codeBuffer.writerIndex // int32(code_w_s size), code, scope doc
            
            prepareWritingPrimitive(.javascriptWithScope, bodyLength: primitiveLength, existingDimensions: dimensions, key: key)
            
            storage.write(integer: Int32(primitiveLength), endianness: .little) // header
            storage.write(integer: codeLength) // string (code)
            storage.write(string: javascript.code)
            storage.write(buffer: &codeBuffer)
        default:
            guard let data = primitive as? BSONDataType else {
                assertionFailure("Currently unsupported type \(primitive)")
                return
            }
            
            self.write(data.primitive, forDimensions: dimensions, key: key)
        }
    }
    
    /// Writes the `primitive` to this Document keyed by `key`
    ///
    /// - precondition: `key` does not contain a null character
    /// - precondition: the document is fully cached
    mutating func write(_ primitive: Primitive, forKey key: String) {
        Swift.assert(!key.contains("\0")) // TODO: this should not only fail on debug. Maybe just remove ocurrences of \0?
        
        let dimensions = cache.dimensions(forKey: key)
        self.write(primitive, forDimensions: dimensions, key: key)
    }
}
