public final class BSONEncoder {
    public init() {}
    
    public func encode<E: Encodable>(_ e: E) throws -> Document {
        let encoder = _BSONEncoder()
        try e.encode(to: encoder)
        
        guard let doc = encoder.wrapper.primitive as? Document else {
            throw BSONEncoderError()
        }
        
        return doc
    }
    
    public func encodePrimitive<E: Encodable>(_ e: E) throws -> Primitive {
        let encoder = _BSONEncoder()
        
        try e.encode(to: encoder)
        
        return encoder.wrapper.primitive
    }
}

fileprivate final class PrimitiveWrapper {
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
    
    typealias Dealloc = (Primitive)->()
    
    var subEncoder: _BSONEncoder {
        var encoder = _BSONEncoder()
        encoder.wrapper = PrimitiveWrapper { primitive in
            self.primitive = primitive
        }
        
        return encoder
    }
    
    func keyedSubEncoder(for key: String) -> _BSONEncoder {
        var encoder = _BSONEncoder()
        encoder.wrapper = PrimitiveWrapper { primitive in
            self.doc[key] = primitive
        }
        
        return encoder
    }
    
    var dealloc: Dealloc
    
    init(_ dealloc: @escaping Dealloc) {
        self.primitive = Document()
        self.dealloc = dealloc
    }
    
    func append<BI: BinaryInteger & SignedInteger>(_ value: BI) {
        if value.bitWidth > 32 {
            self.doc.append(Int(value))
        } else {
            self.doc.append(Int32(value))
        }
    }
    
    func append<BI: BinaryInteger & UnsignedInteger>(_ value: BI) {
        if value.bitWidth >= 32 {
            self.doc.append(Int(value))
        } else {
            self.doc.append(Int32(value))
        }
    }
    
    func append<BI: BinaryInteger & SignedInteger>(_ value: BI, for key: String) {
        if value.bitWidth > 32 {
            self.doc[key] = Int(value)
        } else {
            self.doc[key] = Int32(value)
        }
    }
    
    func append<BI: BinaryInteger & UnsignedInteger>(_ value: BI, for key: String) {
        if value.bitWidth >= 32 {
            self.doc[key] = Int(value)
        } else {
            self.doc[key] = Int32(value)
        }
    }
    
    func encode<BI: BinaryInteger & SignedInteger>(_ value: BI) {
        if value.bitWidth > 32 {
            self.doc.append(Int(value))
        } else {
            self.doc.append(Int32(value))
        }
    }
    
    func encode<BI: BinaryInteger & UnsignedInteger>(_ value: BI) {
        if value.bitWidth >= 32 {
            self.primitive = Int(value)
        } else {
            self.primitive = Int32(value)
        }
    }
    
    deinit {
        dealloc(self.primitive)
    }
}

fileprivate struct _BSONEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var primitive: Primitive = Document()
    
    var wrapper = PrimitiveWrapper { _ in }
    
    init() {}
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(BSONKeyedEncodingContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return BSONUnkeyedEncodingContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return BSONSingleValueContainer(wrapper: wrapper)
    }
}

fileprivate struct BSONKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    var codingPath: [CodingKey] = []
    
    let encoder: _BSONEncoder
    
    var wrapper: PrimitiveWrapper {
        return encoder.wrapper
    }
    
    init(encoder: _BSONEncoder) {
        self.encoder = encoder
    }
    
    mutating func encodeNil(forKey key: K) throws {
        wrapper.doc[key.stringValue] = Null()
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        wrapper.doc[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        wrapper.doc[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        wrapper.doc[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        wrapper.append(value, for: key.stringValue)
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        wrapper.doc[key.stringValue] = Double(value)
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        wrapper.doc[key.stringValue] = value
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        wrapper.doc[key.stringValue] = value
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        wrapper.doc[key.stringValue] = try BSONEncoder().encodePrimitive(value)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(BSONKeyedEncodingContainer<NestedKey>(encoder: self.wrapper.keyedSubEncoder(for: key.stringValue)))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return BSONUnkeyedEncodingContainer(encoder: self.wrapper.keyedSubEncoder(for: key.stringValue))
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        return encoder
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
        return KeyedEncodingContainer(BSONKeyedEncodingContainer<NestedKey>(encoder: self.wrapper.subEncoder))
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return BSONUnkeyedEncodingContainer(encoder: self.wrapper.subEncoder)
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
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        wrapper.primitive = value
    }
    
    mutating func encode(_ value: Int64) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        wrapper.encode(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        wrapper.encode(value)
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
