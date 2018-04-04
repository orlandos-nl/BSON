extension Document {
    public func typeIdentifier(of key: String) -> UInt8? {
        return self.dimension(forKey: key)?.type
    }
    
    internal func assertPrimitive<P: Primitive>(typeOf type: P.Type, forKey key: String) throws -> P {
        if let value =  self.getCached(byKey: key) as? P {
            return value
        }
        
        throw BSONValueNotFound(type: P.self, path: [key])
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
