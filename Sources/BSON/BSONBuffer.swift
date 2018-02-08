final class Storage {
    enum _Storage {
        case subStorage(Storage, range: Range<Int>)
        case readOnly(UnsafeBufferPointer<UInt8>)
        case readWrite(UnsafeMutableBufferPointer<UInt8>)
    }
    
    private let storage: _Storage
    
    init(storage: _Storage) {
        self.storage = storage
    }
    
    var count: Int {
        switch storage {
        case .subStorage(_, let range):
            return range.count
        case .readOnly(let buffer):
            return buffer.count
        case .readWrite(let buffer):
            return buffer.count
        }
    }
    
    var readBuffer: UnsafeBufferPointer<UInt8> {
        switch storage {
        case .subStorage(let storage, let range):
            let buffer = storage.readBuffer
            
            let pointer = buffer.baseAddress!.advanced(by: range.lowerBound)
            
            return UnsafeBufferPointer(start: pointer, count: range.count)
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
        
        if
            case .subStorage(let storage, let range) = storage,
            let buffer = storage.writeBuffer
        {
            let pointer = buffer.baseAddress!.advanced(by: range.lowerBound)
            
            return UnsafeMutableBufferPointer(start: pointer, count: range.count)
        }
        
        return nil
    }
    
    subscript(range: Range<Int>) -> Storage {
        return Storage(storage: .subStorage(self, range: range))
    }
}
