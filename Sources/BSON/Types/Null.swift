/// The BSON Null type
public struct Null: Primitive {
    /// Creates a new `Null`
    public init() {}
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if var container = container as? AnySingleValueBSONEncodingContainer {
            try container.encode(primitive: self)
        } else {
            try container.encodeNil()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONDecodingContainer {
            self = try container.decodeNull()
        } else {
            guard container.decodeNil() else {
                throw BSONValueNotFound(type: Null.self, path: container.codingPath.map { $0.stringValue })
            }
        }
    }
}
