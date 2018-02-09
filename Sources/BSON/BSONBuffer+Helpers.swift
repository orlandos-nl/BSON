extension Storage {
    func cString(at offset: Int) -> Int {
        var cStringLength = 0
        let pointer = readBuffer.baseAddress! + offset
        
        cStringLoop: while offset < count {
            defer { cStringLength = cStringLength &+ 1 }
            
            if pointer[cStringLength] == 0x00 {
                // End of cString
                break cStringLoop
            }
        }
        
        return cStringLength
    }
}
