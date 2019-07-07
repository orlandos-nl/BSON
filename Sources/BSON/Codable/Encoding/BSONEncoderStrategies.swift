/// A configuration structs that contains all strategies for encoding BSON values
public struct BSONEncoderStrategies { // TODO: EncoderStrategies or EncodingStrategies? Also for Extended JSON
    
    /// Defines how optionals that are `nil` are encoded in keyed containers
    ///
    /// Note that for unkeyed containers, like arrays, `nil` is always encoded as `null`
    public enum KeyedNilEncodingStrategy {
        /// A value of `nil` is encoded as BSON `Null`
        case null
        
        /// A value of `nil` is not encoded at all
        case omitted
    }
    
    /// Defines how unsigned integers are encoded
    public enum UnsignedIntegerEncodingStrategy {
        /// Unsigned integers are encoded as Int64. If the value is too large to fit in an int64, an error will be thrown.
        case int64
        
        /// Unsinged integers are encoded as strings
        case string
    }
    
    public static var `default`: BSONEncoderStrategies {
        return .init()
    }
    
    /// Defines how optionals that are `nil` are encoded in keyed containers
    public var keyedNilEncodingStrategy: KeyedNilEncodingStrategy = .omitted
    
    /// Defines how unsigned integers are encoded
    public var unsignedIntegerEncodingStrategy: UnsignedIntegerEncodingStrategy = .int64
    
    public var filterDollarPrefix = false
}
