import Foundation

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
    
    init(size: Int) {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: size)
        
        self.storage = .readWrite(buffer)
    }
    
    convenience init(data: Data) {
        let size = data.count
        self.init(size: size)
        
        data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            _ = memcpy(self.writeBuffer!.baseAddress!, pointer, size)
        }
    }
    
    convenience init(bytes: [UInt8]) {
        let size = bytes.count
        self.init(size: size)
        
        bytes.withUnsafeBytes { buffer in
            _ = memcpy(self.writeBuffer!.baseAddress!, buffer.baseAddress!, size)
        }
    }
    
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.storage = .readOnly(buffer)
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
