import Foundation

private enum BSONEncoderError: Error {
    case encodableNotDocument
}

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

        guard encoder.target == .document, let document = encoder.document else {
            throw BSONEncoderError.encodableNotDocument
        }

        return document
    }

    /// Returns the BSON-encoded representation of the value you supply
    ///
    /// If there's a problem encoding the value you supply, this method throws an error based on the type of problem:
    ///
    /// - The value fails to encode, or contains a nested value that fails to encode—this method throws the corresponding error.
    public func encodePrimitive(_ value: Encodable) throws -> Primitive? {
        if let primitive = value as? Primitive {
            return primitive
        }
        
        let encoder = _BSONEncoder(
            strategies: self.strategies,
            userInfo: self.userInfo
        )

        try value.encode(to: encoder)

        guard let target = encoder.target else {
            return nil
        }

        switch target {
        case .primitive:
            return encoder.primitive
        case .document:
            return encoder.document
        }
    }

    // MARK: Configuration

    /// Configures the behavior of the BSON Encoder. See the documentation on `BSONEncoderStrategies` for details.
    public var strategies: BSONEncoderStrategies

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
}

fileprivate final class _BSONEncoder: Encoder, AnyBSONEncoder {
    enum Target {
        case document
        case primitive
    }

    var target: Target?
    var document: Document? {
        didSet {
            writer?(document)
        }
    }

    var primitive: Primitive? {
        didSet {
            writer?(primitive)
        }
    }

    // MARK: Configuration

    let strategies: BSONEncoderStrategies

    var codingPath: [CodingKey]

    var writer: ((Primitive?) -> ())?
    var userInfo: [CodingUserInfoKey: Any]

    // MARK: Initialization

    init(strategies: BSONEncoderStrategies, codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any]) {
        self.strategies = strategies
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.target = nil
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        self.target = .document
        self.document = Document()

        let container = _BSONKeyedEncodingContainer<Key>(
            encoder: self,
            codingPath: codingPath
        )

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        self.target = .document
        self.document = Document()

        return _BSONUnkeyedEncodingContainer(
            encoder: self,
            codingPath: codingPath
        )
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self.target = .primitive

        return _BSONSingleValueEncodingContainer(
            encoder: self,
            codingPath: codingPath
        )
    }

    // MARK: Encoding
    func encode(document: Document) throws {
        self.document = document
    }

    subscript(key: CodingKey) -> Primitive? {
        get {
            return self.document?[converted(key.stringValue)]
        }
        set {
            self.document?[converted(key.stringValue)] = newValue
        }
    }

    func converted(_ key: String) -> String {
        if strategies.filterDollarPrefix, key.first == "$" {
            var key = key
            key.removeFirst()
            return key
        }
        
        return key
    }

    func makePrimitive(_ value: UInt64) throws -> Primitive {
        switch strategies.unsignedIntegerEncodingStrategy {
        case .int64:
            guard value <= UInt64(Int.max) else {
                let debugDescription = "Cannot encode \(value) as Int in BSON, because it is too large. You can use BSONEncodingStrategies.UnsignedIntegerEncodingStrategy.string to encode the integer as a String."

                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: codingPath,
                        debugDescription: debugDescription
                    )
                )
            }

            return _BSON64BitInteger(value)
        case .string:
            return "\(value)"
        }
    }

    func nestedEncoder(forKey key: CodingKey) -> _BSONEncoder {
        let encoder = _BSONEncoder(
            strategies: strategies,
            codingPath: codingPath + [key],
            userInfo: userInfo
        )

        encoder.writer = { [weak self] primitive in
            self?[key] = primitive
        }

        return encoder
    }
}

fileprivate struct _BSONKeyedEncodingContainer<Key: CodingKey> : KeyedEncodingContainerProtocol {
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
            encoder.document?[encoder.converted(key.stringValue)] = BSON.Null()
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
        encoder[key] = _BSON64BitInteger(value)
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
        encoder[key] = _BSON64BitInteger(value)
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

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        switch value {
        case let primitive as Primitive:
            encoder[key] = primitive
        default:
            let nestedEncoder = encoder.nestedEncoder(forKey: key)
            try value.encode(to: nestedEncoder)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
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

fileprivate struct _BSONUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    var count: Int {
        return encoder.document?.count ?? 0
    }

    var encoder: _BSONEncoder

    var codingPath: [CodingKey]

    init(encoder: _BSONEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath

        encoder.document = Document(isArray: true)
    }

    // MARK: UnkeyedEncodingContainerProtocol

    mutating func encodeNil() throws {
        encoder.document?.append(BSON.Null())
    }

    mutating func encode(_ value: Bool) throws {
        encoder.document?.append(value)
    }

    mutating func encode(_ value: String) throws {
        encoder.document?.append(value)
    }

    mutating func encode(_ value: Double) throws {
        encoder.document?.append(value)
    }

    mutating func encode(_ value: Float) throws {
        encoder.document?.append(Double(value))
    }

    mutating func encode(_ value: Int) throws {
        encoder.document?.append(_BSON64BitInteger(value))
    }

    mutating func encode(_ value: Int8) throws {
        encoder.document?.append(Int32(value))
    }

    mutating func encode(_ value: Int16) throws {
        encoder.document?.append(Int32(value))
    }

    mutating func encode(_ value: Int32) throws {
        encoder.document?.append(value)
    }

    mutating func encode(_ value: Int64) throws {
        encoder.document?.append(_BSON64BitInteger(value))
    }

    mutating func encode(_ value: UInt) throws {
        encoder.document?.append(try encoder.makePrimitive(UInt64(value)))
    }

    mutating func encode(_ value: UInt8) throws {
        encoder.document?.append(try encoder.makePrimitive(UInt64(value)))
    }

    mutating func encode(_ value: UInt16) throws {
        encoder.document?.append(try encoder.makePrimitive(UInt64(value)))
    }

    mutating func encode(_ value: UInt32) throws {
        encoder.document?.append(try encoder.makePrimitive(UInt64(value)))
    }

    mutating func encode(_ value: UInt64) throws {
        encoder.document?.append(try encoder.makePrimitive(value))
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        switch value {
        case let primitive as Primitive:
            encoder.document?.append(primitive)
        default:
            let nestedEncoder = makeNestedEncoder()
            try value.encode(to: nestedEncoder)
        }
    }

    func makeNestedEncoder() -> _BSONEncoder {
        let index = encoder.document?.count ?? 0
        return encoder.nestedEncoder(forKey: BSONKey(stringValue: "\(index)", intValue: index))
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return makeNestedEncoder().container(keyedBy: NestedKey.self)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return makeNestedEncoder().unkeyedContainer()
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }
}

fileprivate struct _BSONSingleValueEncodingContainer: SingleValueEncodingContainer, AnySingleValueBSONEncodingContainer {
    var codingPath: [CodingKey]
    var encoder: _BSONEncoder

    init(encoder: _BSONEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    mutating func encodeNil() throws {
        encoder.primitive = nil
    }

    mutating func encode(_ value: Bool) throws {
        encoder.primitive = value
    }

    mutating func encode(_ value: String) throws {
        encoder.primitive = value
    }

    mutating func encode(_ value: Double) throws {
        encoder.primitive = value
    }

    mutating func encode(_ value: Float) throws {
        encoder.primitive = Double(value)
    }

    mutating func encode(_ value: Int) throws {
        encoder.primitive = _BSON64BitInteger(value)
    }

    mutating func encode(_ value: Int8) throws {
        encoder.primitive = Int32(value)
    }

    mutating func encode(_ value: Int16) throws {
        encoder.primitive = Int32(value)
    }

    mutating func encode(_ value: Int32) throws {
        encoder.primitive = value
    }

    mutating func encode(_ value: Int64) throws {
        encoder.primitive = _BSON64BitInteger(value)
    }

    mutating func encode(_ value: UInt) throws {
        encoder.primitive = try encoder.makePrimitive(UInt64(value))
    }

    mutating func encode(_ value: UInt8) throws {
        encoder.primitive = try encoder.makePrimitive(UInt64(value))
    }

    mutating func encode(_ value: UInt16) throws {
        encoder.primitive = try encoder.makePrimitive(UInt64(value))
    }

    mutating func encode(_ value: UInt32) throws {
        encoder.primitive = try encoder.makePrimitive(UInt64(value))
    }

    mutating func encode(_ value: UInt64) throws {
        encoder.primitive = try encoder.makePrimitive(value)
    }

    mutating func encode(primitive: Primitive) throws {
        encoder.primitive = primitive
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        switch value {
        case let primitive as Primitive:
            encoder.primitive = primitive
        default:
            try value.encode(to: encoder)
        }
    }
}
