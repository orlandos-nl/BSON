import Foundation
import NIOCore

extension Document {
    /// Returns a `Data` representation of this `Document`. This is a copy of the underlying `ByteBuffer`'s data.
    public func makeData() -> Data {
        return makeByteBuffer().withUnsafeReadableBytes { Data($0) }
    }
    
    /// Returns a `ByteBuffer` representation of this `Document`. This is a copy of the underlying `ByteBuffer`.
    public func makeByteBuffer() -> ByteBuffer {
        return storage
    }
}
