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
    
    /// Creates a new Document from a Dictionary literal
    public init(dictionaryLiteral elements: (String, PrimitiveConvertible)...) {
        self.init(elements: elements.lazy.map { ($0, $1.makePrimitive()) })
    }
    
    /// Creates a new Document with the given elements
    public init<S : Sequence>(elements: S, isArray: Bool = false) where S.Element == (String, Primitive) {
        self.init(isArray: isArray)
        for (key, value) in elements {
            self.write(value, forKey: key)
        }
    }
}

extension Dictionary where Key == String, Value == Primitive {
    public init(document: Document) {
        self.init()
        
        for (key, value) in document {
            self[key] = value
        }
    }
}
