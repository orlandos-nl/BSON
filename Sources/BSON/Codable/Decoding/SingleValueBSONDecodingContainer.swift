internal struct SingleValueBSONDecodingContainer: SingleValueDecodingContainer, AnySingleValueBSONDecodingContainer {
    var codingPath: [CodingKey]
    
    let decoder: _BSONDecoder
    
    init(for decoder: _BSONDecoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.decoder = decoder
    }
    
    func decodeDocument() throws -> Document {
        guard let doc = self.decoder.document else {
            throw BSONValueNotFound(type: Document.self, path: self.codingPath.path)
        }
        
        return doc
    }
    
    func decodeBinary() throws -> Binary {
        guard let binary = self.decoder.primitive as? Binary else {
            throw BSONValueNotFound(type: Binary.self, path: self.codingPath.path)
        }
        
        return binary
    }
    
    func decodeDecimal128() throws -> Decimal128 {
        guard let decimal128 = self.decoder.primitive as? Decimal128 else {
            throw BSONValueNotFound(type: Decimal128.self, path: self.codingPath.path)
        }
        
        return decimal128
    }
    
    func decodeObjectId() throws -> ObjectId {
        guard let objectId = self.decoder.primitive as? ObjectId else {
            throw BSONValueNotFound(type: ObjectId.self, path: self.codingPath.path)
        }
        
        return objectId
    }
    
    func decodeRegularExpression() throws -> RegularExpression {
        guard let regex = self.decoder.primitive as? RegularExpression else {
            throw BSONValueNotFound(type: RegularExpression.self, path: self.codingPath.path)
        }
        
        return regex
    }
    
    func decodeNull() throws -> Null {
        guard let null = self.decoder.primitive as? Null else {
            throw BSONValueNotFound(type: Null.self, path: self.codingPath.path)
        }
        
        return null
    }
    
    func decodeNil() -> Bool {
        if let primitive = self.decoder.primitive, !(primitive is Null) {
            return false
        }
        
        return true
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try self.decoder.wrapped.unwrap(asType: Bool.self, path: self.codingPath.path)
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try self.decoder.settings.stringDecodingStrategy.decode(from: decoder, path: self.codingPath.path)
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
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if let type = T.self as? BSONDataType.Type {
            return try type.init(primitive: self.decoder.primitive) as! T
        } else {
            let decoder = _BSONDecoder(wrapped: self.decoder.wrapped, settings: self.decoder.settings, codingPath: self.codingPath, userInfo: self.decoder.userInfo)
            return try T.init(from: decoder)
        }
    }
}
