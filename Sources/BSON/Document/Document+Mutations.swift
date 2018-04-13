import Foundation

extension Document {
    /// Prepates the document before mutations such as addition or removal of keys
    ///
    /// - Removes the null terminator if it's present
    mutating func prepareForMutation() {
        if self.nullTerminated {
            self.storage.remove(from: self.storage.usedCapacity &- 1, length: 1)
            self.nullTerminated = false
        }
    }
    
    /// Writes the `primitive` to this Document keyed by `key`
    mutating func write(_ primitive: Primitive, forKey key: String) {
        assert(!key.contains("\0"))
        
        prepareForMutation()
        
        let dimensions = self.dimension(forKey: key)
        var type: TypeIdentifier!
        var writeLength = false
        
        /// Accesses the pointer as `UInt8`
        func withPointer<I>(
            pointer: UnsafePointer<I>,
            length: Int,
            run: (UnsafePointer<UInt8>, Int) -> ()
        ) {
            return pointer.withMemoryRebound(to: UInt8.self, capacity: 1) { pointer in
                return run(pointer, length)
            }
        }
        
        /// Flushes the value at the pointer with the given length to the document
        ///
        /// - Writes the identifier, key and value
        /// - Updates the DocumentCache
        func flush(from pointer: UnsafePointer<UInt8>?, length: Int) {
            if let dimensions = dimensions {
                var offset = dimensions.from &+ 1 &+ dimensions.keyCString
                var valueLength = dimensions.valueLength
                
                if writeLength {
                    var writtenLength = Int32(length)
                    
                    withPointer(pointer: &writtenLength, length: 4) { pointer, length in
                        self.storage.replace(offset: offset, replacing: 4, with: pointer, length: length)
                    }
                    
                    offset = offset &+ 4
                    valueLength = valueLength &- 4
                }
                
                if let pointer = pointer {
                    self.storage.replace(
                        offset: offset,
                        replacing: valueLength,
                        with: pointer,
                        length: length
                    )
                }
            } else {
                let start = self.storage.usedCapacity
                let keyData = [UInt8](key.utf8) + [0]
                
                self.storage.append(type.rawValue)
                self.storage.append(keyData)
                let totalLength: Int
                
                if writeLength {
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
        switch primitive {
        case let int as Int:
            var int = (numericCast(int) as Int64)
            type = .int64
            
            withPointer(pointer: &int, length: 8, run: flush)
        case var int as Int64:
            type = .int64
            withPointer(pointer: &int, length: 8, run: flush)
        case var int as Int32:
            type = .int32
            withPointer(pointer: &int, length: 4, run: flush)
        case var double as Double:
            type = .double
            withPointer(pointer: &double, length: 8, run: flush)
        case let bool as Bool:
            type = .boolean
            var bool: UInt8 = bool ? 0x01 : 0x00
            
            flush(from: &bool, length: 1)
        case let objectId as ObjectId:
            type = .objectId
            flush(from: objectId.storage.readBuffer.baseAddress!, length: 12)
        case let string as String:
            type = .string
            writeLength = true
            let string = [UInt8](string.utf8) + [0x00]
            flush(from: string, length: string.count)
        case let binary as Binary:
            type = .binary
            writeLength = true
            flush(from: binary.storage.readBuffer.baseAddress!, length: binary.storage.readBuffer.count)
        case is NSNull:
            type = .null
            flush(from: nil, length: 0)
        case let decimal128 as Decimal128:
            type = .decimal128
            flush(from: decimal128.storage.readBuffer.baseAddress!, length: 16)
        case var document as Document:
            type = document.isArray ? .array : .document
            document.withUnsafeBufferPointer { buffer in
                flush(from: buffer.baseAddress!, length: buffer.count)
            }
        case let date as Date:
            type = .datetime
            var milliseconds = Int(date.timeIntervalSince1970 * 1000)
            withPointer(pointer: &milliseconds, length: 8, run: flush)
        default:
            fatalError("Currently unsupported type \(primitive)")
        }
    }
}
