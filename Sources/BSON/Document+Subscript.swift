extension Document {
    mutating func prepareForMutation() {
        if self.nullTerminated {
            self.storage.remove(from: self.storage.usedCapacity &- 1, length: 1)
            self.nullTerminated = false
        }
    }
    
    mutating func write(_ primitive: Primitive, forKey key: String) {
        prepareForMutation()
        
        let dimensions = self.dimension(forKey: key)
        var type: UInt8!
        
        func withPointer<I>(
            pointer: UnsafePointer<I>,
            length: Int,
            run: (UnsafePointer<UInt8>, Int) -> ()
        ) {
            return pointer.withMemoryRebound(to: UInt8.self, capacity: 1) { pointer in
                return run(pointer, length)
            }
        }
        
        func flush(from pointer: UnsafePointer<UInt8>, length: Int) {
            if let dimensions = dimensions {
                self.storage.replace(
                    offset: dimensions.from &+ 1 &+ dimensions.keyCString,
                    replacing: dimensions.valueLength,
                    with: pointer,
                    length: length
                )
            } else {
                let start = self.storage.usedCapacity
                let keyData = [UInt8](key.utf8)
                
                self.storage.append(type)
                self.storage.append(keyData)
                self.storage.append(0)
                self.storage.append(from: pointer, length: length)
                
                let dimensions = DocumentCache.Dimensions(
                    type: type,
                    from: start,
                    keyCString: keyData.count,
                    valueLength: length
                )
                
                self.cache.storage.append((key, dimensions))
            }
        }
        
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
        default:
            fatalError()
        }
    }
}
