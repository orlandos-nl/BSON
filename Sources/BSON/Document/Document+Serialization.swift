import Foundation

extension Document {
    public mutating func withUnsafeBufferPointer<T>(_ run: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        if !nullTerminated {
            self.storage.append(0x00)
            self.nullTerminated = true
        }
        
        var length = Int32(self.storage.usedCapacity)
        withUnsafePointer(to: &length) { pointer in
            pointer.withMemoryRebound(to: UInt8.self, capacity: 4) { pointer in
                self.storage.replace(offset: 0, replacing: 4, with: pointer, length: 4)
            }
        }
        
        return try run(self.storage.readBuffer)
    }
    
    public mutating func makeData() -> Data {
        return self.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
    }
}
