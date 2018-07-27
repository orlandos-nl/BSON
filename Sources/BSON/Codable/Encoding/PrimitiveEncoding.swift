struct WrappedPrimitiveForEncoding: Encodable {
    var primitive: Primitive
    
    func encode(to encoder: Encoder) throws {
        try primitive.encode(to: encoder)
    }
}

extension KeyedEncodingContainer {
    public mutating func encodeBSONPrimitive(_ value: Primitive?, forKey key: Key) throws {
        guard let value = value else {
            return
        }
        
        let wrapped = WrappedPrimitiveForEncoding(primitive: value)
        try self.encode(wrapped, forKey: key)
    }
}

extension UnkeyedEncodingContainer {
    public mutating func encodeBSONPrimitive(_ value: Primitive?) throws {
        guard let value = value else {
            return
        }
        
        let wrapped = WrappedPrimitiveForEncoding(primitive: value)
        try self.encode(wrapped)
    }
}

extension SingleValueEncodingContainer {
    public mutating func encodeBSONPrimitive(_ value: Primitive?) throws {
        guard let value = value else {
            return
        }
        
        let wrapped = WrappedPrimitiveForEncoding(primitive: value)
        try self.encode(wrapped)
    }
}
