import Foundation
import NIOCore

extension Document {
    public func makeData() -> Data {
        return makeByteBuffer().withUnsafeReadableBytes { Data($0) }
    }
    
    public func makeByteBuffer() -> ByteBuffer {
        return storage
    }
}
