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
    public typealias DecodingStrategy<P> = (Primitive?) throws -> P?
    
    public enum FloatDecodingStrategy {
        case string
        case double
        case custom(DecodingStrategy<Float>)
    }
    
    public enum IntegerDecodingStrategy<I: FixedWidthInteger> {
        case string
        case int32
        case int64
        case anyInteger
        case roundingAnyNumber
        case stringOrNumber
        case custom(DecodingStrategy<I>)
    }
    
    
    public enum DoubleDecodingStrategy {
        case double
        case numerical
        case textual
        case numericAndTextual
        
        case custom(DecodingStrategy<Double>)
    }
    
    public var decodeNullAsNil: Bool = true
    public var lossyDecodeIntoString: Bool = false
    public var decodeObjectIdFromString: Bool = false
    
    public var floatDecodingStrategy: FloatDecodingStrategy = .double
    public var doubleDecodingStrategy: DoubleDecodingStrategy = .double
    
    public var int8DecodingStrategy: IntegerDecodingStrategy<Int8> = .anyInteger
    public var int16DecodingStrategy: IntegerDecodingStrategy<Int16> = .anyInteger
    public var int32DecodingStrategy: IntegerDecodingStrategy<Int32> = .int32
    public var int64DecodingStrategy: IntegerDecodingStrategy<Int64> = .int64
    public var intDecodingStrategy: IntegerDecodingStrategy<Int> = .anyInteger
    public var uint8DecodingStrategy: IntegerDecodingStrategy<UInt8> = .anyInteger
    public var uint16DecodingStrategy: IntegerDecodingStrategy<UInt16> = .anyInteger
    public var uint32DecodingStrategy: IntegerDecodingStrategy<UInt32> = .anyInteger
    public var uint64DecodingStrategy: IntegerDecodingStrategy<UInt64> = .anyInteger
    public var uintDecodingStrategy: IntegerDecodingStrategy<UInt> = .anyInteger
}
