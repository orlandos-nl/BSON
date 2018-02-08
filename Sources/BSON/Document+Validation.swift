extension Document {
    public var isValid: Bool {
        let count = self.storage.count
        var offset = 0
        
        guard count >= 4, var pointer = self.storage.readBuffer.baseAddress else {
            return false
        }
        
        guard numericCast(pointer.int32) == count else {
            return false
        }
        
        pointer += 4
        offset += 4
        
        while offset < count {
            switch pointer.pointee {
                case
            }
        }
        
        return true
    }
}
