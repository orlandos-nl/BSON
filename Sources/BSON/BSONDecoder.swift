import Foundation

public struct BSONDecoder {
    public var settings: BSONDecoderSettings
    
    /// The globally default BSONDecoder
    public static var `default`: () -> (BSONDecoder) = {
        return BSONDecoder()
    }
    
    public func decode<D: Decodable>(_ type: D.Type, from document: Document) throws -> D {
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.settings)
        return try D(from: decoder)
    }
    
    public init() {
        self.settings = BSONDecoderSettings()
    }
}

public struct BSONDecoderSettings {
    public typealias DecodingStrategy<P> = (Primitive?) throws -> P?
    
    public enum FloatDecodingStrategy {
        case string
        case double
        case custom(DecodingStrategy<Float>)
        
        fileprivate func decode<K: CodingKey>(fromKey key: K, in value: DecoderValue, path: [String]) throws -> Float {
            switch self {
            case .double:
                return try Float(value.unwrap(asType: Double.self, atKey: key, path: path))
            case .string:
                let string = try value.unwrap(asType: String.self, atKey: key, path: path)
                
                guard let float = Float(string) else {
                    throw BSONValueNotFound(type: Float.self, path: path)
                }
                
                return float
            case .custom(let strategy):
                guard
                    case .document(let document) = value,
                    let float = try strategy(document[key.stringValue])
                else {
                    throw BSONValueNotFound(type: Float.self, path: path)
                }
                
                return float
            }
        }
        
        fileprivate func decode(from value: DecoderValue, path: [String]) throws -> Float {
            switch self {
            case .double:
                let double = try value.unwrap(asType: Double.self, path: path)
                return Float(double)
            case .string:
                let string = try value.unwrap(asType: String.self, path: path)
                
                guard let float = Float(string) else {
                    throw BSONValueNotFound(type: Float.self, path: path)
                }
                
                return float
            case .custom(let strategy):
                guard let float = try strategy(value.primitive) else {
                    throw BSONValueNotFound(type: Float.self, path: path)
                }
                
                return float
            }
        }
    }
    
    public enum IntegerDecodingStrategy<I: FixedWidthInteger> {
        case string
        case int32
        case int64
        case anyInteger
        case roundingAnyNumber
        case stringOrNumber
        case custom(DecodingStrategy<I>)
        
        fileprivate func convert(from string: String) throws -> I {
            if I.isSigned {
                guard let int = Int64(string) else {
                    throw BSONTypeConversionError(from: string, to: I.self)
                }
                
                return numericCast(int)
            } else {
                guard let int = UInt64(string) else {
                    throw BSONTypeConversionError(from: string, to: I.self)
                }
                
                return numericCast(int)
            }
        }
        
        fileprivate func decode(
            from decoder: _BSONDecoder,
            path: @autoclosure () -> [String]
        ) throws -> I {
            switch self {
            case .string, .stringOrNumber:
                if case .stringOrNumber = self {
                    guard decoder.identifier == .string else {
                        throw BSONTypeConversionError(from: decoder.primitive, to: I.self)
                    }
                }
                
                return try convert(from: decoder.wrapped.unwrap(asType: String.self, path: path()))
            case .int32:
                let int = try decoder.wrapped.unwrap(asType: Int32.self, path: path())
                return try int.convert(to: I.self)
            case .int64:
                let int = try decoder.wrapped.unwrap(asType: Int64.self, path: path())
                return try int.convert(to: I.self)
            case .anyInteger, .roundingAnyNumber:
                guard let type = decoder.identifier else {
                    throw BSONValueNotFound(type: I.self, path: path())
                }
                
                switch (type, self) {
                case (.int32, _):
                    let int = try decoder.wrapped.unwrap(asType: Int32.self, path: path())
                    return try int.convert(to: I.self)
                case (.int64, _):
                    // Necessary also for custom integer types
                    let int = try decoder.wrapped.unwrap(asType: Int64.self, path: path())
                    return try int.convert(to: I.self)
                case (.double, .roundingAnyNumber):
                    let double = try decoder.wrapped.unwrap(asType: Double.self, path: path())
                    return I(double)
                default:
                    throw BSONTypeConversionError(from: decoder.primitive, to: I.self)
                }
            case .custom(let strategy):
                guard let value: I = try strategy(decoder.primitive) else {
                    throw BSONValueNotFound(type: I.self, path: path())
                }
                
                return value
            }
        }
        
        fileprivate func decode<K: CodingKey>(
            from decoder: _BSONDecoder,
            forKey key: K,
            path: @autoclosure () -> [String]
        ) throws -> I {
            switch self {
            case .string, .stringOrNumber:
                if case .stringOrNumber = self {
                    guard decoder.identifier == .string else {
                        throw BSONTypeConversionError(from: decoder.primitive, to: I.self)
                    }
                }
                
                return try convert(from: decoder.wrapped.unwrap(asType: String.self, atKey: key, path: path()))
            case .int32:
                let int = try decoder.wrapped.unwrap(asType: Int32.self, atKey: key, path: path())
                return try int.convert(to: I.self)
            case .int64:
                let int = try decoder.wrapped.unwrap(asType: Int64.self, atKey: key, path: path())
                return try int.convert(to: I.self)
            case .anyInteger, .roundingAnyNumber:
                guard let type = decoder.document?.typeIdentifier(of: key.stringValue) else {
                    throw BSONValueNotFound(type: I.self, path: path())
                }
                
                switch (type, self) {
                case (.int32, _):
                    let int = try decoder.wrapped.unwrap(asType: Int32.self, atKey: key, path: path())
                    return try int.convert(to: I.self)
                case (.int64, _):
                    // Necessary also for custom integer types
                    let int = try decoder.wrapped.unwrap(asType: Int64.self, atKey: key, path: path())
                    return try int.convert(to: I.self)
                case (.double, .roundingAnyNumber):
                    let double = try decoder.wrapped.unwrap(asType: Double.self, atKey: key, path: path())
                    return I(double)
                default:
                    throw BSONTypeConversionError(from: decoder.document?[key.stringValue], to: I.self)
                }
            case .custom(let strategy):
                guard let value: I = try strategy(decoder.document?[key.stringValue]) else {
                    throw BSONValueNotFound(type: I.self, path: path())
                }
                
                return value
            }
        }
    }
    
    public enum DoubleDecodingStrategy {
        case double
        case numerical
        case textual
        case numericAndTextual
        
        case custom(DecodingStrategy<Double>)
        
        fileprivate func decode(from decoder: _BSONDecoder, path: [String]) throws -> Double {
            let double: Double?
            
            switch self {
            case .custom(let strategy):
                double = try strategy(decoder.primitive)
            default:
                guard let identifier = decoder.identifier else {
                    throw BSONValueNotFound(type: Double.self, path: path)
                }
                
                switch (identifier, self) {
                case (.string, .textual), (.string, .numericAndTextual):
                    double = try Double(decoder.wrapped.unwrap(asType: String.self, path: path))
                case (.double, _):
                    double = try decoder.wrapped.unwrap(asType: Double.self, path: path)
                case (.int32, .numerical), (.int32, .numericAndTextual):
                    double = try Double(decoder.wrapped.unwrap(asType: Int32.self, path: path))
                case (.int64, .numerical), (.int64, .numericAndTextual):
                    double = try Double(decoder.wrapped.unwrap(asType: Int64.self, path: path))
                default:
                    throw BSONTypeConversionError(from: decoder.primitive, to: Double.self)
                }
            }
            
            if let double = double {
                return double
            }
            
            throw BSONValueNotFound(type: Double.self, path: path)
        }
    }
    
    public var decodeNullAsNil: Bool = true
    public var lossyDecodeIntoString: Bool = false
    public var decodeObjectIdFromString: Bool = false
    
    public var floatDecodingStrategy: FloatDecodingStrategy = .double
    public var doubleDecodingStrategy: DoubleDecodingStrategy = .double
    
    public var int8DecodingStrategy: IntegerDecodingStrategy<Int8> = .anyInteger
    public var int16DecodingStrategy: IntegerDecodingStrategy<Int16> = .anyInteger
    public var int32DecodingStrategy: IntegerDecodingStrategy<Int32> = .int32
    public var int64DecodingStrategy: IntegerDecodingStrategy<Int64> = .int64
    public var intDecodingStrategy: IntegerDecodingStrategy<Int> = .anyInteger
    public var uint8DecodingStrategy: IntegerDecodingStrategy<UInt8> = .anyInteger
    public var uint16DecodingStrategy: IntegerDecodingStrategy<UInt16> = .anyInteger
    public var uint32DecodingStrategy: IntegerDecodingStrategy<UInt32> = .anyInteger
    public var uint64DecodingStrategy: IntegerDecodingStrategy<UInt64> = .anyInteger
    public var uintDecodingStrategy: IntegerDecodingStrategy<UInt> = .anyInteger
}

fileprivate enum DecoderValue {
    case primitive(UInt8, Primitive)
    case nothing
    case document(Document)
    
    var primitive: Primitive? {
        switch self {
        case .document(let doc):
            return doc
        case .primitive(_, let value):
            return value
        case .nothing:
            return nil
        }
    }
    
    func unwrap<P: Primitive, K: CodingKey>(asType type: P.Type, atKey key: K, path: [String]) throws -> P {
        switch self {
        case .document(let document):
            return try document.assertPrimitive(typeOf: P.self, forKey: key.stringValue)
        default:
            throw BSONValueNotFound(type: P.self, path: path)
        }
    }
    
    func unwrap<P: Primitive>(asType type: P.Type, path: [String]) throws -> P {
        switch self {
        case .primitive(let primitive):
            guard let primitive = primitive as? P else {
                throw BSONValueNotFound(type: P.self, path: path)
            }
            
            return primitive
        default:
            throw BSONValueNotFound(type: P.self, path: path)
        }
    }
}

fileprivate struct _BSONDecoder: Decoder {
    var codingPath: [CodingKey]
    var keyPath: [String] {
        return codingPath.map { $0.stringValue }
    }
    
    var userInfo: [CodingUserInfoKey : Any]
    
    let wrapped: DecoderValue
    
    var document: Document? {
        if case .document(let doc) = wrapped {
            return doc
        }
        
        return nil
    }
    
    var identifier: UInt8? {
        if case .primitive(let identifer, _) = wrapped {
            return identifer
        }
        
        return nil
    }
    
    var primitive: Primitive? {
        switch wrapped {
        case .document(let doc):
            return doc
        case .primitive(_, let p):
            return p
        case .nothing:
            return nil
        }
    }
    
    let settings: BSONDecoderSettings
    
    func lossyDecodeString<K: CodingKey>(atKey key: K, path: @autoclosure () -> [String]) throws -> String {
        let key = key.stringValue
        
        guard
            let document = self.document,
            let identifier = document.typeIdentifier(of: key),
            let value = document[key]
        else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        return try self.lossyDecodeString(identifier: identifier, value: value)
    }
    
    func lossyDecodeString(path: @autoclosure () -> [String]) throws -> String {
        guard case .primitive(let identifier, let value) = wrapped else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        return try self.lossyDecodeString(identifier: identifier, value: value)
    }
    
    func lossyDecodeString(identifier: UInt8, value: Primitive) throws -> String {
        switch identifier {
        case .string:
            return try value.assert(asType: String.self)
        case .double:
            return try value.assert(asType: Double.self).description
        case .int32:
            return try value.assert(asType: Int32.self).description
        case .int64:
            return try value.assert(asType: Int64.self).description
        case .boolean:
            return try value.assert(asType: Bool.self) ? "true" : "false"
        case .objectId:
            return try value.assert(asType: ObjectId.self).hexString
        default:
            throw BSONTypeConversionError(from: value, to: String.self)
        }
    }
    
    init(wrapped: DecoderValue, settings: BSONDecoderSettings) {
        self.codingPath = []
        self.userInfo = [:]
        self.wrapped = wrapped
        self.settings = settings
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard case .document = wrapped else {
            throw BSONValueNotFound(type: Document.self, path: self.keyPath)
        }
        
        return KeyedDecodingContainer(KeyedBSONContainer(for: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedBSONContainer(decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueBSONContainer(for: self)
    }
}

fileprivate struct KeyedBSONContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    var allKeys: [K] {
        return self.document.keys.compactMap(K.init)
    }
    
    let decoder: _BSONDecoder
    
    var document: Document {
        // Guaranteed to be a document when initialized
        return self.decoder.document!
    }
    
    init(for decoder: _BSONDecoder) {
        self.codingPath = []
        self.decoder = decoder
    }
    
    func path(forKey key: K) -> [String] {
        return self.codingPath.map { $0.stringValue } + [key.stringValue]
    }
    
    func contains(_ key: K) -> Bool {
        return self.document.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return (self.contains(key) && self.document.typeIdentifier(of: key.stringValue) == .null)
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try self.document.assertPrimitive(typeOf: type, forKey: key.stringValue)
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        if self.decoder.settings.lossyDecodeIntoString {
            return try self.decoder.lossyDecodeString(
                atKey: key,
                path: self.path(forKey: key)
            )
        } else {
            return try self.document.assertPrimitive(typeOf: type, forKey: key.stringValue)
        }
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try self.decoder.settings.doubleDecodingStrategy.decode(
            from: decoder,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try self.decoder.settings.floatDecodingStrategy.decode(
            fromKey: key,
            in: self.decoder.wrapped,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try self.decoder.settings.intDecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try self.decoder.settings.int8DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try self.decoder.settings.int16DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try self.decoder.settings.int32DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try self.decoder.settings.int64DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try self.decoder.settings.uintDecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try self.decoder.settings.uint8DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try self.decoder.settings.uint16DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try self.decoder.settings.uint32DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try self.decoder.settings.uint64DecodingStrategy.decode(
            from: self.decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.document[key.stringValue]) as! T
        } else {
            guard
                let typeIdentifer = self.document.typeIdentifier(of: key.stringValue),
                let value = self.document[key.stringValue]
            else {
                throw BSONValueNotFound(type: T.self, path: path(forKey: key))
            }
            
            let decoder = _BSONDecoder(
                wrapped: .primitive(typeIdentifer, value),
                settings: self.decoder.settings
            )
            return try T.init(from: decoder)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let document = self.document[key.stringValue, as: Document.self] ?? Document()
        
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings)
        
        return KeyedDecodingContainer(KeyedBSONContainer<NestedKey>(for: decoder))
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        let document = try self.decode(Document.self, forKey: key)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings)
        return UnkeyedBSONContainer(decoder: decoder)
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        return decoder
    }
}

fileprivate struct EndOfBSONDocument: Error {}

fileprivate struct SingleValueBSONContainer: SingleValueDecodingContainer, AnySingleValueBSONDecodingContainer {
    var codingPath: [CodingKey]
    
    let decoder: _BSONDecoder
    
    init(for decoder: _BSONDecoder) {
        self.codingPath = []
        self.decoder = decoder
    }
    
    func decodeDocument() throws -> Document {
        guard let doc = self.decoder.document else {
            throw BSONValueNotFound(type: Document.self, path: self.codingPath.path)
        }
        
        return doc
    }
    
    func decodeObjectId() throws -> ObjectId {
        guard let objectId = self.decoder.primitive as? ObjectId else {
            throw BSONValueNotFound(type: ObjectId.self, path: self.codingPath.path)
        }
        
        return objectId
    }
    
    func decodeNil() -> Bool {
        if case .nothing = self.decoder.wrapped {
            return true
        }
        
        return false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try self.decoder.wrapped.unwrap(asType: Bool.self, path: self.codingPath.path)
    }
    
    func decode(_ type: String.Type) throws -> String {
        if self.decoder.settings.lossyDecodeIntoString {
            return try self.decoder.lossyDecodeString(path: self.codingPath.path)
        } else {
            return try self.decoder.wrapped.unwrap(asType: String.self, path: self.codingPath.path)
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try self.decoder.settings.doubleDecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try self.decoder.settings.floatDecodingStrategy.decode(
            from: self.decoder.wrapped,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try self.decoder.settings.intDecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.decoder.settings.int8DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.decoder.settings.int16DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.decoder.settings.int32DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.decoder.settings.int64DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try self.decoder.settings.uintDecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.decoder.settings.uint8DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.decoder.settings.uint16DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.decoder.settings.uint32DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.decoder.settings.uint64DecodingStrategy.decode(
            from: self.decoder,
            path: self.codingPath.path
        )
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.decoder.primitive) as! T
        } else {
            let decoder = _BSONDecoder(wrapped: self.decoder.wrapped, settings: self.decoder.settings)
            return try T.init(from: decoder)
        }
    }
}

fileprivate struct UnkeyedBSONContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    
    var count: Int? {
        return self.iterator.count
    }
    
    var isAtEnd: Bool {
        return self.iterator.isDrained
    }
    
    var currentIndex: Int {
        return self.iterator.currentIndex
    }
    
    let decoder: _BSONDecoder
    
    var iterator: DocumentIterator
    
    mutating func nextElement() throws -> DecoderValue {
        guard let pair = iterator.next() else {
            throw EndOfBSONDocument()
        }
        
        return .primitive(pair.identifier, pair.value)
    }
    
    init(decoder: _BSONDecoder) {
        self.decoder = decoder
        self.codingPath = []
        self.iterator = decoder.document!.makeIterator()
    }
    
    func decodeNil() -> Bool {
        if case .nothing = self.decoder.wrapped {
            return true
        }
        
        return false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try self.decoder.wrapped.unwrap(asType: Bool.self, path: self.codingPath.path)
    }
    
    func decode(_ type: String.Type) throws -> String {
        if self.decoder.settings.lossyDecodeIntoString {
            return try self.decoder.lossyDecodeString(path: self.codingPath.path)
        } else {
            return try self.decoder.wrapped.unwrap(asType: String.self, path: self.codingPath.path)
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try self.decoder.settings.doubleDecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try self.decoder.settings.floatDecodingStrategy.decode(from: self.decoder.wrapped, path: self.codingPath.path)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try self.decoder.settings.intDecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.decoder.settings.int8DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.decoder.settings.int16DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.decoder.settings.int32DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.decoder.settings.int64DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try self.decoder.settings.uintDecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.decoder.settings.uint8DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.decoder.settings.uint16DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.decoder.settings.uint32DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.decoder.settings.uint64DecodingStrategy.decode(from: self.decoder, path: self.codingPath.path)
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.nextElement().primitive) as! T
        } else {
            let decoder = try _BSONDecoder(wrapped: self.nextElement(), settings: self.decoder.settings)
            return try T.init(from: decoder)
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let document = try self.decode(Document.self)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings)
        return KeyedDecodingContainer(KeyedBSONContainer(for: decoder))
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let document = try self.decode(Document.self)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings)
        return UnkeyedBSONContainer(decoder: decoder)
    }
    
    mutating func superDecoder() throws -> Decoder {
        return self.decoder
    }
}

fileprivate extension Array where Element == CodingKey {
    var path: [String] {
        return self.map { $0.stringValue }
    }
}

fileprivate extension FixedWidthInteger {
    func convert<I: FixedWidthInteger>(to int: I.Type) throws -> I {
        // If I is smaller in width we need to see if the current integer fits inside of I
        if I.bitWidth < Self.bitWidth {
            if numericCast(self) > I.max {
                throw BSONTypeConversionError(from: self, to: I.self)
            } else if self < numericCast(I.min) {
                throw BSONTypeConversionError(from: self, to: I.self)
            }
        } else if !I.isSigned {
            // BSON doesn't store unsigned ints and unsigned ints can't be negative
            guard self >= 0 else {
                throw BSONTypeConversionError(from: self, to: I.self)
            }
        }
        
        return numericCast(self)
    }
}

fileprivate extension Primitive {
    func assert<P: Primitive>(asType type: P.Type) throws -> P {
        guard let value = self as? P else {
            throw BSONTypeConversionError(from: self, to: P.self)
        }
        
        return value
    }
}
