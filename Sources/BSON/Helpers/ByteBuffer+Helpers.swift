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
            let byte0 = getByte(at: offset),
            let byte1 = getByte(at: offset + 1),
            let byte2 = getByte(at: offset + 2),
            let byte3 = getByte(at: offset + 3),
            let byte4 = getByte(at: offset + 4),
            let byte5 = getByte(at: offset + 5),
            let byte6 = getByte(at: offset + 6),
            let byte7 = getByte(at: offset + 7),
            let byte8 = getByte(at: offset + 8),
            let byte9 = getByte(at: offset + 9),
            let byte10 = getByte(at: offset + 10),
            let byte11 = getByte(at: offset + 11)
        else {
            return nil
        }

        return ObjectId(byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8, byte9, byte10, byte11)
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
