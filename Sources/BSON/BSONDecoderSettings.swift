/// A configuration structs that contains all strategies for (lossy) decoding values
public struct BSONDecoderSettings {
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
        case stringOrNumber
        
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
        case numericAndTextual
        
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
        case all
        
        /// Used for specifying a custom decoding strategy
        ///
        /// This may be used for applying fallback values or other custom behaviour
        case custom(DecodingStrategy<String>)
    }
    
    /// If `true`, BSON Null values will be regarded as `nil`
    public var decodeNullAsNil: Bool = true
    
    /// A strategy that is applied when encountering a request to decode a `String`
    public var stringDecodingStrategy: StringDecodingStrategy = .string
    
    /// If `true`, allows decoding ObjectIds from Strings if they're formatted as a 24-character hexString
    public var decodeObjectIdFromString: Bool = false
    
    /// A strategy that is applied when encountering a request to decode a `Float`
    public var floatDecodingStrategy: FloatDecodingStrategy = .double
    
    /// A strategy that is applied when encountering a request to decode a `Double`
    public var doubleDecodingStrategy: DoubleDecodingStrategy = .double
    
    /// A strategy that is applied when encountering a request to decode a `Int8`
    public var int8DecodingStrategy: IntegerDecodingStrategy<Int8> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `Int16`
    public var int16DecodingStrategy: IntegerDecodingStrategy<Int16> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `Int32`
    public var int32DecodingStrategy: IntegerDecodingStrategy<Int32> = .int32
    
    /// A strategy that is applied when encountering a request to decode a `Int64`
    public var int64DecodingStrategy: IntegerDecodingStrategy<Int64> = .int64
    
    /// A strategy that is applied when encountering a request to decode a `Int`
    public var intDecodingStrategy: IntegerDecodingStrategy<Int> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `UInt8`
    public var uint8DecodingStrategy: IntegerDecodingStrategy<UInt8> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `UInt16`
    public var uint16DecodingStrategy: IntegerDecodingStrategy<UInt16> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `UInt32`
    public var uint32DecodingStrategy: IntegerDecodingStrategy<UInt32> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `UInt64`
    public var uint64DecodingStrategy: IntegerDecodingStrategy<UInt64> = .anyInteger
    
    /// A strategy that is applied when encountering a request to decode a `UInt`
    public var uintDecodingStrategy: IntegerDecodingStrategy<UInt> = .anyInteger
}
