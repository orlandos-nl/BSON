extension Document {
    internal func typeIdentifier(of key: String) -> TypeIdentifier? {
        _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .all)
        
        return self.dimension(forKey: key)?.type
    }
    
    internal func assertPrimitive<P: Primitive>(typeOf type: P.Type, forKey key: String) throws -> P {
        if let value =  self.getCached(byKey: key) as? P {
            return value
        }
        
        throw BSONValueNotFound(type: P.self, path: [key])
    }
}

struct BSONValueNotFound: Error, CustomStringConvertible {
    let type: Any.Type
    let path: [String]
    
    var description: String {
        return "Couldn't find type \(type) at path \"\(path)\""
    }
}

// TODO: Include more context. These errors are thrown in BSONDecoder but provide no information at all about the KeyPath, and are therefore useless.
struct BSONTypeConversionError<A>: Error {
    let from: A
    let to: Any.Type
}
