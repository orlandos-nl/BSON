import Foundation

struct Storage {
    enum _Storage {
        case subStorage(Storage, range: Range<Int>)
        case readOnly(UnsafeBufferPointer<UInt8>)
        case readWrite(UnsafeMutableBufferPointer<UInt8>)
        
        var count: Int {
            switch self {
            case .subStorage(_, let range):
                return range.count
            case .readOnly(let buffer):
                return buffer.count
            case .readWrite(let buffer):
                return buffer.count
            }
        }
    }
    
    final class AutoDeallocatingStorage {
        var storage: _Storage
        
        init(storage: _Storage) {
            self.storage = storage
        }
        
        deinit {
            if case .readWrite(let buffer) = self.storage {
                buffer.baseAddress?.deallocate()
            }
        }
    }
        
    private var storage: AutoDeallocatingStorage
    let count: Int
    
    init(storage: _Storage) {
        self.storage = .init(storage: storage)
        self.count = storage.count
    }
    
    func expand(minimum: Int) -> Storage {
        // Double size
        let storage = Storage(size: self.count &+ min(minimum, 4_096))
        memcpy(storage.writeBuffer?.baseAddress!, self.readBuffer.baseAddress!, self.count)
        
        return storage
    }
    
    mutating func insert(at position: Int, from pointer: UnsafePointer<UInt8>, length: Int) {
        if self.count &+ length < storage.storage.count {
            self.storage = expand(minimum: length).storage
        }
        
        let writePointer = self.writeBuffer!.baseAddress!
        
        memmove(writePointer + (position + length), writePointer + position, length)
    }
    
    init(size: Int) {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: size)
        
        self.storage = .init(storage: .readWrite(buffer))
        self.count = self.storage.storage.count
    }
    
    init(data: Data) {
        let size = data.count
        self.init(size: size)
        
        data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            _ = memcpy(self.writeBuffer!.baseAddress!, pointer, size)
        }
    }
    
    init(bytes: [UInt8]) {
        let size = bytes.count
        self.init(size: size)
        
        bytes.withUnsafeBytes { buffer in
            _ = memcpy(self.writeBuffer!.baseAddress!, buffer.baseAddress!, size)
        }
    }
    
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.storage = .init(storage: .readOnly(buffer))
        self.count = self.storage.storage.count
    }
    
    var readBuffer: UnsafeBufferPointer<UInt8> {
        switch storage.storage {
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
        if case .readWrite(let buffer) = storage.storage {
            return buffer
        }
        
        if
            case .subStorage(let storage, let range) = storage.storage,
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
