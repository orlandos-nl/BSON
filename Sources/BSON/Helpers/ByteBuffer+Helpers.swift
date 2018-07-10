import NIO

extension ByteBuffer {
    func getDouble(at offset: Int) -> Double? {
        guard let int = getInteger(at: offset, endianness: .little, as: UInt64.self) else {
            return nil
        }
        
        return Double(bitPattern: int)
    }
    
    func getByte(at offset: Int) -> UInt8? {
        return self.getInteger(at: offset, endianness: .little, as: UInt8.self)
    }
    
    /// Returns the first index at which `byte` appears, starting from the reader position
    func firstRelativeIndexOf(byte: UInt8) -> Int? {
        var buffer = self
        while let candidate = buffer.readInteger(endianness: .little, as: UInt8.self) {
            if candidate == byte {
                return buffer.readerIndex - self.readerIndex
            }
        }
        
        return nil
    }
}
