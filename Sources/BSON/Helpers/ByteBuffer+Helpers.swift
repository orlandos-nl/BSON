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
            let byte1 = getByte(at: offset),
            let byte2 = getByte(at: offset),
            let byte3 = getByte(at: offset),
            let byte4 = getByte(at: offset),
            let byte5 = getByte(at: offset),
            let byte6 = getByte(at: offset),
            let byte7 = getByte(at: offset),
            let byte8 = getByte(at: offset),
            let byte9 = getByte(at: offset),
            let byte10 = getByte(at: offset),
            let byte11 = getByte(at: offset)
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
