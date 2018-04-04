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
    var count: Int
    
    init(storage: _Storage) {
        self.storage = .init(storage: storage)
        self.count = storage.count
    }
    
    func expanding(minimum: Int) -> Storage {
        // Double size
        let storage = Storage(size: self.count &+ min(minimum, 4_096))
        storage.writeBuffer?.baseAddress?.assign(from: self.readBuffer.baseAddress!, count: self.count)
        
        return storage
    }
    
    func makeCopy() -> Storage {
        // Double size
        let storage = Storage(size: self.count)
        memcpy(storage.writeBuffer?.baseAddress!, self.readBuffer.baseAddress!, self.count)
        
        return storage
    }
    
    mutating func insert(at position: Int, from pointer: UnsafePointer<UInt8>, length: Int) {
        ensureExtraCapacityForMutation(length)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + position
        
        memmove(writePointer + (position + length), insertPointer, length)
        memcpy(insertPointer, pointer, length)
        self.count = self.count &+ length
    }
    
    mutating func replace(offset: Int, replacing: Int, with pointer: UnsafePointer<UInt8>, length: Int) {
        let diff = replacing &- length
        
        ensureExtraCapacityForMutation(length)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + offset
        
        if diff > 0 {
            memmove(writePointer + replacing + diff, writePointer + replacing, self.count &- offset &- diff)
        }
        
        memcpy(insertPointer, pointer, length)
        self.count = self.count &+ diff
    }
    
    private mutating func ensureExtraCapacityForMutation(_ n: Int) {
        if self.count &+ n < storage.storage.count {
            self.storage = self.expanding(minimum: n).storage
        } else if !isKnownUniquelyReferenced(&self.storage) {
            self.storage = makeCopy().storage
        }
    }
    
    mutating func append(from pointer: UnsafePointer<UInt8>, length: Int) {
        ensureExtraCapacityForMutation(length)
        
        memcpy(self.writeBuffer!.baseAddress! + self.count, pointer, length)
        self.count = self.count &+ length
    }
    
    mutating func append(_ byte: UInt8) {
        ensureExtraCapacityForMutation(1)
        
        (self.writeBuffer!.baseAddress! + self.count).pointee = byte
        self.count = self.count &+ 1
    }
    
    mutating func append(_ bytes: [UInt8]) {
        let size = bytes.count
        ensureExtraCapacityForMutation(size)
        
        (self.writeBuffer!.baseAddress! + self.count).assign(from: bytes, count: size)
        self.count = self.count &+ size
    }
    
    mutating func remove(from offset: Int, length: Int) {
        ensureExtraCapacityForMutation(-length)
        
        memmove(
            self.writeBuffer!.baseAddress! + (offset - length),
            self.writeBuffer!.baseAddress! + offset,
            self.count &- offset
        )
        
        self.count = self.count &- length
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
            self.writeBuffer!.baseAddress!.assign(from: pointer, count: size)
        }
    }
    
    init(bytes: [UInt8]) {
        let size = bytes.count
        self.init(size: size)
        
        self.writeBuffer!.baseAddress!.assign(from: bytes, count: size)
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
