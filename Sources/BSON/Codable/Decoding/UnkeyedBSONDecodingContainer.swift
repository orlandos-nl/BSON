internal struct UnkeyedBSONDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    
    var count: Int? {
        return self.values.count
    }
    
    var isAtEnd: Bool { currentIndex >= values.count }
    
    var currentIndex: Int = 0
    let decoder: _BSONDecoder
    var values: [Primitive]
    
    mutating func nextElement() -> Primitive? {
        if isAtEnd {
            return nil
        }
        
        let value = values[currentIndex]
        currentIndex += 1
        return value
    }
    
    mutating func nextDecoder() throws -> _BSONDecoder {
        _BSONDecoder(
            wrapped: .primitive(nextElement()),
            settings: self.decoder.settings,
            codingPath: self.codingPath,
            userInfo: self.decoder.userInfo
        )
    }
    
    init(decoder: _BSONDecoder, codingPath: [CodingKey]) throws {
        guard let document = decoder.document else {
            throw DecodingError.valueNotFound(Document.self, .init(codingPath: codingPath, debugDescription: "An unkeyed container could not be made because the value is not a document"))
        }
        
        self.decoder = decoder
        self.codingPath = codingPath
        self.values = document.values
    }
    
    mutating func decodeNil() -> Bool {
        guard let value = nextElement() else {
            return false
        }
        
        if value is Null {
            return true
        }
        
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard let primitive = self.nextElement() else {
            throw EndOfBSONDocument()
        }
        return try primitive.unwrap(asType: Bool.self, path: self.codingPath.path)
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        return try self.decoder.settings.stringDecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        return try self.decoder.settings.doubleDecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        return try self.decoder.settings.floatDecodingStrategy.decode(from: self.nextDecoder().wrapped, path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        return try self.decoder.settings.intDecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.decoder.settings.int8DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.decoder.settings.int16DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.decoder.settings.int32DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.decoder.settings.int64DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try self.decoder.settings.uintDecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.decoder.settings.uint8DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.decoder.settings.uint16DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.decoder.settings.uint32DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.decoder.settings.uint64DecodingStrategy.decode(from: self.nextDecoder(), path: self.codingPath.path)
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.nextElement()) as! T
        } else {
            return try T.init(from: nextDecoder())
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        let document = try self.decode(Document.self)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
        return KeyedDecodingContainer(KeyedBSONDecodingContainer(for: decoder, codingPath: self.codingPath))
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let document = try self.decode(Document.self)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
        return try UnkeyedBSONDecodingContainer(decoder: decoder, codingPath: self.codingPath)
    }
    
    mutating func superDecoder() throws -> Decoder {
        return self.decoder
    }
}
