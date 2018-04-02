extension Document {
    public func typeIdentifier(of key: String) -> UInt8? {
        return self.dimension(forKey: key)?.type
    }
    
    internal func assertPrimitive<P: Primitive>(_ type: P.Type, forKey key: String) throws -> P {
        if let value =  self.getCached(byKey: key) as? P {
            return value
        }
        
        throw BSONValueNotFound(type: P.self, key: key)
    }
}

struct BSONValueNotFound: Error {
    let type: Primitive.Type
    let key: String
}
