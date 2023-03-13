import NIOCore

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
    
    func getBSONString(at offset: Int) -> String? {
        guard let length = getInteger(at: offset, endianness: .little, as: Int32.self) else {
            return nil
        }
        
        // Omit the null terminator as we don't use/need that in Swift
        return getString(at: offset &+ 4, length: numericCast(length) - 1)
    }
    
    func getBSONBinary(at offset: Int) -> Binary? {
        guard let length = getInteger(at: offset, endianness: .little, as: Int32.self) else {
            return nil
        }
        
        guard
            let subType = getByte(at: offset &+ 4),
            let slice = getSlice(at: offset &+ 5, length: numericCast(length))
        else {
            return nil
        }
        
        return Binary(subType: Binary.SubType(subType), buffer: slice)
    }
    
    func getByte(at offset: Int) -> UInt8? {
        return self.getInteger(at: offset, endianness: .little, as: UInt8.self)
    }
    
    /// Returns the first index at which `byte` appears, starting from the reader position
    func firstRelativeIndexOf(matchingByte match: UInt8 = 0x00, startingAt: Int) -> Int? {
        withUnsafeReadableBytes { buffer -> Int? in
            var i = startingAt
            let count = buffer.count
            
            while i < count {
                if buffer[i] == match {
                    return i - startingAt
                }
                
                i += 1
            }
            
            return nil
        }
    }
}
