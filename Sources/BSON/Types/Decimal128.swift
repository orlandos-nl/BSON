import NIOCore

/// A BSON Decimal128 value
///
/// OpenKitten BSON currently does not support the handling of Decimal128 values. The type is a stub and provides no API. It serves as a point for future implementation.
public struct Decimal128: Primitive, Hashable {
    private static let exponentBitCount: UInt64 = 14
    private static let exponentBitMask: Int = 0b1111_1111_1111_11
    private static let significandBitCount: UInt64 = 110
    private static let nanBits = 0b11111
    private static let infinityBits = 0b11110
    
    public var isNegative: Bool {
        high >> 58 == 1
    }
    
    public var isInfinity: Bool {
        high >> 58 & 0b011111 == Self.infinityBits
    }
    
    public var isNaN: Bool {
        high >> 58 & 0b011111 == Self.nanBits
    }
    
    let low: UInt64
    let high: UInt64
    
    internal init(low: UInt64, high: UInt64) {
        self.low = low
        self.high = high
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
