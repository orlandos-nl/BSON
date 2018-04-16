/// A configuration structs that contains all strategies for encoding BSON values
public struct BSONEncoderStrategies {
    
    /// Defines how optionals that are `nil` are encoded in keyed containers
    ///
    /// Note that for unkeyed containers, like arrays, `nil` is always encoded as `null`
    enum KeyedNilEncodingStrategy {
        /// A value of `nil` is encoded as BSON `Null`
        case null
        
        /// A value of `nil` is not encoded – the key is
        case noValue
    }
    
    /// Defines how unsigned integers are encoded
    enum UnsignedIntegerEncodingStrategy {
        /// Unsigned integers are encoded as Int64. If the value is too large to fit in an int64, an error will be thrown.
        case int64
        
        /// Unsinged integers are encoded as strings
        case string
    }
    
    public static var `default`: BSONEncoderStrategies {
        return .init()
    }
    
    /// Defines how optionals that are `nil` are encoded in keyed containers
    var keyedNilEncodingStrategy: KeyedNilEncodingStrategy = .noValue
    
    /// Defines how unsigned integers are encoded
    var unsignedIntegerEncodingStrategy: UnsignedIntegerEncodingStrategy = .int64
    
}
