public final class BSONEncoder {
    public init() {}
    
    public func encode<E: Encodable>(_ e: E) throws -> Document {
        try e.encode(to: _BSONEncoder())
    }
    
    public func encodePrimitive<E: Encodable>(_ e: E) throws -> Document {
        try e.encode(to: _BSONEncoder())
    }
}

final class PrimitiveWrapper {
    var primitive: Primitive
    var doc: Document {
        get {
            if let primitive = primitive as? Document {
                return primitive
            }
            
            self.primitive = Document()
            return self.primitive as! Document
        }
        set {
            self.primitive = newValue
        }
    }
    
    init() {
        self.primitive = Document()
    }
    
    func encode<BI: BinaryInteger & SignedInteger>(_ value: BI) throws {
        if value.bitWidth > 32 {
            self.primitive = Int(value)
        } else {
            self.primitive = Int32(value)
        }
    }
    
    func encode<BI: BinaryInteger & UnsignedInteger>(_ value: BI) throws {
        if value.bitWidth >= 32 {
            self.primitive = Int(value)
        } else {
            self.primitive = Int32(value)
        }
    }
}

struct _BSONEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var wrapper = PrimitiveWrapper()
    
    init() {}
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        <#code#>
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return BSONUnkeyedEncodingContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return BSONSingleValueContainer(wrapper: wrapper)
    }
}

fileprivate struct BSONUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var count: Int {
        return wrapper.doc.count
    }
    
    var wrapper: PrimitiveWrapper {
        return encoder.wrapper
    }
    
    let encoder: _BSONEncoder
    
    var codingPath: [CodingKey] = []
    
    init(encoder: _BSONEncoder) {
        self.encoder = encoder
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        <#code#>
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        var encoder = _BSONEncoder()
        encoder.wrapper = self.wrapper
        
        return BSONUnkeyedEncodingContainer(encoder: encoder)
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    mutating func encodeNil() throws {
        wrapper.doc.append(Null())
    }
    
    mutating func encode(_ value: Bool) throws {
        wrapper.doc.append(value)
    }
    
    mutating func encode(_ value: Int) throws {
        wrapper.doc.append(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        wrapper.doc.append(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        wrapper.append(value)
    }
    
    mutating func encode(_ value: Float) throws {
        wrapper.doc.append(Double(value))
    }
    
    mutating func encode(_ value: Double) throws {
        wrapper.doc.append(value)
    }
    
    mutating func encode(_ value: String) throws {
        wrapper.doc.append(value)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try value.encode(to: encoder)
    }
}

fileprivate struct BSONSingleValueContainer: SingleValueEncodingContainer {
    let wrapper: PrimitiveWrapper
    
    var codingPath: [CodingKey] = []
    
    init(wrapper: PrimitiveWrapper) {
        self.wrapper = wrapper
    }
    
    mutating func encodeNil() throws {
        wrapper.primitive = Null()
    }
    
    mutating func encode(_ value: Bool) throws {
        wrapper.primitive = value
    }
    
    mutating func encode(_ value: Int) throws {
        wrapper.primitive = value
    }
    
    mutating func encode(_ value: Int8) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        wrapper.primitive = value
    }
    
    mutating func encode(_ value: Int64) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        try wrapper.encode(value)
    }
    
    mutating func encode(_ value: Float) throws {
        wrapper.primitive = Double(value)
    }
    
    mutating func encode(_ value: Double) throws {
        wrapper.primitive = value
    }
    
    mutating func encode(_ value: String) throws {
        wrapper.primitive = value
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        var encoder = _BSONEncoder()
        encoder.wrapper = wrapper
        try value.encode(to: encoder)
    }
}
