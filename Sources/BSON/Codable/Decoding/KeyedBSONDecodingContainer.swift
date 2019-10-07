internal struct KeyedBSONDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
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
    
    init(for decoder: _BSONDecoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.decoder = decoder
    }
    
    func path(forKey key: K) -> [String] {
        return self.codingPath.map { decoder.converted($0.stringValue) } + [decoder.converted(key.stringValue)]
    }
    
    func contains(_ key: K) -> Bool {
        if let value = self.document[decoder.converted(key.stringValue)], !(value is Null) {
            return true
        } else {
            return false
        }
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return !self.contains(key)
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try self.document.assertPrimitive(typeOf: type, forKey: decoder.converted(key.stringValue))
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try self.decoder.settings.stringDecodingStrategy.decode(from: decoder, forKey: key, path: path(forKey: key))
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try self.decoder.settings.doubleDecodingStrategy.decode(
            from: decoder,
            forKey: key,
            path: path(forKey: key)
        )
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try self.decoder.settings.floatDecodingStrategy.decode(
            stringKey: decoder.converted(key.stringValue),
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
    
    func decode(_ type: Primitive.Protocol, forKey key: K) throws -> Primitive {
        guard let value = self.document[decoder.converted(key.stringValue)] else {
            throw BSONValueNotFound(type: Primitive.self, path: path(forKey: key))
        }
        
        return value
    }
    
    func decodeIfPresent(_ type: Primitive.Protocol, forKey key: K) throws -> Primitive? {
        return self.document[decoder.converted(key.stringValue)]
    }
    
    func decode<T>(_ type: T.Type, forKey codingKey: K) throws -> T where T: Decodable {
        let key = decoder.converted(codingKey.stringValue)
        if let instance = self as? T {
            return instance
        } else if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.document[key]) as! T
        } else {
            let value = self.document[key]
            
            // Decoding strategy for Primitives, like Date
            if let value = value as? T {
                return value
            }
            
            let decoderValue: DecoderValue
            if let document = value as? Document {
                decoderValue = .document(document)
            } else {
                decoderValue = .primitive(value)
            }
            
            let decoder = _BSONDecoder(
                wrapped: decoderValue,
                settings: self.decoder.settings,
                codingPath: self.codingPath + [codingKey],
                userInfo: self.decoder.userInfo
            )
            
            return try T.init(from: decoder)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        let document = self.document[decoder.converted(key.stringValue), as: Document.self] ?? Document()
        
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
        
        return KeyedDecodingContainer(KeyedBSONDecodingContainer<NestedKey>(for: decoder, codingPath: self.codingPath + [key]))
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        let document = try self.decode(Document.self, forKey: key)
        let decoder = _BSONDecoder(wrapped: .document(document), settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
        return try UnkeyedBSONDecodingContainer(decoder: decoder, codingPath: self.codingPath + [key])
    }
    
    func superDecoder() throws -> Decoder {
        // TODO: Use `super` key
        return decoder
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        // TODO: Respect given key
        return decoder
    }
}
