extension Document {
    public var isValid: Bool {
        return validate(recursively: true)
    }
    
    public func validate(recursively: Bool) -> Bool {
        let count = self.storage.count
        var offset = 0
        
        guard count >= 4, var pointer = self.storage.readBuffer.baseAddress else {
            return false
        }
        
        func advance(_ n: Int) {
            pointer += n
            offset = offset &+ n
        }
        
        func has(_ n: Int) -> Bool {
            return offset &+ n < count
        }
        
        guard numericCast(pointer.int32) == count else {
            return false
        }
        
        advance(4)
        
        // Iterate over key-value pairs.
        // Key is null terminated
        while offset < count {
            let type = pointer.pointee
            
            advance(1)
            var cStringLength = 0
            
            cStringLoop: while offset < count {
                defer { cStringLength = cStringLength &+ 1 }
                
                if pointer[cStringLength] == 0x00 {
                    // End of cString
                    break cStringLoop
                }
            }
            
            advance(cStringLength)
            
            switch type {
            case .double:
                advance(8)
            case .string:
                guard has(4) else { return false }
                
                advance(numericCast(4 &+ pointer.int32))
            case .document, .array:
                guard has(4) else { return false }
                
                if recursively {
                    let length = numericCast(pointer.int32) as Int
                    
                    guard has(length) else { return false }
                    
                    let document = Document(storage: self.storage[offset ..< offset &+ length])
                    
                    guard document.validate(recursively: true) else {
                        return false
                    }
                } else {
                    advance(numericCast(pointer.int32))
                }
            case .objectId:
                advance(12)
            default:
                return false
            }
            
            guard offset < count else {
                // Scrolled past the end
                return false
            }
        }
        
        return true
    }
}
