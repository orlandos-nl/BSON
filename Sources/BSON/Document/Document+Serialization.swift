import Foundation

extension Document {
    public mutating func withUnsafeBufferPointer<T>(_ run: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        if !nullTerminated {
            self.storage.append(0x00)
            self.nullTerminated = true
        }
        
        return try run(self.storage.readBuffer)
    }
    
    public mutating func makeData() -> Data {
        return self.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
    }
}
