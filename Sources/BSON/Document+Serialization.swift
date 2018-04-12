import Foundation

extension Document {
    func serializeData() -> Data {
        self.storage.writeBuffer?.baseAddress?.withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
            if self.nullTerminated {
                pointer.pointee = Int32(self.storage.readBuffer.count)
            } else {
                pointer.pointee = Int32(self.storage.readBuffer.count &+ 1)
            }
        }
        
        if self.nullTerminated {
            return Data(buffer: self.storage.readBuffer)
        } else {
            return Data(buffer: self.storage.readBuffer) + [0]
        }
    }
}
