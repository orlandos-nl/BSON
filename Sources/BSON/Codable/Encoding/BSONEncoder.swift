import Foundation

/// An object that encodes instances of `Encodable` types as BSON Documents.
public final class BSONEncoder {
    
    // MARK: Encoding
    
    /// Creates a new, reusable encoder with the given strategies
    public init(strategies: BSONEncoderStrategies = .default) {
        self.strategies = strategies
    }
    
    /// Returns the BSON-encoded representation of the value you supply
    ///
    /// If there's a problem encoding the value you supply, this method throws an error based on the type of problem:
    ///
    /// - The value fails to encode, or contains a nested value that fails to encode—this method throws the corresponding error.
    /// - The value can't be encoded as a BSON array or BSON object—this method throws the invalidValue error.
    public func encode(_ value: Encodable) throws -> Document {
        let encoder = _BSONEncoder(strategies: self.strategies, userInfo: self.userInfo)
        
        try value.encode(to: encoder)
        
        return encoder.target.document
    }
    
    // MARK: Configuration
    
    /// Configures the behavior of the BSON Encoder. See the documentation on `BSONEncoderStrategies` for details.
    public var strategies: BSONEncoderStrategies
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
}

fileprivate final class _BSONEncoder : Encoder, AnyBSONEncoder {
    enum Target {
        case document(Document)
        case primitive(get: () -> Primitive?, set: (Primitive?) -> ())
        
        var document: Document {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get() as? Document ?? Document()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
        
        var primitive: Primitive? {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue as! Document)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
    }
    var target: Target
    
    // MARK: Configuration
    
    let strategies: BSONEncoderStrategies
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: Initialization
    
    init(strategies: BSONEncoderStrategies, codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey : Any], target: Target = .document([:])) {
        self.strategies = strategies
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.target = target
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = _BSONKeyedEncodingContainer<Key>(
            encoder: self,
            codingPath: codingPath
        )
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _BSONUnkeyedEncodingContainer(
            encoder: self,
            codingPath: codingPath
        )
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _BSONSingleValueEncodingContainer(
            encoder: self,
            codingPath: codingPath
        )
    }
    
    // MARK: Encoding
    func encode(document: Document) throws {
        self.target.document = document
    }
    
    subscript(key: CodingKey) -> Primitive? {
        get {
            return self.target.document[converted(key.stringValue)]
        }
        set {
            self.target.document[converted(key.stringValue)] = newValue
        }
    }
    
    func converted(_ key: String) -> String {
        // TODO: Implement key strategies
        return key
    }
    
    func makePrimitive(_ value: UInt64) throws -> Primitive {
        switch strategies.unsignedIntegerEncodingStrategy {
        case .int64:
            guard value <= UInt64(Int64.max) else {
                let debugDescription = "Cannot encode \(value) as Int in BSON, because it is too large. You can use BSONEncodingStrategies.UnsignedIntegerEncodingStrategy.string to encode the integer as a String."
                
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: codingPath,
                        debugDescription: debugDescription
                    )
                )
            }
            
            return Int64(value)
        case .string:
            return "\(value)"
        }
    }
    
    func nestedEncoder(forKey key: CodingKey) -> _BSONEncoder {
        return _BSONEncoder(
            strategies: strategies,
            codingPath: codingPath + [key],
            userInfo: userInfo,
            target: .primitive(
                get: { self[key] },
                set: { self[key] = $0 }
            )
        )
    }
}

fileprivate struct _BSONKeyedEncodingContainer<Key : CodingKey> : KeyedEncodingContainerProtocol {
    
    var encoder: _BSONEncoder
    
    var codingPath: [CodingKey]
    
    init(encoder: _BSONEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    // MARK: KeyedEncodingContainerProtocol
    
    mutating func encodeNil(forKey key: Key) throws {
        switch encoder.strategies.keyedNilEncodingStrategy {
        case .null:
            encoder.target.document[encoder.converted(key.stringValue)] = BSON.Null()
        case .omitted:
            return
        }
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        encoder[key] = Double(value)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        encoder[key] = Int32(value)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        encoder[key] = Int32(value)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        encoder[key] = value
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        encoder[key] = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        encoder[key] = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        encoder[key] = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        encoder[key] = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        encoder[key] = try encoder.makePrimitive(value)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        switch value {
        case let primitive as Primitive:
            encoder[key] = primitive
        default:
            let nestedEncoder = encoder.nestedEncoder(forKey: key)
            try value.encode(to: nestedEncoder)
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nestedEncoder = encoder.nestedEncoder(forKey: key)
        return nestedEncoder.container(keyedBy: NestedKey.self)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let nestedEncoder = encoder.nestedEncoder(forKey: key)
        return nestedEncoder.unkeyedContainer()
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder.nestedEncoder(forKey: BSONKey.super)
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder.nestedEncoder(forKey: key)
    }
}

fileprivate struct _BSONUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    
    var count: Int {
        return encoder.target.document.count
    }
    
    var encoder: _BSONEncoder
    
    var codingPath: [CodingKey]
    
    init(encoder: _BSONEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
        
        encoder.target.document = Document(isArray: true)
    }
    
    // MARK: UnkeyedEncodingContainerProtocol
    
    mutating func encodeNil() throws {
        encoder.target.document.append(BSON.Null())
    }
    
    mutating func encode(_ value: Bool) throws {
        encoder.target.document.append(value)
    }
    
    mutating func encode(_ value: String) throws {
        encoder.target.document.append(value)
    }
    
    mutating func encode(_ value: Double) throws {
        encoder.target.document.append(value)
    }
    
    mutating func encode(_ value: Float) throws {
        encoder.target.document.append(Double(value))
    }
    
    mutating func encode(_ value: Int) throws {
        encoder.target.document.append(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        encoder.target.document.append(Int32(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        encoder.target.document.append(Int32(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        encoder.target.document.append(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        encoder.target.document.append(Int(value))
    }
    
    mutating func encode(_ value: UInt) throws {
        encoder.target.document.append(try encoder.makePrimitive(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt8) throws {
        encoder.target.document.append(try encoder.makePrimitive(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt16) throws {
        encoder.target.document.append(try encoder.makePrimitive(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt32) throws {
        encoder.target.document.append(try encoder.makePrimitive(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt64) throws {
        encoder.target.document.append(try encoder.makePrimitive(value))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        switch value {
        case let primitive as Primitive:
            encoder.target.document.append(primitive)
        default:
            let nestedEncoder = makeNestedEncoder()
            try value.encode(to: nestedEncoder)
        }
    }
    
    func makeNestedEncoder() -> _BSONEncoder {
        let index = encoder.target.document.count
        let key = BSONKey(stringValue: "\(index)", intValue: index)
        encoder.target.document.append(Null())
        
        return _BSONEncoder(
            strategies: encoder.strategies,
            codingPath: codingPath + [key],
            userInfo: encoder.userInfo,
            target: .primitive(
                get: { self.encoder[key] },
                set: {
                    self.encoder[key] = $0
                }
            )
        )
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return makeNestedEncoder().container(keyedBy: NestedKey.self)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return makeNestedEncoder().unkeyedContainer()
    }
    
    mutating func superEncoder() -> Encoder {
        return makeNestedEncoder()
    }
}

fileprivate struct _BSONSingleValueEncodingContainer : SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    var encoder: _BSONEncoder
    
    init(encoder: _BSONEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    func encodingPrecheck(_ value: Any) throws {
        switch encoder.target {
        case .primitive: return
        case .document:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Attempted to encode on the top level through a single value container"
                )
            )
        }
    }
    
    mutating func encodeNil() throws {
        try encodingPrecheck(nil as Primitive? as Any)
        encoder.target.primitive = nil
    }
    
    mutating func encode(_ value: Bool) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: String) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: Double) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: Float) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = Double(value)
    }
    
    mutating func encode(_ value: Int) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: Int8) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = Int32(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = Int32(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: Int64) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = value
    }
    
    mutating func encode(_ value: UInt) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = try encoder.makePrimitive(UInt64(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        try encodingPrecheck(value)
        encoder.target.primitive = try encoder.makePrimitive(value)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try encodingPrecheck(value)
        
        switch value {
        case let primitive as Primitive:
            encoder.target.primitive = primitive
        default:
            try value.encode(to: encoder)
        }
    }
    
    
}
