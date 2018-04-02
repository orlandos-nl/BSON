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
    public var decodeNullAsNil: Bool = true
    public var allowMissingSubDocument: Bool = true
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
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try self.decoder.document.assertPrimitive(Int8.self, forKey: key.stringValue)
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try self.decoder.document.assertPrimitive(Int16.self, forKey: key.stringValue)
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        
        return try self.decoder.document.assertPrimitive(type, forKey: key.stringValue)
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        <#code#>
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        <#code#>
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        <#code#>
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let document: Document
        
        if let found = self.decoder.document[key.stringValue, as: Document.self] {
            document = found
        } else {
            guard self.decoder.settings.allowMissingSubDocument else {
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
