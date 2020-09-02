import NIO

extension ByteBuffer {
    func getDouble(at offset: Int) -> Double? {
        guard let int = getInteger(at: offset, endianness: .little, as: UInt64.self) else {
            return nil
        }
        
        return Double(bitPattern: int)
    }

    func getObjectId(at offset: Int) -> ObjectId? {
        guard 
            let timestamp = getInteger(at: offset + 0, endianness: .big, as: UInt32.self),
            let random = getInteger(at: offset + 4, endianness: .big, as: UInt64.self)
        else {
            return nil
        }

        return ObjectId(timestamp: timestamp, random: random)
    }
    
    func getByte(at offset: Int) -> UInt8? {
        return self.getInteger(at: offset, endianness: .little, as: UInt8.self)
    }
    
    /// Returns the first index at which `byte` appears, starting from the reader position
    func firstRelativeIndexOf(startingAt: Int) -> Int? {
        withUnsafeReadableBytes { buffer -> Int? in
            var i = startingAt
            let count = buffer.count
            
            while i < count {
                if buffer[i] == 0 {
                    return i - startingAt
                }
                
                i += 1
            }
            
            return nil
        }
    }
}
