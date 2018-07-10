import Foundation
import NIO

extension Document {
    public func makeData() -> Data {
        return makeByteBuffer().withUnsafeReadableBytes(Data.init)
    }
    
    public func makeByteBuffer() -> ByteBuffer {
        var buffer = self.storage
        buffer.moveReaderIndex(to: 0)
        buffer.moveWriterIndex(to: Int(self.usedCapacity))
        return buffer
    }
}
