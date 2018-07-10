import Foundation



extension Document {
    /// Writes the type identifier and key, and makes sure there is enough place to write the buffer
    private func prepareWritingPrimitive(_ type: TypeIdentifier, bodyLength: Int, dimensions: DocumentCache.Dimensions?, key: String) {
        // TODO: Handle existing dimensions
    }
    
    mutating func write(_ primitive: Primitive, forDimensions dimensions: DocumentCache.Dimensions?, key: String) {
        // When changing this switch, please order in ascending type identifier order for readability
        switch primitive {
        case var double as Double: // 0x01
            prepareWritingPrimitive(.double, bodyLength: 8, dimensions: dimensions, key: key)
            storage.write(integer: double.bitPattern, endianness: .little)
        case let string as String: // 0x02
            let stringLengthWithNull = string.count + 1
            prepareWritingPrimitive(.string, bodyLength: stringLengthWithNull + 4, dimensions: dimensions, key: key)
            
            storage.write(integer: Int32(stringLengthWithNull), endianness: .little)
            storage.write(string: string)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            prepareWritingPrimitive(document.isArray ? .array : .document, bodyLength: Int(document.usedCapacity), dimensions: dimensions, key: key)
            var buffer = document.makeByteBuffer()
            storage.write(buffer: &buffer)
        case let binary as Binary: // 0x05
            prepareWritingPrimitive(.binary, bodyLength: binary.count + 1, dimensions: dimensions, key: key)
            storage.write(integer: binary.subType.identifier, endianness: .little)
            var buffer = binary.storage
            storage.write(buffer: &buffer)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            unimplemented()
//            type = .objectId
//            flush(from: objectId.storage.readBuffer.baseAddress!, length: 12)
        case let bool as Bool: // 0x08
            unimplemented()
//            type = .boolean
//            var bool: UInt8 = bool ? 0x01 : 0x00
//
//            flush(from: &bool, length: 1)
        case let date as Date: // 0x09
            unimplemented()
//            type = .datetime
//            var milliseconds = Int(date.timeIntervalSince1970 * 1000)
//            withPointer(pointer: &milliseconds, length: 8, run: flush)
        case is Null: // 0x0A
            unimplemented()
//            type = .null
//            flush(from: nil, length: 0)
            // TODO: RegularExpression (0x0B)
            // 0x0C is deprecated (DBPointer)
            // TODO: JavascriptCode (0x0D)
            // 0x0E is deprecated (Symbol)
        // TODO: JavascriptCode With Scope (0x0F)
        case var int as Int32: // 0x10
            unimplemented()
//            type = .int32
//            withPointer(pointer: &int, length: 4, run: flush)
        case var stamp as Timestamp:
            unimplemented()
//            type = .timestamp
//            withPointer(pointer: &stamp, length: 8, run: flush)
        case let int as Int: // 0x12
            unimplemented()
//            var int = (numericCast(int) as Int64)
//            type = .int64
//
//            withPointer(pointer: &int, length: 8, run: flush)
        case var int as Int64: // 0x12
            unimplemented()
//            type = .int64
//            withPointer(pointer: &int, length: 8, run: flush)
        case let decimal128 as Decimal128:
            unimplemented()
//            type = .decimal128
//            flush(from: decimal128.storage.readBuffer.baseAddress!, length: 16)
        case is MaxKey: // 0x7F
            unimplemented()
//            type = .maxKey
//            flush(from: nil, length: 0)
        case is MinKey: // 0xFF
            unimplemented()
//            type = .minKey
//            flush(from: nil, length: 0)
        default:
            assertionFailure("Currently unsupported type \(primitive)")
        }
    }
    
    mutating func writeOld(_ primitive: Primitive, forDimensions dimensions: DocumentCache.Dimensions?, key: String) {
        var type: TypeIdentifier!
        var writeLengthPrefix = false // true if the primitive type to write needs a length prefix
        
        /// Flushes the value at the pointer with the given length to the document
        ///
        /// - Writes the identifier, key and value
        /// - Updates the DocumentCache
        func flush(from pointer: UnsafePointer<UInt8>?, length: Int) {
            if var dimensions = dimensions {
                self.storage.writeBuffer![dimensions.from] = type.rawValue
                
                var offset = dimensions.from &+ 1 &+ dimensions.keyCString
                var replaceLength = dimensions.valueLength
                
                dimensions.type = type
                dimensions.valueLength = length
                
                if writeLengthPrefix {
                    var writtenLength = Int32(length)
                    
                    withPointer(pointer: &writtenLength, length: 4) { pointer, length in
                        self.storage.replace(offset: offset, replacing: 4, with: pointer, length: length)
                    }
                    
                    // Update for length prefix
                    offset = offset &+ 4
                    
                    // The value's length needs to be 4 longer since it's prefixed
                    dimensions.valueLength = dimensions.valueLength &+ 4
                    
                    // We already advanced 4 bytes, so the amount of replacable bytes is reduced
                    replaceLength = replaceLength &- 4
                }
                
                if let pointer = pointer {
                    self.storage.replace(
                        offset: offset,
                        replacing: replaceLength,
                        with: pointer,
                        length: length
                    )
                }
                
                for index in 0..<self.cache.storage.count {
                    if self.cache.storage[index].1.from == dimensions.from {
                        // Found the old dimensions
                        self.cache.storage[index].1 = dimensions
                        return
                    }
                }
                
                assertionFailure("Internal Document error: updated with incorrect dimensions")
            } else {
                let start = self.storage.usedCapacity
                let keyData = [UInt8](key.utf8) + [0]
                
                self.storage.append(type.rawValue)
                self.storage.append(keyData)
                let totalLength: Int
                
                if writeLengthPrefix {
                    var dataLength = Int32(length)
                    totalLength = length &+ 4
                    
                    withPointer(pointer: &dataLength, length: 4) { pointer, length in
                        self.storage.append(from: pointer, length: length)
                    }
                } else {
                    totalLength = length
                }
                
                if let pointer = pointer {
                    self.storage.append(from: pointer, length: length)
                }
                
                let dimensions = DocumentCache.Dimensions(
                    type: type,
                    from: start,
                    keyCString: keyData.count,
                    valueLength: totalLength
                )
                
                self.cache.storage.append((key, dimensions))
            }
        }
        
        // Try to find the appropriate behaviour for a given type
        // When changing this switch, please order in ascending type identifier order for readability
        switch primitive {
        case var double as Double: // 0x01
            type = .double
            
            withPointer(pointer: &double, length: 8, run: flush)
        case let string as String: // 0x02
            type = .string
            writeLengthPrefix = true
            let string = [UInt8](string.utf8) + [0x00]
            flush(from: string, length: string.count)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            type = document.isArray ? .array : .document
            let data = document.makeData()
            data.withUnsafeBytes { buffer in
                flush(from: buffer, length: data.count)
            }
        case let binary as Binary: // 0x05
            type = .binary
            writeLengthPrefix = true
            flush(from: binary.storage.readBuffer.baseAddress!, length: binary.storage.readBuffer.count)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            type = .objectId
            flush(from: objectId.storage.readBuffer.baseAddress!, length: 12)
        case let bool as Bool: // 0x08
            type = .boolean
            var bool: UInt8 = bool ? 0x01 : 0x00
            
            flush(from: &bool, length: 1)
        case let date as Date: // 0x09
            type = .datetime
            var milliseconds = Int(date.timeIntervalSince1970 * 1000)
            withPointer(pointer: &milliseconds, length: 8, run: flush)
        case is Null: // 0x0A
            type = .null
            flush(from: nil, length: 0)
            // TODO: RegularExpression (0x0B)
            // 0x0C is deprecated (DBPointer)
            // TODO: JavascriptCode (0x0D)
            // 0x0E is deprecated (Symbol)
        // TODO: JavascriptCode With Scope (0x0F)
        case var int as Int32: // 0x10
            type = .int32
            withPointer(pointer: &int, length: 4, run: flush)
        case var stamp as Timestamp:
            type = .timestamp
            withPointer(pointer: &stamp, length: 8, run: flush)
        case let int as Int: // 0x12
            var int = (numericCast(int) as Int64)
            type = .int64
            
            withPointer(pointer: &int, length: 8, run: flush)
        case var int as Int64: // 0x12
            type = .int64
            withPointer(pointer: &int, length: 8, run: flush)
        case let decimal128 as Decimal128:
            type = .decimal128
            flush(from: decimal128.storage.readBuffer.baseAddress!, length: 16)
        case is MaxKey: // 0x7F
            type = .maxKey
            flush(from: nil, length: 0)
        case is MinKey: // 0xFF
            type = .minKey
            flush(from: nil, length: 0)
        default:
            assertionFailure("Currently unsupported type \(primitive)")
        }
    }
    
    /// Writes the `primitive` to this Document keyed by `key`
    ///
    /// - precondition: `key` does not contain a null character
    mutating func write(_ primitive: Primitive, forKey key: String) {
        assert(!key.contains("\0")) // TODO: this should not only fail on debug. Maybe just remove ocurrences of \0?
        
        let dimensions = self.dimension(forKey: key)
        self.write(primitive, forDimensions: dimensions, key: key)
    }
}
