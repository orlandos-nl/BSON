extension Document {
    public subscript<P: Primitive>(key: String, as type: P.Type) -> P? {
        return self[key] as? P
    }
    
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            if let newValue = newValue {
                self.write(newValue, forKey: key)
            } else {
                guard let dimensions = self.dimension(forKey: key) else { return }
                
                self.storage.remove(from: dimensions.from, length: dimensions.fullLength)
            }
        }
    }
    
    mutating func write(_ primitive: Primitive, forKey key: String) {
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
                let characters = key.utf8.count
                
                self.storage.append(type)
                
                key.withCString { pointer in
                    self.storage.append(from: pointer, length: characters)
                }
                
                self.storage.append(0)
                
                let dimensions = DocumentCache.Dimensions(
                    type: type,
                    from: start,
                    keyCString: characters,
                    valueLength: length
                )
                
                self.cache.storage.append((key, dimensions))
                self.storage.insert(at: start, from: pointer, length: length)
            }
        }
        
        switch primitive {
        case let int as Int:
            var int = numericCast(int) as Int64
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
        default:
            fatalError()
        }
    }
}
