import Foundation
import NIO

extension Document {
    /// Updates the document header, containing the length of the document
    internal mutating func writeHeader() {
        var length = Int32(self.storage.usedCapacity) + 1
        
        withUnsafePointer(to: &length) { pointer in
            pointer.withMemoryRebound(to: UInt8.self, capacity: 4) { pointer in
                self.storage.replace(offset: 0, replacing: 4, with: pointer, length: 4)
            }
        }
    }
    
    public mutating func withUnsafeBufferPointer<T>(_ run: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        writeHeader()
        
        return try run(self.storage.readBuffer)
    }
    
    // TODO: This should not be a mutating func
    public mutating func makeData() -> Data {
        return self.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer) + [0] // TODO: Something more performant
        }
    }
    
    public func makeByteBuffer() -> ByteBuffer {
        var buffer = self.storage
        buffer.moveReaderIndex(to: 0)
        buffer.moveWriterIndex(to: Int(self.usedCapacity))
        return buffer
    }
}
