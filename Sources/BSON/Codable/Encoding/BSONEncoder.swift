import Foundation

/// An object that encodes instances of `Encodable` types as BSON Documents.
public class BSONEncoder {
    
    // MARK: - Encoding
    
    /// Creates a new, reusable encoder with the given strategies
    public init(strategies: BSONEncoderStrategies = .default) {
        self.strategies = strategies
    }
    
    /// Returns the BSON-encoded representation of the value you supply
    ///
    /// If there's a problem encoding the value you supply, this method throws an error based on the type of problem:
    ///
    /// - The value fails to encode, or contains a nested value that fails to encode—this method throws the corresponding error.
    /// - The value can't be encoded as a BSON array or BSON object—this method throws the invalidValue error.
    public func encode<T : Encodable>(_ value: T) throws -> Document {
        unimplemented()
    }
    
    // MARK: - Configuration
    
    /// Configures the behavior of the BSON Encoder. See the documentation on `BSONEncoderStrategies` for details.
    public var strategies: BSONEncoderStrategies
    
}
