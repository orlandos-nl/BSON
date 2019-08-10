import NIO

/// A BSON Decimal128 value
///
/// OpenKitten BSON currently does not support the handling of Decimal128 values. The type is a stub and provides no API. It serves as a point for future implementation.
public struct Decimal128: Primitive, Hashable {
    var storage: [UInt8]
    
    internal init(_ storage: [UInt8]) {
        Swift.assert(storage.count == 16)
        
        self.storage = storage
    }
    
    public func encode(to encoder: Encoder) throws {
        let container = encoder.singleValueContainer()
        
        if var container = container as? AnySingleValueBSONEncodingContainer {
            try container.encode(primitive: self)
        } else {
            throw UnsupportedDecimal128()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONDecodingContainer {
            self = try container.decodeDecimal128()
        } else {
            throw UnsupportedDecimal128()
        }
    }
}

fileprivate struct UnsupportedDecimal128: Error {
    init() {}
    
    let message = "Decimal128 did not yet implement Codable using non-BSON encoders"
}
