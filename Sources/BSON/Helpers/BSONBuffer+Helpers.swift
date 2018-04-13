extension BSONBuffer {
    /// Scans a cString at the given offset, returns the length of the cString
    func cString(at offset: Int) -> Int {
        var cStringLength = 0
        let pointer = readBuffer.baseAddress! + offset
        
        cStringLoop: while offset < self.usedCapacity {
            defer { cStringLength = cStringLength &+ 1 }
            
            if pointer[cStringLength] == 0x00 {
                // End of cString
                break cStringLoop
            }
        }
        
        return cStringLength
    }
}
