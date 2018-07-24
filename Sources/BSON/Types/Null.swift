/// The BSON Null type
public struct Null: Primitive {
    /// Creates a new `Null`
    public init() {}
    
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
