import Foundation

/// A helper that is able to decode BSON data types into a `Decodable` type
public struct BSONDecoder {
    /// The configuration used for decoding
    public var settings: BSONDecoderSettings
    
    /// A dictionary you use to customize the decoding process by providing contextual information.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Creates a new decoder using fresh settings
    public init(settings: BSONDecoderSettings = .adaptive) {
        self.settings = settings
    }
}

/// MARK: Strategies

extension BSONDecoderSettings.FloatDecodingStrategy {
    /// Decodes the `value` with a key of `key` to a `Float` using the current strategy
    internal func decode<K: CodingKey>(fromKey key: K, in value: DecoderValue, path: [String]) throws -> Float {
        switch self {
        case .double:
            return try Float(value.unwrap(asType: Double.self, atKey: key, path: path))
        case .string:
            let string = try value.unwrap(asType: String.self, atKey: key, path: path)
            
            guard let float = Float(string) else {
                throw BSONValueNotFound(type: Float.self, path: path)
            }
            
            return float
        case .adaptive:
            unimplemented()
        case .custom(let strategy):
            guard
                case .document(let document) = value,
                let float = try strategy(key.stringValue, document[key.stringValue])
            else {
                throw BSONValueNotFound(type: Float.self, path: path)
            }
            
            return float
        }
    }
    
    /// Decodes the `value` without key to a `Float` using the current strategy
    internal func decode(from value: DecoderValue, path: [String]) throws -> Float {
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
        case .adaptive:
            unimplemented()
        case .custom(let strategy):
            guard let float = try strategy(nil, value.primitive) else {
                throw BSONValueNotFound(type: Float.self, path: path)
            }
            
            return float
        }
    }
}

extension BSONDecoderSettings.IntegerDecodingStrategy {
    /// A helper that converts a String to an integer of type `I`
    internal func convert(from string: String) throws -> I {
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
    
    /// Decodes the `value` without key to an integer of type `I` using the current strategy
    internal func decode(
        from decoder: _BSONDecoder,
        path: @autoclosure () -> [String]
    ) throws -> I {
        switch self {
        case .string, .adaptive:
            if case .string = self {
                guard decoder.primitive is String else {
                    throw BSONTypeConversionError(from: decoder.primitive, to: I.self)
                }
            }
            
            return try convert(from: decoder.wrapped.unwrap(asType: String.self, path: path()))
        case .int32:
            let int = try decoder.wrapped.unwrap(asType: Int32.self, path: path())
            return try int.convert(to: I.self)
        case .int64:
            let int = try decoder.wrapped.unwrap(asType: Int.self, path: path())
            return try int.convert(to: I.self)
        case .anyInteger, .roundingAnyNumber:
            guard let value = decoder.primitive else {
                throw BSONValueNotFound(type: I.self, path: path())
            }
            
            switch value {
            case is Int32:
                let int = try decoder.wrapped.unwrap(asType: Int32.self, path: path())
                return try int.convert(to: I.self)
            case is Int:
                // Necessary also for custom integer types with different widths
                let int = try decoder.wrapped.unwrap(asType: Int.self, path: path())
                return try int.convert(to: I.self)
            case is Double:
                let double = try decoder.wrapped.unwrap(asType: Double.self, path: path())
                return I(double)
            default:
                throw BSONTypeConversionError(from: decoder.primitive, to: I.self)
            }
        case .custom(let strategy):
            guard let value: I = try strategy(nil, decoder.primitive) else {
                throw BSONValueNotFound(type: I.self, path: path())
            }
            
            return value
        }
    }
    
    /// Decodes the `value` with a key of `key` to an integer of type `I` using the current strategy
    internal func decode<K: CodingKey>(
        from decoder: _BSONDecoder,
        forKey key: K,
        path: @autoclosure () -> [String]
    ) throws -> I {
        guard let identifier = decoder.document?.typeIdentifier(of: key.stringValue) else {
            throw BSONValueNotFound(type: I.self, path: path())
        }
        
        switch (self, identifier) {
        case (.string, .string), (.adaptive, .string):
            return try convert(from: decoder.wrapped.unwrap(asType: String.self, atKey: key, path: path()))
        case (.int32, .int32), (.adaptive, .int32), (.anyInteger, .int32), (.roundingAnyNumber, .int32):
            let int = try decoder.wrapped.unwrap(asType: Int32.self, atKey: key, path: path())
            return try int.convert(to: I.self)
        case (.int64, .int64), (.adaptive, .int64), (.anyInteger, .int64), (.roundingAnyNumber, .int64):
            let int = try decoder.wrapped.unwrap(asType: Int.self, atKey: key, path: path())
            return try int.convert(to: I.self)
        case (.roundingAnyNumber, .double), (.adaptive, .double):
            let double = try decoder.wrapped.unwrap(asType: Double.self, atKey: key, path: path())
            return I(double)
        case (.custom(let strategy), _):
            guard let value: I = try strategy(
                key.stringValue,
                decoder.document?[key.stringValue]
            ) else {
                throw BSONValueNotFound(type: I.self, path: path())
            }
            
            return value
        default:
            throw BSONTypeConversionError(from: decoder.document?[key.stringValue], to: I.self)
        }
    }
}

extension BSONDecoderSettings.DoubleDecodingStrategy {
    internal func decode(primitive: Primitive, path: @autoclosure () -> [String]) throws -> Double {
        switch (primitive, self) {
        case (let string as String, .textual), (let string as String, .adaptive):
            guard let double = try Double(string) else {
                throw BSONValueNotFound(type: Double.self, path: path())
            }
            
            return double
        case (let double as Double, _):
            return double
        case (let int as Int32, .numerical), (let int as Int32, .adaptive):
            return Double(int)
        case (let int as Int, .numerical), (let int as Int, .adaptive):
            return Double(int)
        default:
            throw BSONTypeConversionError(from: primitive, to: Double.self)
        }
    }
    
    internal func decode(from decoder: _BSONDecoder, path: @autoclosure () -> [String]) throws -> Double {
        switch self {
        case .custom(let strategy):
            guard let double = try strategy(nil, decoder.primitive) else {
                throw BSONValueNotFound(type: Double.self, path: path())
            }
            
            return double
        default:
            guard
                let primitive = decoder.primitive
            else {
                throw BSONValueNotFound(type: Double.self, path: path())
            }
            
            return try decode(primitive: primitive, path: path)
        }
    }
    
    internal func decode<K: CodingKey>(from decoder: _BSONDecoder, forKey key: K, path: @autoclosure () -> [String]) throws -> Double {
        switch self {
        case .custom(let strategy):
            guard let double = try strategy(key.stringValue, decoder.document?[key.stringValue]) else {
                throw BSONValueNotFound(type: Double.self, path: path())
            }
            
            return double
        default:
            guard
                let primitive = decoder.document?[key.stringValue],
                let identifier = decoder.document?.typeIdentifier(of: key.stringValue)
                else {
                    throw BSONValueNotFound(type: Double.self, path: path())
            }
            
            return try decode(primitive: primitive, path: path)
        }
    }
}

extension BSONDecoder {
    public func decode<D: Decodable>(_ type: D.Type, fromPrimitive primitive: Primitive) throws -> D {
        var decoder = _BSONDecoder(wrapped: .primitive(primitive), settings: self.settings, codingPath: [], userInfo: self.userInfo)
        return try D(from: decoder)
    }
        
    public func decode<D: Decodable>(_ type: D.Type, from document: Document) throws -> D {
        var decoder = _BSONDecoder(wrapped: .document(document), settings: self.settings, codingPath: [], userInfo: self.userInfo)
        return try D(from: decoder)
    }
}

internal enum DecoderValue {
    case primitive(Primitive)
    case nothing
    case document(Document)
    
    var primitive: Primitive? {
        switch self {
        case .document(let doc):
            return doc
        case .primitive(let value):
            return value
        case .nothing:
            return nil
        }
    }
    
    func unwrap<P: Primitive, K: CodingKey>(asType type: P.Type, atKey key: K, path: [String]) throws -> P {
        guard let document = self.primitive as? Document else {
            throw BSONValueNotFound(type: P.self, path: path)
        }
        
        return try document.assertPrimitive(typeOf: P.self, forKey: key.stringValue)
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

internal struct _BSONDecoder: Decoder {
    var codingPath: [CodingKey]
    var keyPath: [String] {
        return codingPath.map { $0.stringValue }
    }
    
    var userInfo: [CodingUserInfoKey: Any]
    
    let wrapped: DecoderValue
    
    var document: Document? {
        if case .document(let doc) = wrapped {
            return doc
        } else if let doc = self.primitive as? Document {
            return doc
        }
        
        return nil
    }
    
    var primitive: Primitive? {
        switch wrapped {
        case .document(let doc):
            return doc
        case .primitive(let p):
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
            let value = document[key]
        else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        return try self.lossyDecodeString(value: value)
    }
    
    func lossyDecodeString(path: @autoclosure () -> [String]) throws -> String {
        guard case .primitive(let value) = wrapped else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        return try self.lossyDecodeString(value: value)
    }
    
    func lossyDecodeString(value: Primitive) throws -> String {
        switch value {
        case let string as String:
            return string
        case let double as String:
            return double.description
        case let int as Int32:
            return int.description
        case let int as Int:
            return int.description
        case let bool as Bool:
            return bool ? "true" : "false"
        case let objectId as ObjectId:
            return objectId.hexString
        default:
            throw BSONTypeConversionError(from: value, to: String.self)
        }
    }
    
    init(wrapped: DecoderValue, settings: BSONDecoderSettings, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.wrapped = wrapped
        self.settings = settings
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard wrapped.primitive as? Document != nil else {
            throw BSONValueNotFound(type: Document.self, path: self.keyPath)
        }
        
        return KeyedDecodingContainer(KeyedBSONDecodingContainer(for: self, codingPath: self.codingPath))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try UnkeyedBSONDecodingContainer(decoder: self, codingPath: self.codingPath)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueBSONDecodingContainer(for: self, codingPath: self.codingPath)
    }
}

extension BSONDecoderSettings.StringDecodingStrategy {
    internal func decode<K: CodingKey>(
        from decoder: _BSONDecoder,
        forKey key: K,
        path: @autoclosure () -> [String]
    ) throws -> String {
        guard
            let primitive = decoder.document?[key.stringValue]
        else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        let decoder = _BSONDecoder(wrapped: .primitive( primitive), settings: decoder.settings, codingPath: decoder.codingPath + [key], userInfo: decoder.userInfo)
        
        return try decode(from: decoder, path: path)
    }
        
    internal func decode(from decoder: _BSONDecoder, path: @autoclosure () -> [String]) throws -> String {
        guard let primitive = decoder.primitive else {
            throw BSONValueNotFound(type: String.self, path: path())
        }
        
        switch (primitive, self) {
        case (let string as String, .string):
            return string
        case (let int as Int32, .integers), (let int as Int32, .numerical):
            return int.description
        case (let int as Int, .integers), (let int as Int, .numerical):
            return int.description
        case (let double as Double, .numerical):
            return double.description
        case (_, .adaptive):
            return try decoder.lossyDecodeString(value: primitive)
        case (_, .custom(let strategy)):
            guard let string = try strategy(nil, decoder.primitive) else {
                throw BSONValueNotFound(type: String.self, path: path())
            }
            
            return string
        default:
            throw BSONValueNotFound(type: String.self, path: path())
        }
    }
}

extension FixedWidthInteger {
    /// Converts the current FixedWidthInteger to another FixedWithInteger type `I`
    ///
    /// Throws a `BSONTypeConversionError` if the range of `I` does not contain `self`
    internal func convert<I: FixedWidthInteger>(to int: I.Type) throws -> I {
        // If I is smaller in width we need to see if the current integer fits inside of I
        if I.bitWidth < Self.bitWidth {
            if numericCast(I.max) < self {
                throw BSONTypeConversionError(from: self, to: I.self)
            } else if numericCast(I.min) > self {
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

extension Primitive {
    /// Asserts that the primitive is of type `P`
    ///
    /// Throws a `BSONTypeConversionError` otherwise
    internal func assert<P: Primitive>(asType type: P.Type) throws -> P {
        guard let value = self as? P else {
            throw BSONTypeConversionError(from: self, to: P.self)
        }
        
        return value
    }
}

/// MARK: Decoding types

internal struct EndOfBSONDocument: Error {}

internal extension Array where Element == CodingKey {
    var path: [String] {
        return self.map { $0.stringValue }
    }
}
