import NIO

extension Document: ExpressibleByDictionaryLiteral {
    /// Gets all top level keys in this Document
    public var keys: [String] {
        // NOTE: BSON internally depends on the side effect accessing the keys has, of making the document fully cached
        ensureFullyCached()
        return cache.cachedKeys
    }
    
    /// Tries to extract a value of type `P` from the value at key `key`
    internal subscript<P: Primitive>(key: String, as type: P.Type) -> P? {
        return self[key] as? P
    }
    
    /// Creates a new Document from a Dictionary literal
    public init(dictionaryLiteral elements: (String, PrimitiveConvertible)...) {
        self.init(elements: elements.lazy.compactMap { key, value in
            guard let primitive = value.makePrimitive() else {
                return nil // continue
            }
            
            return (key, primitive)
        })
    }
    
    /// Creates a new Document with the given elements
    // TODO: @_specialize ?
    public init<S: Sequence>(elements: S, isArray: Bool = false) where S.Element == (String, PrimitiveConvertible) {
        self.init(isArray: isArray)
        for (key, value) in elements {
            guard let value = value.makePrimitive() else {
                continue
            }
            
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
