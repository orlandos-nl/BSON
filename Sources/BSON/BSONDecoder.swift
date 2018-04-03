import Foundation

public struct BSONDecoder {
    public var settings: BSONDecoderSettings
    
    /// The globally default BSONDecoder
    public static var `default`: () -> (BSONDecoder) = {
        return BSONDecoder()
    }
    
    public init() {
        self.settings = BSONDecoderSettings()
    }
}

public struct BSONDecoderSettings {
    public typealias DecodingStrategy<P> = (Document, String) throws -> P?
    
    public enum FloatDecodingStrategy {
        case string
        case double
        case custom(DecodingStrategy<Float>)
    }
    
    public enum IntegerDecodingStrategy<I: Integer> {
        case string
        case int32
        case int64
        case anyInteger
        case roundingAnyNumber
        case custom(DecodingStrategy<I>)
    }
    
    public var decodeNullAsNil: Bool = true
    public var permitMissingSubDocuments: Bool = true
    public var floatDecodingStrategy: FloatDecodingStrategy = .double
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

fileprivate struct _BSONDecoder: Decoder {
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    let document: Document
    let settings: BSONDecoderSettings
    
    init(document: Document, settings: BSONDecoderSettings) {
        self.codingPath = []
        self.userInfo = [:]
        self.document = document
        self.settings = settings
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedBSONContainer(for: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        <#code#>
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        <#code#>
    }
}

fileprivate struct KeyedBSONContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    var allKeys: [K]
    
    let decoder: _BSONDecoder
    
    init(for decoder: _BSONDecoder) {
        self.allKeys = []
        self.codingPath = []
        self.decoder = decoder
    }
    
    func contains(_ key: K) -> Bool {
        return self.decoder.document.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return (self.contains(key) && self.decoder.document.typeIdentifier(of: key.stringValue) == .null)
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        switch self.decoder.settings.floatDecodingStrategy {
        case .double:
            let double = try self.decoder.document.assertPrimitive(Double.self, forKey: key.stringValue)
            
            return Float(double)
        case .string:
            let string = try self.decoder.document.assertPrimitive(String.self, forKey: key.stringValue)
            
            guard let float = Float(string) else {
                throw BSONValueNotFound(type: Float.self, key: key.stringValue)
            }
            
            return float
        case .custom(let strategy):
            guard let float = try strategy(self.decoder.document, key.stringValue) else {
                throw BSONValueNotFound(type: Float.self, key: key.stringValue)
            }
            
            return float
        }
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.intDecodingStrategy)
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.int8DecodingStrategy)
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.int16DecodingStrategy)
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.int32DecodingStrategy)
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.int64DecodingStrategy)
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.uintDecodingStrategy)
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.uint8DecodingStrategy)
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.uint16DecodingStrategy)
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.uint32DecodingStrategy)
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try decodeInteger(type, forKey: key, strategy: self.decoder.settings.uint64DecodingStrategy)
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        
    }
    
    public func decodeInteger<I: FixedWidthInteger>(
        _ type: I.Type,
        forKey key: K,
        strategy: BSONDecoderSettings.IntegerDecodingStrategy<I>
    ) throws -> I {
        switch strategy {
        case .string:
            let string = try self.decode(String.self, forKey: key)
            
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
        case .int32:
            return try self.decode(Int32.self, forKey: key).convert(to: I.self)
        case .int64:
            return try self.decode(Int64.self, forKey: key).convert(to: I.self)
        case .anyInteger, .roundingAnyNumber:
            let document = self.decoder.document
            
            guard let type = document.typeIdentifier(of: key.stringValue) else {
                throw BSONValueNotFound(type: I.self, key: key.stringValue)
            }
            
            switch (type, strategy) {
            case (.int32, _):
                return try self.decode(Int32.self, forKey: key).convert(to: I.self)
            case (.int64, _):
                // Necessary also for custom integer types
                return try self.decode(Int64.self, forKey: key).convert(to: I.self)
            case (.double, .roundingAnyNumber):
                let double = try self.decode(Double.self, forKey: key)
                
                return I(double)
            default:
                throw BSONTypeConversionError(from: document[key.stringValue], to: I.self)
            }
        case .custom(let strategy):
            guard let value: I = try strategy(self.decoder.document, key.stringValue) else {
                throw BSONValueNotFound(type: I.self, key: key.stringValue)
            }
            
            return value
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let document: Document
        
        if let found = self.decoder.document[key.stringValue, as: Document.self] {
            document = found
        } else {
            guard self.decoder.settings.permitMissingSubDocuments else {
                throw BSONValueNotFound(type: Document.self, key: key.stringValue)
            }
            
            document = Document()
        }
        
        let decoder = _BSONDecoder(document: document, settings: self.decoder.settings)
        
        return KeyedDecodingContainer(KeyedBSONContainer<NestedKey>(for: decoder))
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        <#code#>
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        return decoder
    }
}

extension FixedWidthInteger {
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
            
            return numericCast(self)
        }
    }
}
