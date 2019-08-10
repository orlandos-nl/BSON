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
    func firstRelativeIndexOf(byte: UInt8, startingAt: Int) -> Int? {
        var i = 0
        while let candidate = self.getInteger(at: startingAt + i, endianness: .little, as: UInt8.self) {
            if candidate == byte {
                return i
            } else {
                i += 1
            }
        }
        
        return nil
    }
}
