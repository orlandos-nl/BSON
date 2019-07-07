/// A configuration structs that contains all strategies for (lossy) decoding values
public struct BSONDecoderSettings {
    /// Decodes values only if they are exactly matching the expectation.
    ///
    /// For non-BSON types, the following mapping applies:
    ///
    /// - Float: Decode from Double
    /// - Non-native Integer types: .anyInteger
    public static var strict: BSONDecoderSettings {
        return .init(
            decodeNullAsNil: false,
            filterDollarPrefix: false,
            stringDecodingStrategy: .string,
            decodeObjectIdFromString: false,
            floatDecodingStrategy: .double,
            doubleDecodingStrategy: .double,
            int8DecodingStrategy: .anyInteger,
            int16DecodingStrategy: .anyInteger,
            int32DecodingStrategy: .int32,
            int64DecodingStrategy: .int64,
            intDecodingStrategy: .anyInteger,
            uint8DecodingStrategy: .anyInteger,
            uint16DecodingStrategy: .anyInteger,
            uint32DecodingStrategy: .anyInteger,
            uint64DecodingStrategy: .anyInteger,
            uintDecodingStrategy: .anyInteger
        )
    }
    
    /// Tries to decode values, even if the types do not match. Some precision loss is possible.
    public static var adaptive: BSONDecoderSettings {
        return .init(
            decodeNullAsNil: true,
            filterDollarPrefix: false,
            stringDecodingStrategy: .adaptive,
            decodeObjectIdFromString: true,
            floatDecodingStrategy: .adaptive,
            doubleDecodingStrategy: .adaptive,
            int8DecodingStrategy: .adaptive,
            int16DecodingStrategy: .adaptive,
            int32DecodingStrategy: .adaptive,
            int64DecodingStrategy: .adaptive,
            intDecodingStrategy: .adaptive,
            uint8DecodingStrategy: .adaptive,
            uint16DecodingStrategy: .adaptive,
            uint32DecodingStrategy: .adaptive,
            uint64DecodingStrategy: .adaptive,
            uintDecodingStrategy: .adaptive
        )
    }
    
    /// A strategy used to decode `P` from a BSON `Primitive?` value
    ///
    /// If the key (`String`) is nil the value was not associated with a Dictionary Document.
    ///
    /// If the value (`Primitive`) is nil, the value was not found at all but can be overwritten with a default
    public typealias DecodingStrategy<P> = (String?, Primitive?) throws -> P?
    
    /// A strategy used to decode float values
    /// Floats are not a native BSON type
    ///
    /// WARNING: This API may have cases added to it, do *not* manually switch over them
    public enum FloatDecodingStrategy {
        case string
        case double
        case adaptive
        case custom(DecodingStrategy<Float>)
    }
    
    /// A strategy used to decode float values
    /// Floats are not a native BSON type
    ///
    /// WARNING: This API may have cases added to it, do *not* manually switch over them
    public enum IntegerDecodingStrategy<I: FixedWidthInteger> {
        /// Decodes this integer type only from Strings
        case string
        
        /// Decodes this integer type only from BSON Int32
        case int32
        
        /// Decodes this integer type only from BSON Int64
        case int64
        
        /// Decodes this integer from either BSON Int32 or Int64
        case anyInteger
        
        /// Decodes this integer from any number (Int32, Int64 or Double), rouding Doubles
        case roundingAnyNumber
        
        /// Decodes this integer from either a String or a number (rounding Doubles)
        case adaptive
        
        /// Applies a custom decoding strategy
        case custom(DecodingStrategy<I>)
    }
    
    /// A strategy used to decode double values
    /// Although Doubles are a native BSON type, lossy conversion may be favourable in certain circumstances
    ///
    /// WARNING: This API may have cases added to it, do *not* manually switch over them
    public enum DoubleDecodingStrategy {
        /// Decodes only the correct type. No lossy decoding.
        case double
        
        /// Decodes from any numerical type, meaning `Int32` and `Int64` will be converted
        ///
        /// Some data loss may occur for Int64
        case numerical
        
        /// Allows lossy decoding from `String` as well as `Double`
        ///
        /// If the String is formatted as a Double as permitted by the currently used Swift standard library
        case textual
        
        /// Allows both lossy conversions from both numerical and strings in addition to the regular `Double`.
        case adaptive
        
        /// Used for specifying a custom decoding strategy
        ///
        /// This may be used for applying fallback values or other custom behaviour
        case custom(DecodingStrategy<Double>)
    }
    
    /// A strategy used to influence decoding Strings
    ///
    /// WARNING: This API may have cases added to it, do *not* manually switch over them
    public enum StringDecodingStrategy {
        /// Decode only strings themselves
        case string
        
        /// Decode strings from integers' textual representations
        case integers
        
        /// Decode strings from any numerical's textual representations
        case numerical
        
        /// Try to decode from any type
        ///
        /// - ObjectId.hexString
        /// - Int32.desciption
        /// - Int64.description
        /// - Bool ? "true" : "false"
        case adaptive
        
        /// Used for specifying a custom decoding strategy
        ///
        /// This may be used for applying fallback values or other custom behaviour
        case custom(DecodingStrategy<String>)
    }
    
    /// If `true`, BSON Null values will be regarded as `nil`
    public var decodeNullAsNil: Bool = true
    public var filterDollarPrefix = false
    
    /// A strategy that is applied when encountering a request to decode a `String`
    public var stringDecodingStrategy: StringDecodingStrategy
    
    /// If `true`, allows decoding ObjectIds from Strings if they're formatted as a 24-character hexString
    public var decodeObjectIdFromString: Bool = false
    
    /// A strategy that is applied when encountering a request to decode a `Float`
    public var floatDecodingStrategy: FloatDecodingStrategy
    
    /// A strategy that is applied when encountering a request to decode a `Double`
    public var doubleDecodingStrategy: DoubleDecodingStrategy
    
    /// A strategy that is applied when encountering a request to decode a `Int8`
    public var int8DecodingStrategy: IntegerDecodingStrategy<Int8>
    
    /// A strategy that is applied when encountering a request to decode a `Int16`
    public var int16DecodingStrategy: IntegerDecodingStrategy<Int16>
    
    /// A strategy that is applied when encountering a request to decode a `Int32`
    public var int32DecodingStrategy: IntegerDecodingStrategy<Int32>
    
    /// A strategy that is applied when encountering a request to decode a `Int64`
    public var int64DecodingStrategy: IntegerDecodingStrategy<Int64>
    
    /// A strategy that is applied when encountering a request to decode a `Int`
    public var intDecodingStrategy: IntegerDecodingStrategy<Int>
    
    /// A strategy that is applied when encountering a request to decode a `UInt8`
    public var uint8DecodingStrategy: IntegerDecodingStrategy<UInt8>
    
    /// A strategy that is applied when encountering a request to decode a `UInt16`
    public var uint16DecodingStrategy: IntegerDecodingStrategy<UInt16>
    
    /// A strategy that is applied when encountering a request to decode a `UInt32`
    public var uint32DecodingStrategy: IntegerDecodingStrategy<UInt32>
    
    /// A strategy that is applied when encountering a request to decode a `UInt64`
    public var uint64DecodingStrategy: IntegerDecodingStrategy<UInt64>
    
    /// A strategy that is applied when encountering a request to decode a `UInt`
    public var uintDecodingStrategy: IntegerDecodingStrategy<UInt>
}
