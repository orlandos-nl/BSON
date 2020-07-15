extension Document {
    internal func typeIdentifier(of key: String) -> TypeIdentifier? {
        var index = 4

        while index < storage.readableBytes {
            guard
                let typeNum = storage.getInteger(at: index, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeNum)
            else {
                return nil
            }

            index += 1

            if matchesKey(key, at: index) {
                return type
            }

            guard
                skipKey(at: &index),
                skipValue(ofType: type, at: &index)
            else {
                return nil
            }
        }

        return nil
    }

    internal func typeIdentifier(at index: Int) -> TypeIdentifier? {
        var offset = 4

        for _ in 0..<index {
            guard skipKeyValuePair(at: &offset) else {
                return nil
            }
        }

        guard let type = storage.getInteger(at: offset, as: UInt8.self) else {
            return nil
        }

        return TypeIdentifier(rawValue: type)
    }

    internal func assertPrimitive<P: Primitive>(typeOf type: P.Type, forKey key: String) throws -> P {
        if let value = self[key] as? P {
            return value
        }

        throw BSONValueNotFound(type: P.self, path: [key])
    }
}

public struct BSONValueNotFound: Error, CustomStringConvertible {
    public let type: Any.Type
    public let path: [String]
    
    public var description: String {
        return "Couldn't find type \(type) at path \"\(path)\""
    }
}

// TODO: Include more context. These errors are thrown in BSONDecoder but provide no information at all about the KeyPath, and are therefore useless.
struct BSONTypeConversionError<A>: Error {
    let from: A
    let to: Any.Type
}
