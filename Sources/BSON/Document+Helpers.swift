extension Document {
    internal func typeIdentifier(of key: String) -> TypeIdentifier? {
        return self.dimension(forKey: key)?.type
    }
    
    internal func assertPrimitive<P: Primitive>(typeOf type: P.Type, forKey key: String) throws -> P {
        if let value =  self.getCached(byKey: key) as? P {
            return value
        }
        
        throw BSONValueNotFound(type: P.self, path: [key])
    }
    
    /// Ensures the minimum writable capacity of this BSON Document is `n` bytes
    ///
    /// Useful when you know in advance a Document will contain a large(r) amount of values
    /// Prevents unnecessary reallocations
    public mutating func ensureBinaryCapacity(_ n: Int) {
        self.storage.ensureCapacity(n)
    }
}

struct BSONValueNotFound: Error {
    let type: Any.Type
    let path: [String]
}

struct BSONTypeConversionError<A>: Error {
    let from: A
    let to: Any.Type
}
