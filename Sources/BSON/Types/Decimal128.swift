import NIO

/// A BSON Decimal128 value
///
/// OpenKitten BSON currently does not support the handling of Decimal128 values. The type is a stub and provides no API. It serves as a point for future implementation.
public struct Decimal128: Primitive {
    var storage: ByteBuffer
    
    internal init(_ storage: ByteBuffer) {
        Swift.assert(storage.readableBytes == 16)
        
        self.storage = storage
    }
    
    public func encode(to encoder: Encoder) throws {
        unimplemented()
    }
    
    public init(from decoder: Decoder) throws {
        unimplemented()
    }
}
