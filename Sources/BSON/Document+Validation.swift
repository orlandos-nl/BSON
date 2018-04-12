extension Document {
    /// If `true`, this document is completely and recursively valid
    public var isValid: Bool {
        return validate()
    }
    
    /// Validates this document's technical correctness
    ///
    /// If `recursively` is `true` the subdocuments will be traversed, too
    public func validate(recursively: Bool = true) -> Bool {
        var offset = 0
        let count = self.storage.usedCapacity
        
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
        
        func document() -> Bool {
            guard has(4) else {
                return false
            }
            
            if recursively {
                let length = numericCast(pointer.int32) as Int
                
                guard has(length) else { return false }
                
                let document = Document(storage: self.storage[offset ..< offset &+ length &- 1], nullTerminated: false)
                
                guard document.validate(recursively: true) else {
                    return false
                }
            } else {
                advance(numericCast(pointer.int32))
            }
            
            return true
        }
        
        func string() -> Bool {
            guard has(4) else {
                return false
            }
            
            let stringLength = pointer.int32
            
            // Minimum a null terminator
            guard stringLength >= 1, pointer[numericCast(stringLength &- 1 &+ 4)] == 0x00 else {
                return false
            }
            
            // int32 contains the entire length, including null terminator
            advance(numericCast(4 &+ stringLength))
            
            return true
        }
        
        guard numericCast(pointer.int32) == count else {
            return false
        }
        
        advance(4)
        
        // Iterate over key-value pairs.
        // Key is null terminated
        nextPair: while offset < count {
            let typeId = pointer.pointee
            
            advance(1)
            
            if typeId == 0x00 {
                return offset == count
            }
            
            // Type
            guard let type = TypeIdentifier(rawValue: typeId) else {
                return false
            }
            
            // Key
            advance(storage.cString(at: offset))
            
            // Value
            switch type {
            case .double:
                advance(8)
            case .string:
                guard string() else {
                    return false
                }
            case .document, .array:
                guard document() else {
                    return false
                }
            case .binary:
                guard has(4) else {
                    return false
                }
                
                // int32 + subtype + bytes
                advance(numericCast(5 &+ pointer.int32))
            case .objectId:
                advance(12)
            case .boolean:
                guard pointer.pointee == 0x00 || pointer.pointee == 0x01 else {
                    return false
                }
                
                advance(1)
            case .datetime, .timestamp, .int64:
                advance(8)
            case .null, .minKey, .maxKey:
                // no data
                // Still need to check the key's size
                break
            case .regex:
                advance(storage.cString(at: offset))
                advance(storage.cString(at: offset))
            case .javascript:
                guard string() else {
                    return false
                }
            case .javascriptWithScope:
                guard string() else {
                    return false
                }
                guard document() else {
                    return false
                }
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
        
        return offset == count
    }
}
