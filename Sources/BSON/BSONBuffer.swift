final class Storage {
    enum _Storage {
        case readOnly(UnsafeBufferPointer<UInt8>)
        case readWrite(UnsafeMutableBufferPointer<UInt8>)
    }
    
    private let storage: _Storage
    
    init(storage: _Storage) {
        self.storage = storage
    }
    
    var count: Int {
        switch storage {
        case .readOnly(let buffer):
            return buffer.count
        case .readWrite(let buffer):
            return buffer.count
        }
    }
    
    var readBuffer: UnsafeBufferPointer<UInt8> {
        switch storage {
        case .readOnly(let buffer):
            return buffer
        case .readWrite(let buffer):
            return UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count)
        }
    }
    
    var writeBuffer: UnsafeMutableBufferPointer<UInt8>? {
        if case .readWrite(let buffer) = storage {
            return buffer
        }
        
        return nil
    }
}
