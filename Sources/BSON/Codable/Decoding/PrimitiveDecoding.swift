// Helpers to decode a `Primitive` (without knowing the concrete type)

extension KeyedBSONDecodingContainer: Decodable {
    init(from decoder: Decoder) throws {
        throw DecodingError.typeMismatch(KeyedBSONDecodingContainer<Key>.self, .init(codingPath: decoder.codingPath, debugDescription: "Decoding a primitive is only possible from a BSONDecoder"))
    }
}

extension KeyedDecodingContainer {
    public func decode(_ type: Primitive.Protocol, forKey key: Key) throws -> Primitive {
        let container = try self.decode(KeyedBSONDecodingContainer<Key>.self, forKey: key)
        return try container.decode(Primitive.self, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Primitive.Protocol, forKey key: Key) throws -> Primitive? {
        let container = try self.decode(KeyedBSONDecodingContainer<Key>.self, forKey: key)
        return try container.decodeIfPresent(Primitive.self, forKey: key)
    }
}
