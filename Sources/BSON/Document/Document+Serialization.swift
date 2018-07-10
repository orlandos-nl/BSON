import Foundation
import NIO

extension Document {
    public func makeData() -> Data {
        return makeByteBuffer().withUnsafeReadableBytes(Data.init)
    }
    
    public func makeByteBuffer() -> ByteBuffer {
        var buffer = self.storage
        buffer.moveReaderIndex(to: 0)
        buffer.moveWriterIndex(to: Swift.min(Int(self.usedCapacity), buffer.capacity)) // directly using usedCapacity instead of `min` may trigger a precondition with invalid documents
        return buffer
    }
}
