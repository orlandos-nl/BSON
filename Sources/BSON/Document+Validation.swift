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
        
        @discardableResult
        func cString() -> Int {
            var cStringLength = 0
            
            cStringLoop: while offset < count {
                defer { cStringLength = cStringLength &+ 1 }
                
                if pointer[cStringLength] == 0x00 {
                    // End of cString
                    break cStringLoop
                }
            }
        }
        
        func document() -> Bool {
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
            
            return true
        }
        
        func string() -> Bool {
            guard has(4) else { return false }
            
            // int32 contains the entire length, including null terminator
            advance(numericCast(4 &+ pointer.int32))
            
            return true
        }
        
        guard numericCast(pointer.int32) == count else {
            return false
        }
        
        advance(4)
        
        // Iterate over key-value pairs.
        // Key is null terminated
        nextPair: while offset < count {
            // Type
            let type = pointer.pointee
            advance(1)
            
            // Key
            advance(cString())
            
            // Value
            switch type {
            case .double:
                advance(8)
            case .string:
                guard string() else { return false }
            case .document, .array:
                guard document() else { return false }
            case .binary:
                guard has(4) else { return false }
                
                // int32 + subtype + bytes
                advance(numericCast(5 &+ pointer.int32))
            case .objectId:
                advance(12)
            case .boolean:
                advance(1)
            case .datetime, .timestamp, .int64:
                advance(8)
            case .null, .minKey, .maxKey:
                // no data
                // Still need to check the key's size
                break
            case .regex:
                advance(cString())
                advance(cString())
            case .javascript:
                guard string() else { return false }
            case .javascriptWithScope:
                guard string() else { return false }
                guard document() else { return false }
            case .int32:
                advance(4)
            case .decimal128:
                advance(16)
            default:
                return false
            }
            
            // Check parsed data size
            guard offset < count else {
                // Scrolled past the end
                return false
            }
        }
        
        return true
    }
}
