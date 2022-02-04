public protocol PrimitiveEncodable {
    func encodePrimitive() throws -> Primitive
}

// - MARK: Sequences

extension Array: PrimitiveEncodable where Element: Encodable {
    public func encodePrimitive() throws -> Primitive {
        return try BSONEncoder().encode(self)
    }
}

extension Set: PrimitiveEncodable where Element: Encodable {
    public func encodePrimitive() throws -> Primitive {
        return try BSONEncoder().encode(self)
    }
}

extension Dictionary: PrimitiveEncodable where Key == String, Value: Encodable {
    public func encodePrimitive() throws -> Primitive {
        return try BSONEncoder().encode(self)
    }
}

// - MARK: Optional

fileprivate enum BSONInternalUnknownTypeForPrimitiveConvertibleConversion: Primitive {
    case invalid // if we don't include a case, Swift generates a warning "Will never be executed"
    
    init(from decoder: Decoder) throws {
        self = .invalid
    }
    
    func encode(to encoder: Encoder) throws {
        preconditionFailure()
    }
}

extension Optional: PrimitiveEncodable where Wrapped: PrimitiveEncodable {
    public func encodePrimitive() throws -> Primitive {
        switch self {
        case .none:
            return Null()
        case .some(let wrapped):
            return try wrapped.encodePrimitive()
        }
    }
}
