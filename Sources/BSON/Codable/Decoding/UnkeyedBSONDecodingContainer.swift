internal struct UnkeyedBSONDecodingContainer: UnkeyedDecodingContainer {
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
    
    var iterator: DocumentPairIterator
    
    mutating func nextElement() throws -> DecoderValue {
        guard let pair = iterator.next() else {
            throw EndOfBSONDocument()
        }
        
        return .primitive(pair.value)
    }
    
    init(decoder: _BSONDecoder, codingPath: [CodingKey]) throws {
        guard let document = decoder.document else {
            throw DecodingError.valueNotFound(Document.self, .init(codingPath: codingPath, debugDescription: "An unkeyed container could not be made because the value is not a document"))
        }
        
        self.decoder = decoder
        self.codingPath = codingPath
        self.iterator = document.pairs
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
        return try self.decoder.settings.stringDecodingStrategy.decode(from: decoder, path: self.codingPath.path)
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
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.nextElement().primitive) as! T
        } else {
            let decoder = try _BSONDecoder(wrapped: self.nextElement(), settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
            return try T.init(from: decoder)
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
