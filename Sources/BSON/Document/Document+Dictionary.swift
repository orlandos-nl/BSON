extension Document: ExpressibleByDictionaryLiteral {
    /// Gets all top level keys in this Document
    public var keys: [String] {
        _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .all)
        let pointer = self.storage.readBuffer.baseAddress!
        
        return self.cache.storage.map { (_, dimension) in
            // + 1 for the type identifier
            let pointer = pointer.advanced(by: dimension.from &+ 1)
            return String(cString: pointer)
        }
    }
    
    /// Tries to extract a value of type `P` from the value at key `key`
    internal subscript<P: Primitive>(key: String, as type: P.Type) -> P? {
        return self[key] as? P
    }
    
    /// Extracts any `Primitive` fom the value at key `key`
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
                
                for i in 0..<self.cache.storage.count {
                    if self.cache.storage[i].0 == key {
                        self.cache.storage.remove(at: i)
                        return
                    }
                }
            }
        }
    }
    
    /// Creates a new Document from a Dictionary literal
    public init(dictionaryLiteral elements: (String, PrimitiveConvertible)...) {
        self.init(elements: elements.lazy.map { ($0, $1.makePrimitive()) })
    }
    
    /// Creates a new Document with the given elements
    public init<S : Sequence>(elements: S) where S.Element == (String, Primitive) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}

extension Dictionary where Key == String, Value == Primitive {
    public init(document: Document) {
        self.init()
        
        for pair in document {
            self[pair.key] = pair.value
        }
    }
}
